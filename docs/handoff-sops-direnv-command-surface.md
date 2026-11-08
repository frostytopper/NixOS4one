# Handoff — sops shell layer, direnv template, command surface

Analysis session output, 2026-11-08. No code was written; this doc is the
agreed design for the next implementation session. Scope: NixOS4one only.

## Current state (verified against repo + session history)

- `paths.secrets = "${user.home}/secrets"` in the configuration.nix let block
- `SOPS_CONFIG` and `CREDENTIALS_FILE` exported via `environment.sessionVariables`
- `programs.direnv` + `nix-direnv` enabled
- Local git host live: per-project `origin = git@localhost:/srv/git/<Project>.git`,
  `github` remote separate and explicit; the local host never forwards
- `programs.fish` already carries `interactiveShellInit` (zoxide) — the
  extension point for the shell function layer

## 1. sops shell layer

Three real verbs from usage history: edit, extract, encrypt-in-place fallback.

- Declarations go in `programs.fish` in configuration.nix — no Home-Manager.
- Expanding fish abbreviations for the single-shot verbs (edit, encrypt -i):
  keeps the full sops syntax visible on every use, matching the
  learn-by-seeing preference.
- One function for two-arg extraction, e.g. `cred <service> <field>`,
  designed for fish command substitution: `(cred ncbi api_key)` — the exact
  shape project .envrc files will consume.
- Decrypted values travel via substitution/pipes into env vars, never as
  visible command arguments (arguments leak into the process table briefly).
- Add a config comment: the global `SOPS_CONFIG` shadows per-project
  `.sops.yaml` discovery; unset/override it in a project .envrc if a project
  ever needs its own recipient set.

## 2. direnv template + push semantics

direnv has NO exit hook. Do not chase push-on-exit through cd overrides,
fish EXIT events, or tmux pane hooks — all fragile under the persistent
tmux workflow (panes outlive directory visits).

Split the job by what each tool is good at:

- `.envrc` establishes the connection: idempotently ensure `origin` points
  at `git@localhost:/srv/git/<Project>.git` (add if missing, per playbook
  step 2.4). This also closes the open loop — the Pipeline direnv directory
  is not yet connected to a local bare repo.
- A `post-commit` hook owns the push, targeting `origin` only: every
  committed state lands on the bare repo automatically, uncommitted work
  never does, and GitHub is unreachable from this path because origin IS
  the local host.
- Template mechanism: shared functions live in `~/.config/direnv/direnvrc`;
  each project's `.envrc` reduces to a one-liner, e.g.
  `use local_git_host Pipeline`. Plain bash, no templating language.

## 3. Command surface grouping (mined from session history)

Promote to shell surface (fish abbrs/functions in configuration.nix):

- Group A — config lifecycle: `nixos-rebuild test/switch`,
  `-I nixos-config=...`, the cfg.sh pull/try/switch pattern (docs/workflow.md),
  `git diff` review before rebuild.
- Group B — secrets: sops edit / `--extract` / `encrypt -i`.
- Group D — dev bursts: uv direnv entry, failed→retry list swap + rerun,
  tmux attach to the persistent `editor` session.

Keep doc-first, script-second (do NOT promote to casual shell surface):

- Group C — githost per-project setup: `sudo -u git git init --bare`,
  remote rename/add, the `ssh git@localhost` boundary test (must FAIL),
  `git ls-remote` verification. Wrap as one documented `githost-init`
  procedure so the boundary test is never silently skipped.

## Loose ends

1. nvim swap/backup cleanup from the plaintext-credentials debugging
   session (2026-10-30): check ~/secrets for `.credentials.yaml.swp` or `~`
   backups and remove. One-time task.
2. sops → Pipeline .envrc wiring: NCBI key extraction into the uv dev
   shell. Paused when the download session started; resume after the
   downloader finishes.

## Live operational state (as of 2026-11-08)

- The PMC downloader is RUNNING on lati with the IncompleteRead fix
  applied — but in a plain terminal window, NOT inside tmux. It dies if
  that window closes. Next session: leave the window untouched until the
  run completes, and wrap future long jobs in tmux from the start
  (persistent `editor` session exists via the tmux-main service; a
  dedicated session is fine too).
