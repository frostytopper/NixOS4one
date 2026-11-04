# Neovim: Current State

Managed entirely by NixOS via `programs.neovim` (see
[docs/decisions/05-nixos-managed-neovim.md](../decisions/05-nixos-managed-neovim.md)).
Every declared plugin is wired — this pass has no "installed but inert"
entries.

## Wired today

- **LSP** — `vim.lsp.enable({ "nixd", "lua_ls", "ruff" })`, with completion
  capabilities injected from blink.cmp (`vim.lsp.config("*", ...)`)
- **nixd formatting** — Alejandra via `nixd`, on `<leader>nf` (nix buffers
  only)
- **Treesitter** — all grammars installed; python and nix buffers get an
  explicit `vim.treesitter.start` autocmd
- **Telescope** — `<leader>ff` files, `<leader>fg` live grep, `<leader>fb`
  buffers, `<leader>fh` help tags
- **oil.nvim** — default file explorer (takes over netrw); `<leader>e`
  parent directory, `<leader>E` floating explorer; `q`/`<Esc>` close,
  `<C-s>`/`<C-v>` split
- **lualine** — global statusline with branch/diff/diagnostics and LSP
  status; oil extension enabled
- **blink.cmp** — completion from lsp/path/snippets/buffer, default keymap
  preset, Lua fuzzy matcher (no native binary)
- **gitsigns** — setup with defaults
- **nvim-lint** — python checker held in `local py_checker` (currently
  `mypy`); runs on `BufReadPost`/`BufWritePost`
- **Basics** — number + relativenumber, mouse, termguicolors, scrolloff 8,
  cursorline, ignorecase/smartcase, confirm dialogs, undofile,
  clipboard=unnamedplus, 2-space indent, leader = space, habamax

## Plugin set (all nixpkgs vimPlugins)

nvim-treesitter.withAllGrammars, nvim-lspconfig, plenary-nvim,
telescope-nvim, oil-nvim, lualine-nvim, nvim-web-devicons, blink-cmp,
friendly-snippets, gitsigns-nvim, nvim-lint.

## Not yet declared

- basedpyright — present but commented out in user packages; re-enable if
  ruff alone proves insufficient
- treesitter textobjects and other candidates in `upgrades/`
