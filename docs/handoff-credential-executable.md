# Handoff — credential executable

Status: **Approved design; skeleton ready to install.** Resolves §2.4 of the
approved implementation order.

Scope: a system-managed `credentials` executable that decrypts sops/age
profiles into process memory only. Projects stay fully committable — no
plaintext secrets in `.envrc`, `shell.nix`, or scripts. All sensitive material
lives in `~/secrets` (root-protected via `systemd.tmpfiles`).

Per the approved order: activate the py-uv-shell environment (§2.5) next, then
`dev-doctor` diagnostics (§2.6), then managed jobs (§2.7).

## References

- [Approved implementation order](handoff-approved-implementation-order.md) — this document resolves §2.4
- [SOPS/direnv command surface](handoff-sops-direnv-command-surface.md)
- [Python development workbench](handoff-python-development-workbench.md)

## Decisions

1. **Interface is print-exports.** `credentials env <profile>` emits
   `export KEY='value'` lines that a project `.envrc` feeds to `eval`.
   Reason: `.envrc` is evaluated by Bash; direnv applies the exported diff to
   the outer shell (fish included) and unloads it on directory exit — lifecycle
   hygiene for free, and it composes with the nix-direnv `use nix` cache.
2. **Same binary also provides `exec`** for the managed-jobs step: the parent
   environment never receives secrets; the child sees only that profile's keys.
3. **Plaintext never touches disk.** One `sops decrypt` streams into an
   unexported shell variable; `yq` extracts the profile from memory.
4. **`credentials.yaml` is keyed by profile**; profiles are flat scalar maps.
   The project→profile mapping is the one explicit argument in the `.envrc` —
   inspectable, committable, fails closed on machines without `~/secrets`.
5. **Fail closed, loudly.** Distinct stderr messages for: missing secrets
   directory, unreadable credentials file, decryption failure, missing
   profile, unsafe key names. Exit 1 on any precondition/validation failure;
   exit 64 on usage error.
6. **Encoding safety.** Key names must match `[A-Za-z_][A-Za-z0-9_]*`;
   values are shell-quoted via yq's `@sh` encoder (correctly escapes embedded
   quotes). Empty values export as `''`. Non-scalar values are rejected.
7. **Availability check.** `credentials list <profile>` prints key names
   only — usable for diagnostics without exposing values.
8. **Per-host keys (future).** When a second machine appears, add its age
   recipient to `creation_rules` in `~/secrets/.sops.yaml` and re-encrypt.
   The executable and every `.envrc` stay byte-identical.

## configuration.nix patch

Add to the `let` block, next to `paths`:

```nix
  # Credential broker: decrypts sops/age profiles into process memory.
  # Activation, diagnostics, and managed jobs build on this executable.
  credentialBroker = pkgs.writeShellApplication {
    name = "credentials";
    runtimeInputs = [
      pkgs.sops
      pkgs.yq-go
    ];
    text = ''
      # script below, verbatim — with one escape:
      #   ${CREDENTIALS_FILE:-}  →  ''${CREDENTIALS_FILE:-}
      # (Nix indented-string interpolation must be escaped)
    '';
  };
```

Add to `environment.systemPackages`:

```nix
    credentialBroker
```

Consequences:

- Lands in `/run/current-system/sw/bin` — already the last element of
  `tmux-main`'s forced `PATH`, so future services call it with no PATH work.
- `writeShellApplication` runs shellcheck at build time — malformed edits
  fail `nixos-rebuild`, not shell entry.
- No new session variables; reuses the global `CREDENTIALS_FILE` and
  `SOPS_CONFIG` exports already set via `environment.sessionVariables`.

## The script

