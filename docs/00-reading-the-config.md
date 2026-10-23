# Reading the Config, Top to Bottom

`configuration.nix` is organized into labeled sections. Grep for these
headers and read them in this order your first time through:

| Section | Grep | What It Does |
|---|---|---|
| Personalization | `vars = {` | Three values (user, display name, hostname) customize the whole system. |
| Hardware | `imports = [` / `hardware.facter` | Machine-generated files supply hardware config — never hand-edited, never committed. |
| Boot | `--  Boot --` | systemd-boot on EFI. |
| Locale & Time | `-- Locale / Time --` | Timezone and full en_US.UTF-8 locale set. |
| Desktop | `-- Desktop` | SDDM on Wayland, KDE Plasma 6, us keymap. |
| Printing & Audio | `-- Printing --` / `-- Audio --` | CUPS; PipeWire with ALSA+Pulse shims, rtkit. |
| Nix Settings | `-- Nix --` | Flakes/nix-command allowed (for projects), unfree allowed. |
| Programs | `-- Programs (system-managed) --` | Neovim (plugins + LSP via Nix), git, fish, tmux, direnv. |
| Services | `-- Services --` | Tailscale, PostgreSQL (+scratch db, user with CREATEDB), OpenSSH. |
| Persistent tmux | `-- Persistent TMUX Session --` | systemd unit keeps a `main` tmux session alive from boot. |
| Fonts | `-- Fonts --` | Three Nerd Fonts for terminal + editor use. |
| User Account | `-- User --` | The single user: groups, shell, per-user dev packages. |
| System Packages | `environment.systemPackages` | CLI bench: search, data, archives, network tools. |
| Safety Nets | `system.copySystemConfiguration` / `stateVersion` | Config snapshot in each generation; pinning note you must read. |
