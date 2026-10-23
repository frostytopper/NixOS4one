# Decision 04: tmux as a systemd Service

A system unit starts a detached `main` tmux session at boot, as the user.

- Survives desktop crashes and logout; attachable from any terminal or SSH.
- Beats shell-profile autostart: no dependency on a display manager.
- `Restart = "on-failure"` keeps it self-healing.
