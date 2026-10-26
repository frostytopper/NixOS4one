## One-time setup

```bash
mkdir -p ~/nix-config && cd ~/nix-config
git init
cp /etc/nixos/configuration.nix .
git add configuration.nix
git commit -m "initial copy of live config"
```

## One script, four commands

```bash
#!/usr/bin/env bash
# ~/nix-config/cfg.sh
set -euo pipefail
REPO="$HOME/nix-config"
CFG="$REPO/configuration.nix"

case "${1:-}" in
  pull)
    # /etc/nixos -> repo: snapshot the live config into history
    cp /etc/nixos/configuration.nix "$REPO"
    if git -C "$REPO" diff --quiet -- configuration.nix; then
      echo "no changes"
    else
      git -C "$REPO" add configuration.nix
      git -C "$REPO" commit -m "sync from /etc/nixos $(date -Is)"
    fi
    ;;
  try)
    # test-rebuild against the repo copy; /etc/nixos untouched
    sudo nixos-rebuild test -I nixos-config="$CFG"
    ;;
  switch)
    # make it live, sync fallback copy, commit the known-good version
    sudo nixos-rebuild switch -I nixos-config="$CFG"
    sudo cp "$CFG" /etc/nixos/configuration.nix
    git -C "$REPO" add configuration.nix
    git -C "$REPO" commit -m "switch: $(date -Is)"
    ;;
  *)
    echo "usage: cfg.sh {pull|try|switch}"; exit 1 ;;
esac
```

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
