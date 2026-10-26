#!/usr/bin/env bash
# find-tmux-server.sh — locate running tmux server(s), their socket(s), and sessions.
# Prints the exact -S SOCKET value to pass to tmux commands.

set -euo pipefail

echo "== tmux server processes =="
pgrep -a tmux || echo "(none found)"
echo

echo "== sockets =="
found=0
for d in "/tmp/tmux-$(id -u)" "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/tmux-$(id -u)" "${TMUX_TMPDIR:-}"; do
    [ -d "$d" ] || continue
    while IFS= read -r sock; do
        found=1
        echo "socket: $sock"
        echo "sessions:"
        tmux -S "$sock" ls 2>/dev/null || echo "  (could not list)"
        echo
    done < <(find "$d" -maxdepth 1 -type s 2>/dev/null)
done
[ "$found" -eq 0 ] && echo "(no sockets found in default locations)"
