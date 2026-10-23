# Neovim: Current State

Managed entirely by NixOS via `programs.neovim` (see
docs/decisions/05-nixos-managed-neovim.md). Plugins and LSP servers are
declared, but most plugins are not wired with keymaps or config yet.

Wired today:
- LSP: `vim.lsp.enable` for basedpyright, ruff, nixd, lua_ls
- Treesitter: all grammars installed
- Basics: relative numbers, leader = space, `<leader>e` :Ex, habamax

Declared but unwired:
- Telescope (no keymaps)
- oil.nvim (no bindings/config)
- lualine, nvim-web-devicons (defaults only)

Not yet declared (candidates live in `upgrades/`):
- Completion engine, git integration, treesitter textobjects
