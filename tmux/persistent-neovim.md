## Persistent Neovim session

NixOS starts a dedicated tmux session named `editor` on `lati` at boot. Neovim stays running when you detach or disconnect, allowing local and Pixel/Termux connections to return to the same editor.

**Persistence** has two layers: tmux keeps the live editor running across disconnections; Resurrect and Continuum restore saved workspace state after reboot. [file:179]

### How it works

- `tmux-main.service` runs as `brian`, starting Neovim in `/home/brian`.
- The shared tmux socket is `/run/user/1000/tmux-1000/default`.
- Resurrect saves tmux sessions, windows, panes, and supported programs.
- Continuum is configured for five-minute snapshots and automatic restoration when the tmux server starts.
- NixOS handles boot startup; Continuum’s own boot integration is disabled. [file:179]

The startup script leaves an existing `editor` session alone. If session creation fails, it checks again for `editor`, accommodating a session created concurrently by restoration. The process mapping below normalizes Nix-store Neovim commands so the `nvim` session strategy can apply: [file:179][file:142]

```tmux
set -g @resurrect-strategy-nvim 'session'
set -g @resurrect-processes '"~nvim->nvim"'
```

### Connect

From the Pixel’s Termux terminal:

```sh
ssh -t brian@lati 'tmux -S /run/user/1000/tmux-1000/default attach-session -t editor'
```

From a normal terminal on `lati`:

```sh
tmux -S /run/user/1000/tmux-1000/default attach-session -t editor
```

These attach to the existing session rather than launching another editor. Pixel attachment and post-reboot workspace restoration have both been tested successfully.

### Detach and save

For tmux shortcuts, press `Ctrl-b`, release both keys, then press the next key:

| Action | Shortcut |
|---|---|
| Detach, leaving Neovim running | `Ctrl-b`, then `d` |
| Save a tmux snapshot manually | `Ctrl-b`, then `Ctrl-s` |
| Restore a tmux snapshot manually | `Ctrl-b`, then `Ctrl-r` |

Neovim workspace restoration also requires a separate `Session.vim` file in the saved pane’s working directory. For this setup, save it from Neovim with:

```vim
:mksession! /home/brian/Session.vim
```

Check which editor session is loaded with:

```vim
:echo v:this_session
```

The installed restoration strategy launches `nvim -S` when that working directory contains `Session.vim`.

### Important behaviors

- Detaching preserves the live editor. Quitting Neovim or running `tmux kill-session` does not.
- Reboot restoration recreates saved state; it does not preserve the original running process or guarantee recovery of unsaved edits. Save files before rebooting.
- Automatic restoration runs at tmux server startup, not every time you attach. [file:72][file:73]
- The service uses `Type=oneshot` and `RemainAfterExit=true`. An `active (exited)` status alone does not prove Neovim is still running. Restarting the service kills the existing `editor` session before recreating it. [file:179]

### Useful checks

Inspect the actual running panes:

```sh
tmux -S /run/user/1000/tmux-1000/default list-panes -a -F 'session=#{session_name} command=#{pane_current_command} cwd=#{pane_current_path}'
```

Read service messages from the current boot:

```sh
sudo journalctl -b -u tmux-main.service --no-pager -o cat -n 30
```