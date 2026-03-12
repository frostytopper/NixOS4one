## The below was written with AI. This is me, FrostyTopper, typing to you directly. This is a side/passion project for me. Since so much of this ecosystem is always full of dialogue about how to build things that you can take anywhere, pull from everywhere, it gets pretty tedious finding clear examples that approach it soley from a personal user on a single machine perspective.
## Currently (3/12/26) I am going to organize the configuration.nix a little more. Then do a little documentation and modularization to make navigating the configuration a less clunky. After that, Devenv/TMUX/nix-serve is going to be hit because that's what my projects need :)

# NixOS4one

**Focused on single user, single device experience.**  
Keeping the communication in that context, keeping it clear and complete for those new to NixOS.  

Flakes for projects, **not** for total system configuration.  
**No** Home Manager.  

This is for those who want to work on mastering the fundamentals with minimal abstraction.

---

## Purpose

This repo is your complete, single-file `configuration.nix` for a **personal NixOS 25.11 stable** system.  
One user. One device. Full ownership. Maximum NixOS power with zero extra layers.

Everything you need to own your machine is right here — desktop, shell, dev tools, databases, web server, local cache, tmux, and more — all in plain, readable Nix.

## What’s Inside (ready to use)

- XFCE + LightDM (auto-login for the single user)
- Bash + Starship + Zoxide + blesh (modern, fast, beautiful shell)
- Tmux with sensible plugins (resurrect, continuum, yank, etc.)
- Ghostty terminal with smart tmux auto-attach
- Angie (nginx fork) + local `nixos.local` site
- PostgreSQL 17 with your user already set up
- Local Nix binary cache (`nix-serve`)
- Full dev stack: `nixd`, `alejandra`, `devenv`, `direnv`, Python 3.13, Node 20, Jupyter, etc.
- Nerd fonts, eza, fzf, yazi, bat, zoxide, aria2, xh… everything a power user wants

How to Keep It Yours

Change networking.hostName
Rename the user frosty to your username
Set your own time.timeZone if you’re not in Pacific Time
Add any SSH keys or extra packages you want

Never commit hardware-configuration.nix (it’s machine-specific).
Edit configuration.nix directly — that’s the point of this repo.
Use flakes only inside projects (nix develop, devenv, packaging, etc.).


Run sudo nixos-rebuild switch whenever you change something.

Philosophy (why this repo exists)
Own your system.
Learn Nix the real way.
No layers. No bloat. Just pure NixOS joy on one machine.
This repo is public so others can fork it and do the same.
