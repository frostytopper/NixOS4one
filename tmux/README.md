# tmux remote helpers

Scripts for driving a tmux session on a remote machine (e.g. a laptop with
tmux + tailscale, accessed from Termux on a phone) when you just need to
grab a file.

## The problem these solve

`tmux ls` / `tmux new-window` fail with:

```
error connecting to /run/user/1000/tmux-1000/default (No such file or directory)
```

even though a session is running. Cause: `TMUX_TMPDIR` (or the tmux default
`/tmp`) points somewhere other than where the server actually created its
socket. The scripts below find the real socket instead of trusting the env.

## Scripts

### find-tmux-server.sh
Lists tmux server processes, locates sockets in the usual places, and lists
sessions on each socket.

```bash
./tmux/find-tmux-server.sh
```

### launch-fileserver.sh
Starts `python3 -m http.server` in a new window (named `fileserver`) of an
existing tmux session, auto-locating the socket.

```bash
# session name, port, directory — all optional, defaults: main 8000 $PWD
./tmux/launch-fileserver.sh main 8000 ~/Downloads
```

On NixOS the scripts are plain POSIX-ish bash; python3 must be in PATH in
the window's shell.
