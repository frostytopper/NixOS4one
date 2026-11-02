# Neovim upgrade notes — `configuration_NV_01_02`

## Changes from `01_01`: finding and Nix formatting

This iteration wires up Telescope and adds explicit nixd/Alejandra formatting integration. It builds on the completion configuration in `01_01` without changing Blink or adding plugins or packages.

### Telescope finding and search

- Initializes the already-installed Telescope plugin.
- Adds four Normal-mode mappings under the existing Space leader:
  - `<leader>ff`: find files.
  - `<leader>fg`: search project text with live grep.
  - `<leader>fb`: find and switch buffers.
  - `<leader>fh`: search help tags.
- Uses the existing Telescope, Plenary, ripgrep, and fd declarations; no additional dependencies are introduced.

### Explicit Nix formatting integration

- Sets nixd's executable to `${pkgs.nixd}/bin/nixd`.
- Configures nixd to invoke `${pkgs.alejandra}/bin/alejandra` for formatting.
- Adds the `NixOS4oneNixTools` FileType autocmd group for Nix buffers.
- Adds buffer-local `<leader>nf` to request formatting specifically from nixd, synchronously, with a five-second timeout.
- Formatting remains an explicit action; this iteration does not add format-on-save.

## Scope and sequence

Nix tooling was prioritized during the work: explicit nixd/Alejandra integration came before Telescope wiring. Although both changes are captured in `01_02`, they were implemented as separate bounded steps.

The existing Blink sources, documentation display, default completion keymap, Lua fuzzy matcher, and shared LSP capabilities remain unchanged. The enabled language servers are still `basedpyright`, `nixd`, `lua_ls`, and `ruff`.

`<leader>e` still opens netrw through `:Ex`. This iteration does not configure Oil or Lualine, add Git integration, or explicitly start Tree-sitter highlighting.

## Testing and checkpoint

The Nix formatting step required corrections to the newly added autocmd's Lua syntax before reaching a successful rebuild, switch, and startup checkpoint.

After the Telescope wiring, you reported a fully passing Telescope health check and successful interaction tests for all four pickers, without additional declarations. You subsequently reported accurate completion suggestions and working Alejandra formatting.

Those reports establish the tested checkpoint for this iteration: Telescope's four mapped pickers worked interactively, completion remained functional, and Nix formatting worked through Alejandra. They do not establish validation of later Tree-sitter, Git, statusline, or Oil changes.
