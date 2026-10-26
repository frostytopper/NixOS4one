# Neovim: Consolidated customRC

> **Status: proposal — unvalidated.** Reference material only. The code
> below has NOT been applied to configuration.nix, NOT built with
> `nixos-rebuild`, and NOT exercised in a live Neovim session.
> `docs/neovim/00-current-state.md` remains the record of the system as it
> actually stands today.

Proposed drop-in replacement for the `customRC` string in
`programs.neovim.configure` (configuration.nix). Would merge the completion
pass (blink.cmp) with candidate wiring for already-declared plugins:
oil/lualine setup, treesitter on all filetypes, editor defaults, lua_ls
runtime config, ruff/basedpyright split, diagnostics.

## Proposed changes vs 00-current-state

Nothing below is applied or running. This is the delta this proposal WOULD
make if adopted and validated:

- oil.nvim takes over `<leader>e` and `-`; netrw disabled
- lualine initialized (today: declared, never set up)
- treesitter starts on every filetype (pcall-guarded); the Nix autocmd
  keeps only the alejandra format keymap
- editor options: clipboard=unnamedplus, scrolloff, splits, persistent
  undo, listchars, yank highlight
- lua_ls runtime/workspace settings (suppress "undefined global vim")
- ruff hoverProvider disabled (basedpyright owns hover)
- vim.diagnostic.config + `<leader>ld` float

## customRC

```vim
" ---- basics ----
set number
set relativenumber
set mouse=a
set termguicolors
set signcolumn=yes
set ignorecase
set smartcase

" interface
set scrolloff=8
set cursorline
set splitright
set splitbelow
set confirm
set undofile
set list
set listchars=tab:»\ ,trail:·

" clipboard (Wayland: wl-clipboard is in systemPackages)
set clipboard=unnamedplus

" indentation
set expandtab
set shiftwidth=2
set tabstop=2
filetype plugin indent on

" ---- keymaps ----
let mapleader = " "

" ---- colors ----
colorscheme habamax

" ---- plugins & LSP ----
lua << EOF
-- oil replaces netrw as the default explorer
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

require("oil").setup({
  default_file_explorer = true,
  view_options = { show_hidden = true },
})

vim.keymap.set("n", "-", "<cmd>Oil<CR>", { desc = "Oil: parent directory" })
vim.keymap.set("n", "<leader>e", "<cmd>Oil<CR>", { desc = "File explorer (Oil)" })

require("lualine").setup({
  options = { theme = "auto" },
})

-- telescope
require("telescope").setup({})

local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Search project text" })
vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Find buffers" })
vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Search help" })

-- completions
local blink = require("blink.cmp")

blink.setup({
  keymap = { preset = "default" },
  completion = { documentation = { auto_show = true } },
  sources = { default = { "lsp", "path", "snippets", "buffer" } },
  -- Keep independent of native matcher binaries.
  fuzzy = { implementation = "lua" },
})

-- completion capabilities for every server
vim.lsp.config("*", {
  capabilities = blink.get_lsp_capabilities(),
})

-- nixd: alejandra for formatting
vim.lsp.config("nixd", {
  cmd = { "${pkgs.nixd}/bin/nixd" },
  settings = {
    nixd = {
      formatting = {
        command = { "${pkgs.alejandra}/bin/alejandra" },
      },
    },
  },
})

-- lua_ls: teach it the Neovim runtime (kills "undefined global vim")
vim.lsp.config("lua_ls", {
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      workspace = {
        library = vim.api.nvim_get_runtime_file("", true),
        checkThirdParty = false,
      },
      telemetry = { enable = false },
    },
  },
})

-- ruff lints/organizes; basedpyright owns hover & type info
vim.lsp.config("ruff", {
  on_attach = function(client)
    client.server_capabilities.hoverProvider = false
  end,
})

vim.lsp.enable({
  "basedpyright", "nixd", "lua_ls", "ruff",
})

-- diagnostics
vim.diagnostic.config({
  virtual_text = { spacing = 2, source = "if_many" },
  severity_sort = true,
  float = { border = "rounded" },
})
vim.keymap.set("n", "<leader>ld", vim.diagnostic.open_float, { desc = "Line diagnostics" })

-- treesitter: start on any buffer that has a parser
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("TreesitterStart", { clear = true }),
  callback = function(event)
    pcall(vim.treesitter.start, event.buf)
  end,
})

-- nix buffers: alejandra format keymap
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("NixOS4oneNixTools", { clear = true }),
  pattern = "nix",
  callback = function(event)
    vim.keymap.set("n", "<leader>nf", function()
      vim.lsp.buf.format({
        bufnr = event.buf,
        name = "nixd",
        async = false,
        timeout_ms = 5000,
      })
    end, {
      buffer = event.buf,
      desc = "Nix: format with Alejandra",
    })
  end,
})

-- visual feedback on yank
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.hl.on_yank({ timeout = 150 })
  end,
})
EOF
```

## Validation checklist (required before adopting)

- [ ] `sudo nixos-rebuild build` succeeds (no activation)
- [ ] `sudo nixos-rebuild test`, then relaunch nvim
- [ ] `-` and `<leader>e` open oil; netrw never appears
- [ ] lualine renders in the statusline
- [ ] treesitter highlighting active on .py / .lua / .md buffers
- [ ] `:LspInfo` shows basedpyright, ruff, nixd, lua_ls attached where expected
- [ ] no "undefined global vim" diagnostics when editing Lua
- [ ] `<leader>nf` formats a .nix buffer via alejandra

## Notes

- `${pkgs.nixd}` / `${pkgs.alejandra}` are Nix interpolations; if adopted,
  this block must live inside the nix `''...''` string, not a standalone
  .vim file.
- `vim.hl.on_yank` requires Neovim 0.11+.
