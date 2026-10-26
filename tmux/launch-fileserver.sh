#!/usr/bin/env bash
# launch-fileserver.sh — start a temp HTTP fileserver in a tmux session window.
# Use case: remote machine running tmux + tailscale; grab files over the tailnet.
#
#   ./launch-fileserver.sh [SESSION] [PORT] [DIRECTORY]
#   defaults: SESSION=main PORT=8000 DIRECTORY=$PWD

set -euo pipefail

SESSION="${1:-main}"
PORT="${2:-8000}"
DIR="${3:-$PWD}"

find_socket() {
    # Prefer known socket paths over inherited TMUX_TMPDIR, which can point at a
    # runtime dir where the server socket does not exist (causes:
    # "error connecting to /run/user/N/tmux-N/default (No such file or directory)").
    local uid_sock="/tmp/tmux-$(id -u)"
    local runtime_sock="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/tmux-$(id -u)"
    for d in "$uid_sock" "$runtime_sock" "${TMUX_TMPDIR:-}"; do
        [ -d "$d" ] || continue
        find "$d" -maxdepth 1 -type s 2>/dev/null
    done | head -n 1
}

SOCKET="$(find_socket)"

if [ -z "$SOCKET" ]; then
    echo "No tmux server socket found. Is tmux running? Check: pgrep -a tmux" >&2
    exit 1
fi

tmux -S "$SOCKET" new-window -t "$SESSION" -n fileserver \
    "cd '$DIR' && python3 -m http.server $PORT --bind 0.0.0.0"

echo "Serving $DIR on http://0.0.0.0:$PORT in tmux window '$SESSION:fileserver'"
echo "Socket: $SOCKET"
