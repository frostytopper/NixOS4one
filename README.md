## From the human behind this: Most current config is located here: 
## https://github.com/frostytopper/NixOS4one/blob/main/docs/LocalGitHost/configuration_LGit_01_01.nix
## This config includes the fantastic addition of a local bare git repo! 
## This means you can keep track of every change OFFLINE and only push to your git holder of choice
## when you want too. This is new to me, so I'll be exploring some utilization options.

## TODO for 11/3/26 - 11/6/26
## 1 - Setup Headscale(it's a nixpkg!) and localize control of my Tailnet
## 2 - Setup a persistent TMUX instance that launches neovim on boot,
## AND loads neovim on boot for the whole system... so first load has happened
## before you ever touch the terminal and response is snappy
## 3 - Dedicated/declared container as a system service for hosting local LLMs (They stole our data,
## abliterated models give it back)
## 4 - Set PATHs for anything that gets referenced for configuration
## 5 - Unlock full hardware updates and utilize Facter hardware profile in 
## configuration.nix for more granular control (never done this, should be interesting)

##-## NixOS is a MONSTER of an OS. Turning your machine into YOUR machine is     ##-##
##-## a beautiful thing. Unfortunately the Reproducability and Portability of    ##-##
##-## Nixos took over the conversation, missing one of the most amazing uses     ##-##
##-## which is wiring your system so that it takes much less effort              ##-##
##-## to do MORE... The adventure continues!                                     ##-##

#### Important Note: You, yes you, are a beautiful human! :-D                    ####

# NixOS4One

One user. One machine. One `configuration.nix`.

This repo is a complete, working NixOS configuration for a solo developer's
daily-driver machine. No flakes for the system, no Home Manager, no layers
of abstraction to learn before you can change your wallpaper — just a single
readable file and `sudo nixos-rebuild switch`.

The audience is the solo dev: someone who wants a full workstation with real
services (database, VPN mesh, persistent terminal sessions, LSP-backed
editor) without maintaining a meta-framework on top of their OS.

See `docs/` for an annotated walkthrough of the config, the reasoning behind
each structural choice (`docs/decisions/`), and a staged upgrade path
(`docs/upgrades/`).

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
- **Hardware detection** — `hardware.facter` reads `facter.json`, plus the
  machine-generated `hardware-configuration.nix`, so hardware config is
  data, not hand-edited Nix. Both files are **gitignored by design**: a
  full hardware manifest (serials, MACs, partition UUIDs) is an
  attack-surface shopping list and never gets committed

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

1. Edit the `vars` attrset at the top of `configuration.nix` — `username`,
   `hostName`, and `timeZone` — and the user account, PostgreSQL access,
   and the persistent tmux session all follow automatically
2. Set the new user's password after install with `passwd` (the one thing
   `vars` can't — and shouldn't — capture)
3. Generate the hardware files locally and keep them out of version
   control: `nixos-facter` for `facter.json`, and the machine-generated
   `hardware-configuration.nix` — both are gitignored on purpose
4. Trim or extend the package lists — every section is commented by purpose

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
