# NixOS4One

One user. One machine. One `configuration.nix`.

This repo is a complete, working NixOS configuration for a solo developer's
daily-driver machine. No flakes for the system, no Home Manager, no layers
of abstraction to learn before you can change your wallpaper — just a single
readable file and `sudo nixos-rebuild switch`.

The audience is the solo dev: someone who wants a full workstation with real
services (database, VPN mesh, persistent terminal sessions, LSP-backed
editor) without maintaining a meta-framework on top of their OS.

## What's Inside

Everything below is live in the config right now:

- **Desktop** — KDE Plasma 6 on SDDM with Wayland, us keymap
- **Shell** — fish as the user shell, system-wide git configured for
  `pull.rebase`, `main` default branch, and nvim as editor
- **Editor** — Neovim managed by NixOS itself: treesitter with all grammars,
  LSP enabled against system-installed servers (basedpyright, ruff, nixd,
  lua_ls), telescope, oil.nvim, lualine, devicons — no plugin manager, unless
  absolutely unavoidable
- **Persistent tmux** — a `tmux-main` systemd service starts a detached
  `main` session at boot as your user, so there's always a session to attach
  to (Ghostty or SSH, doesn't matter which)
- **Services** — PostgreSQL with your user and a scratch database ready
  (`createdb` right granted), Tailscale, OpenSSH, CUPS printing, PipeWire
- **Dev tooling** — Python 3.14 with uv, Node, Lua, Rust toolchain pieces,
  nix-direnv for per-project environments, plus a lint/format bench:
  ruff, mypy, ty, sqlfluff, stylua, alejandra, nil + nixd
- **Quality of life** — eza, bat, fd, ripgrep, jq/yq/xq, miller, pandoc,
  pup, htop, rustscan, Ghostty terminal, Nerd Fonts (BlexMono, FiraMono,
  RobotoMono), Brave + LibreWolf
- **Hardware detection** — `hardware.facter` reads `facter.json`, so the
  hardware scan is data in the repo, not a generated Nix file

## Why a Single File

Because for one person on one machine, indirection is the enemy. Every
option is one file-grep away. Diffing a change is diffing one file. Rolling
back is pointing at the previous generation. When the config fits in your
head, you stop being afraid of your own system.

Flakes still exist in this world — just scoped to projects (dev shells,
devenv, packaging), not the system definition.

## Iterating With an LLM

This repo is deliberately hospitable to AI-assisted editing, because the
current generation of models is unusually good at Nix:

- Nix and the NixOS option surface are heavily represented in training data.
  Most frontier models can correctly name `programs.*` and `services.*`
  options, generate reasonable `environment.systemPackages` additions, and
  explain what an existing block does.
- A single-file config fits in context. You can paste the whole thing, or
  point the model at the repo, and get a full-file rewrite back instead of
  fragments you have to stitch.
- The feedback loop is cheap: ask for a change → `nixos-rebuild build` to
  verify it evaluates → `nixos-rebuild test` to activate it live without
  making it the boot default — if it breaks your desktop or network, a
  reboot puts you back on your last good config → `switch` only once it
  proves out. And even a bad `switch` is survivable, since the boot menu
  keeps your previous generations. Iterating on a prompt is faster than
  reading the manual end-to-end when you already know roughly what you
  want.

Two caveats that keep this honest: always sanity-check unfamiliar option
names against <https://search.nixos.org/options> (models do occasionally
hallucinate plausible-sounding options), and read diffs before switching —
the point is to *learn* Nix by iterating, not to rubber-stamp.

## Making It Yours

1. Rename `networking.hostName` and the `users.users."brian"` entry; set the
   new user's groups and shell as needed
2. Change the PostgreSQL `ensureUsers` / `ensureDatabases` entries to match
3. Set your own `time.timeZone` (currently `America/Los_Angeles`)
4. Run `nixos-facter` on your hardware and commit the resulting
   `facter.json`; delete the reference while testing on other machines
5. Trim or extend the package lists — every section is commented by purpose

Then:

```sh
sudo nixos-rebuild switch
```

## Non-Goals

- Multi-user or multi-host abstraction
- Home Manager
- Flake-based system configuration
- Being a distribution. Fork it, gut it, keep what earns its place.

## Philosophy

You should be able to read your own OS configuration top to bottom and
understand every line. NixOS makes that possible; this repo is the proof.
