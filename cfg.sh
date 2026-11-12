## Proposed script only, for review and implementation later.

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
