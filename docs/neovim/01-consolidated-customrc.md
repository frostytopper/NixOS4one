# Neovim: Consolidated customRC

Drop-in replacement for the `customRC` string in `programs.neovim.configure`
(configuration.nix). Merges the completion pass (blink.cmp) with the wiring
fixes from the plugin audit: oil/lualine setup, treesitter on all filetypes,
editor defaults, lua_ls runtime config, ruff/basedpyright split, diagnostics.

## Changes vs 00-current-state

- Fixed: oil.nvim owns `<leader>e` and `-`; netrw disabled
- Fixed: lualine initialized (was declared, never set up)
- Fixed: treesitter starts on every filetype (pcall-guarded); the Nix
  autocmd now keeps only the alejandra format keymap
- Added: clipboard=unnamedplus, scrolloff, splits, persistent undo,
  listchars, yank highlight
- Added: lua_ls runtime/workspace settings (kills "undefined global vim")
- Changed: ruff hoverProvider disabled (basedpyright owns hover)
- Added: vim.diagnostic.config + `<leader>ld` float

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

## Notes

- `${pkgs.nixd}` / `${pkgs.alejandra}` are Nix interpolations; keep this
  block inside the nix `''...''` string, not a standalone .vim file.
- `vim.hl.on_yank` requires Neovim 0.11+ (satisfied on 26.05 channels).
