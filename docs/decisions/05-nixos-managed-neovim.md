# Decision 05: Nix-Managed Neovim

Neovim is configured by NixOS itself via `programs.neovim`.

- Plugins come from nixpkgs `vimPlugins` — versions pinned to the channel,
  no plugin manager, no lockfile.
- LSP servers are system packages (nixd, basedpyright, ruff, lua_ls);
  `vim.lsp.enable` wires them in the init.
- Treesitter with all grammars: zero parsers compiled at runtime.
