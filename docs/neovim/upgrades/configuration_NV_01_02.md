# Neovim upgrade notes — `configuration_NV_01_02`

Companion to [the matching NixOS configuration snapshot](./configuration_NV_01_02.nix). Configuration details below describe that saved snapshot. Testing notes summarize user-reported development results; they are not a fresh build or execution of the snapshot during documentation review.

## Changes from `01_01`: finding and Nix formatting

This iteration wires up Telescope and adds explicit nixd/Alejandra formatting integration. It builds on the completion configuration in `01_01` without changing Blink or adding plugins or packages.

### Telescope finding and search

- Initializes the already-installed Telescope plugin.
- Adds four Normal-mode mappings under the existing Space leader:
  - `<leader>ff`: find files with `builtin.find_files`.
  - `<leader>fg`: search text with `builtin.live_grep`.
  - `<leader>fb`: find and switch buffers with `builtin.buffers`.
  - `<leader>fh`: search help tags with `builtin.help_tags`.
- Adds no explicit project-root detection or search-directory override to the Telescope setup or mappings.
- Reuses the existing Telescope, Plenary, ripgrep, and fd declarations; no additional dependencies are introduced.

### Explicit Nix formatting integration

- Sets nixd's executable to `${pkgs.nixd}/bin/nixd`.
- Configures nixd to invoke `${pkgs.alejandra}/bin/alejandra` for formatting.
- Adds the `NixOS4oneNixTools` FileType autocmd group for Nix buffers.
- Adds buffer-local `<leader>nf` to request formatting specifically from nixd, synchronously, with a five-second timeout.
- Formatting remains an explicit action; this iteration does not add format-on-save.

## Scope and sequence

During development, Nix tooling was prioritized: explicit nixd/Alejandra integration came before Telescope wiring. Both changes are captured in `01_02`, but they were implemented as separate bounded steps.

The existing Blink sources, documentation display, default completion keymap, Lua fuzzy matcher, and shared LSP capabilities remain unchanged. The enabled language servers are still `basedpyright`, `nixd`, `lua_ls`, and `ruff`.

`<leader>e` still opens netrw through `:Ex`. This iteration does not configure Oil or Lualine, add Gitsigns, or explicitly start Tree-sitter highlighting.

## Reported testing and checkpoint

During development, corrections to the new formatting autocmd's embedded Lua preceded a user-reported successful rebuild, switch, and Neovim startup.

During the October 23, 2026 Telescope follow-up, the user reported a fully passing Telescope health check and successful interaction tests for all four mapped pickers, without additional declarations. The user subsequently reported accurate completion suggestions and working Alejandra formatting.

These reports support the historical checkpoint for this iteration: the four mapped pickers worked interactively, completion suggestions worked, and Nix formatting worked through Alejandra. They do not establish exhaustive validation of every completion source or validation of the later Tree-sitter, Gitsigns, statusline, or Oil changes.