```bash
# NixOS4one credential broker.
# Decrypts a profile from the sops/age credentials file into process
# memory only. Plaintext never touches disk, and `decrypted` is never
# exported, so exec'd children see only the profile's own keys.
set -euo pipefail

die() { printf 'credentials: %s\n' "$*" >&2; exit 1; }

usage() {
  cat >&2 <<'EOF'
NixOS4one credential broker

usage:
  credentials env  <profile>           print `export KEY='…'` lines for eval
  credentials exec <profile> -- cmd …  exec cmd with the profile injected
  credentials list <profile>           print key names only (no values)
EOF
  exit 64
}

[ $# -ge 2 ] || usage
action="$1"
profile="$2"
shift 2

# ---- fail-closed preflights ------------------------------------------------
[ -n "${CREDENTIALS_FILE:-}" ] || die 'CREDENTIALS_FILE is not set'
secrets_dir="$(dirname -- "$CREDENTIALS_FILE")"
[ -d "$secrets_dir" ] || die "secrets directory missing: $secrets_dir"
[ -r "$CREDENTIALS_FILE" ] || die "credentials file unreadable: $CREDENTIALS_FILE"

decrypted="$(sops decrypt "$CREDENTIALS_FILE")" \
  || die 'decryption failed (no usable age key on this host?)'

yq -e --arg p "$profile" \
  'has($p) and (.[$p] | tag == "!!map")' <<<"$decrypted" >/dev/null \
  || die "no credential profile '$profile' in $CREDENTIALS_FILE"

# Profiles are flat KEY: value maps. Reject anything a shell cannot export
# safely; fail closed, loudly.
unsafe="$(yq --arg p "$profile" \
  '.[$p] | keys | map(select(test("^[A-Za-z_][A-Za-z0-9_]*$") | not)) | .[]' \
  <<<"$decrypted")"
[ -z "$unsafe" ] || die "unsafe key names in profile '$profile': $unsafe"

# Shell-safe export lines via yq's @sh encoder (correctly escapes embedded
# quotes; deliberately avoids `-o=shell -r`, which skips quoting).
emit_exports() {
  yq --arg p "$profile" '
    .[$p] | to_entries | .[] |
    "export \(.key)=\(
      if (.value | tag) == "!!str" then .value
      elif (.value | tag | test("^!!(int|float|bool)$")) then (.value | tostring)
      else error("profile \($p): key \(.key) must be a scalar")
      end | @sh)"' <<<"$decrypted"
}

# ---- actions ---------------------------------------------------------------
case "$action" in
  env)
    emit_exports
    ;;

  exec)
    [ $# -ge 1 ] || die 'exec: missing -- separator or command'
    [ "$1" = "--" ] && shift
    [ $# -ge 1 ] || die 'exec: no command given'
    # Eval only output this script itself generated and validated.
    eval "$(emit_exports)"
    unset decrypted
    exec "$@"
    ;;

  list)
    yq --arg p "$profile" '.[$p] | keys | .[]' <<<"$decrypted"
    ;;

  *)
    usage
    ;;
esac
```

## Data contract

`~/secrets/credentials.yaml` (edited with `sops edit`, which respects the
`.sops.yaml` in the same directory):

```yaml
py-uv-shell:
  GITHUB_TOKEN: ENC[AES256_GCM,data:…]
  SOME_API_KEY: ENC[AES256_GCM,data:…]
```

Project `.envrc` (committable; fails closed on machines without `~/secrets`):

```bash
use nix ~/.local/lib/nix/shells/py-uv-shell.nix
eval "$(credentials env py-uv-shell)"
```

The `eval` line runs on every directory entry (age decryption is sub-10 ms);
nix-direnv caching applies only to the `use nix` derivation environment.

## Failure matrix

| Condition                     | stderr message                                        | Exit |
|-------------------------------|--------------------------------------------------------|------|
| Bad invocation                | usage banner                                           | 64   |
| `CREDENTIALS_FILE` unset      | `CREDENTIALS_FILE is not set`                          | 1    |
| `~/secrets` missing           | `secrets directory missing: …`                         | 1    |
| File unreadable               | `credentials file unreadable: …`                       | 1    |
| No usable age key             | `decryption failed (no usable age key on this host?)`  | 1    |
| Profile absent / not a map    | `no credential profile '…' in …`                       | 1    |
| Invalid key names             | `unsafe key names in profile '…': …`                   | 1    |
| Non-scalar value              | yq `error(` trap: `profile … key … must be a scalar`   | 1    |

At shell entry, each failure surfaces through direnv's `.envrc` error path.

## Next session

Activate the py-uv-shell environment (§2.5): add its profile entry to
`credentials.yaml`, create the two-line `.envrc`, `direnv allow`, and verify
the failure matrix. `dev-doctor` (§2.6) can then branch on the exit codes
above; managed jobs (§2.7) will use `credentials exec`.
