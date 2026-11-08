# Handoff — module extraction candidates

Analysis session output, 2026-11-08 (PM follow-up to
handoff-sops-direnv-command-surface.md). Design only; no code written.

Question answered: which pieces of this system earn a real NixOS module
(options + mkIf boundary), versus what stays in the monolithic
configuration.nix. Splitting the config into files was considered and
rejected as premature. Modules wrap existing options only where there is
a genuine unit of composition — the module boundary must respect the
declarative-vs-imperative split, not erase it.

## Strong candidates

### 1. Local git host (build FIRST)

Owns: the `git` system user, `git-shell`, `/srv/git`, the authorizedKeys
list. Options sketch: `enable`, `user`, `repoRoot = "/srv/git"`,
`authorizedKeys`.

Smallest, crispest boundary on the system. The data plane (bare repos)
stays imperative by design — the LocalGitHost playbook already documents
exactly that boundary. Pairs with wrapping the remaining playbook steps
(2.2 onward) into the module's documentation.

### 2. Persistent tmux session (tmux-main, build SECOND)

Owns: the systemd oneshot service, the resurrect/continuum plugin wiring.
Options sketch: `enable`, `user`, `sessionName = "editor"`, `command`.

Extraction forces two coupling fixes — exactly the kind of thing module
boundaries expose:

- Hardcoded `user-runtime-dir@1000` — UID must derive from the user
  option, not a literal.
- `paths.userProfileBin` reaching into `/etc/profiles/per-user/...` by
  string concatenation.

This is the showpiece of the Pixel → tmux → neovim workflow; it deserves
the module treatment.

### 3. Git project template with auto-push hook (build THIRD)

Operationalizes the push semantics from handoff-sops-direnv-command-surface.md
§2 machine-wide:

- Set `init.templateDir` (merges into the existing `programs.git.config`)
  pointing at a store path containing a `post-commit` hook.
- The hook pushes to origin ONLY if an origin remote exists; silently
  exits otherwise. That guard makes global installation safe: repos
  without a local host are untouched, repos with one get
  commit-equals-local-push for free.
- Converts a per-project imperative step into a system property.

Depends on the direnv template work in the earlier handoff, hence third.

## Moderate candidates

### 4. Secrets layout

Too thin alone (two session variables), real as a bundle behind one
`enable`: `SOPS_CONFIG` / `CREDENTIALS_FILE`, the ~/secrets 0700 tmpfiles
rule (Tier 2 of the earlier handoff), and the `age` + `sops` packages.
The value is making the "declarative where, imperative what" contract one
importable statement instead of three scattered stanzas.

### 5. Nix maintenance defaults

Tier 0 from the earlier handoff as a curated bundle: nix.gc, optimise,
systemd-boot configurationLimit, journald cap, zramSwap. Low intellectual
content, high audience value — a forker gets a non-rotting system from
one line.

## Enabler, not a module

The shared direnv library (handoff §2) can be declarative WITHOUT Home
Manager: the direnv stdlib reads `direnv_config_dir` from the
`DIRENV_CONFIG` environment variable. So:

- `environment.sessionVariables.DIRENV_CONFIG = "/etc/direnv"`
- `environment.etc."direnv/direnvrc"` holds the `use local_git_host`
  function

This closes the last dotfile-shaped hole in the design.

## Anti-candidates (stay in the monolith)

- Neovim — `programs.neovim` already IS the module; wrapping it adds an
  option around an option. Also the most personal, most volatile part of
  the config: every edit would churn module internals.
- Fish layer — no module needed. Native system-wide surface confirmed:
  `programs.fish.shellAbbrs` (real abbreviations, not aliases) and
  `programs.fish.plugins` are NixOS options, not Home-Manager-only.
  Handoff §1 is pure option-setting.
- SSH/mosh/Tailscale bundle — three unrelated native toggles; a
  "remote access profile" module would be a renaming exercise.

## Build order

1. Git host (smallest, crispest boundary)
2. Persistent tmux (forces the UID/PATH coupling fixes; showpiece)
3. Git project template hook (depends on the earlier handoff's §2)
4. Secrets layout and 5. nix-maintenance fold in whenever convenient —
   half an hour each.

Fish, neovim, and the network layer stay in the monolith.
