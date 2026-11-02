# configuration_v1.nix — Companion Notes

**Status:** Working system configuration (single-file, no flake, no Home Manager).

## What this file is

`configuration_v1.nix` is the current live reference for the full NixOS system:
desktop (KDE Plasma 6 + SDDM/Wayland), audio, services, user packages, and a
system-managed Neovim via `programs.neovim.configure`.

It is the successor to `neovim/upgrades/Phase1/configuration_NV_01_05.nix`, which was a
Phase 1 snapshot focused on getting the Neovim toolchain stood up. Do not treat
NV_01_05 as the current system config; it is kept for history.

## Differences from `configuration_NV_01_05.nix`

v1 is a near-superset of NV_01_05. The actual deltas:

1. **`nix.nixPath` pinning (new)**
   Adds `nix.nixPath = [ "nixpkgs=${pkgs.path}" ];` so `<nixpkgs>` / `nix search`
   resolve against the same nixpkgs the system was built from, not whatever
   channel happens to be registered.

2. **nvim-lint checker indirection (cosmetic)**
   Hoists the Python linter into `local py_checker = "mypy"` and uses
   `{ python = { py_checker } }` instead of a hardcoded `"mypy"` — one-line
   change to swap linters later.

3. **Security tooling added to user packages**
   Adds `age` and `sops`.

4. **`basedpyright` disabled**
   Commented out in the linter/LSP list (kept in place for easy re-enable).

5. **Secrets environment variables (machine-specific)**
   Adds `environment.sessionVariables` with `SOPS_CONFIG` and
   `CREDENTIALS_FILE` pointing at `/home/brian/secrets/`. These are personal
   paths; fork users should adjust or drop this block.

Everything else — the system-managed Neovim stack (telescope, oil, lualine,
blink.cmp, nixd + alejandra formatting, nvim-lint autocmds), plugin set,
services (tailscale, postgresql, openssh, tmux-main), fonts, and package
lists — is identical between the two files.
