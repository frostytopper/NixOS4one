## One-time setup

```bash
mkdir -p ~/nix-config && cd ~/nix-config
git init
cp /etc/nixos/configuration.nix .
git add configuration.nix
git commit -m "initial copy of live config"
```

## One script, four commands

`cfg.sh` lives in the repository root. Install it as `~/nix-config/cfg.sh`, then `chmod +x cfg.sh`.

## Why `try` before `switch`

`nixos-rebuild test` is one of the least talked about rebuild options: it
makes your config *live* without making it a *generation*. You can test any
new config without polluting your generation history — and if it
misbehaves, a reboot puts you back on your last booted config.

It's like using "nix run ...", except on your home system lol

## The workflow

When an LLM proposes a config, paste it over `~/nix-config/configuration.nix` — no delete step, git is holding the old one:

```bash
cd ~/nix-config
git diff                      # review exactly what changed vs. last known-good
./cfg.sh try                  # build + activate as a test generation, reversible
./cfg.sh switch               # good: make it live, sync /etc/nixos, commit
git checkout -- configuration.nix   # bad: one command back to known-good
```

And after any rebuild you did the traditional way (`sudo nixos-rebuild switch` from `/etc/nixos`), run `./cfg.sh pull` to snapshot the live config into the repo's history.

## Quick live edits with `sudoedit`

For small edits directly against `/etc/nixos`, `env SUDO_EDITOR=nvim sudoedit /etc/nixos/configuration.nix` is a legitimate shortcut. Know its behavior:

- sudoedit copies the file to `/var/tmp/...` and opens the copy as *you*, with your environment. This is why your shell, aliases, and editor config all work.
- The `/var/tmp` path in nvim's save prompt is normal. Answering **Yes** and exiting is what triggers the write-back to `/etc/nixos` as root.
- Answering **No** discards silently — sudoedit sees an unchanged temp file and writes nothing back.
- You cannot `:w` to the real path from inside (E212: you'd need to be root).

After a `sudoedit`-based rebuild, run `./cfg.sh pull` so the repo snapshot doesn't drift from the live config.
