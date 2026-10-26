# SSH → Wayland clipboard (fish)

Notes from the first Termux → Tailscale → lati editing session
(2026-10-26). Reference for giving SSH sessions access to the graphical
clipboard. The manual fix below was validated live; the declarative
snippets are proposals — not yet applied or rebuilt.

## Problem

- PAM/systemd-logind creates `XDG_RUNTIME_DIR` (/run/user/1000) for every
  login, including SSH.
- `WAYLAND_DISPLAY` / `DISPLAY` are exported only by the graphical
  session startup, so SSH sessions never see them.
- Result: `wl-copy` / `wl-paste` fail with "Failed to connect to a
  Wayland server", and Neovim prints `clipboard: No provider` at startup
  when `clipboard=unnamedplus` is set unconditionally.

## Environment matrix

| Session type              | WAYLAND_DISPLAY | Clipboard result        |
|---------------------------|-----------------|-------------------------|
| local Plasma              | set             | works                   |
| SSH, GUI session running  | unset           | works after fix below   |
| SSH, machine at greeter   | unset           | impossible (no compositor) |

## Socket naming

The compositor socket lives at `$XDG_RUNTIME_DIR/wayland-N`. The number
varies: `wayland-0` on lati's current session, `wayland-1` is common
elsewhere. Never hardcode it. Companion `wayland-*.lock` files are
regular files, not sockets — filter them out with fish's `test -S`.

Checking the session situation:

```fish
ls $XDG_RUNTIME_DIR | grep wayland
loginctl list-sessions    # look for a seat0 session, class=user
```

## Manual fix (validated 2026-10-26)

```fish
set -x WAYLAND_DISPLAY wayland-0
echo hello | wl-copy
wl-paste        # prints: hello
```

## Proposed declarative fix (unvalidated)

In configuration.nix:

```nix
programs.fish.interactiveShellInit = ''
  # SSH sessions don't inherit the graphical session env
  if set -q SSH_CONNECTION; and not set -q WAYLAND_DISPLAY
    for sock in $XDG_RUNTIME_DIR/wayland-*
      if test -S $sock
        set -x WAYLAND_DISPLAY (basename $sock)
        break
      end
    end
  end
'';
```

Guards: `SSH_CONNECTION` keeps it from touching local logins; the
socket scan handles both socket numbering and greeter-only states
(no socket → nothing exported → graceful fallback).

## Neovim side (proposed, unvalidated)

Replace `set clipboard=unnamedplus` in the customRC with:

```vim
" clipboard only when a graphical session is reachable
if !empty($WAYLAND_DISPLAY) || !empty($DISPLAY)
  set clipboard=unnamedplus
endif
```

Falls back to internal registers silently in headless SSH sessions.

## Scope

This syncs yanks to lati's GUI clipboard, not the phone's. Getting text
into Termux is a separate problem (OSC52), out of scope for now.
