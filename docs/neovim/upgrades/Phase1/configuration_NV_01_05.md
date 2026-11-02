# Neovim upgrade notes — `configuration_NV_01_05`

Companion to [the matching NixOS configuration snapshot](./configuration_NV_01_05.nix). Configuration details below describe that saved snapshot. Testing notes summarize user-reported development results; they are not a fresh build or execution of the snapshot during documentation review.

## Changes from `01_04`: Oil activation and Python tooling

This snapshot replaces the netrw explorer mapping with Oil, adds explicit automatic Python Tree-sitter highlighting, and wires Mypy into nvim-lint while removing Basedpyright from the enabled language servers. It includes Mypy integration work performed after the initial phase-five checkpoint.

### Oil activation

- Configures the already-installed Oil plugin as the default directory explorer.
- Replaces `<leader>e` → `:Ex` with `require("oil").open()` and adds `<leader>E` to call `require("oil").toggle_float()`.
- Enables the icon column and hidden-file visibility, and sets `restore_win_options = true`.
- Sets Oil buffer options to `buflisted = false` and `bufhidden = "hide"`.
- Configures a rounded floating window with padding of 2 and `winblend = 0`.
- Adds `q` and Escape as close keys, disables Oil's `<C-h>` and `<C-l>` bindings, and explicitly assigns `<C-s>` to vertical selection and `<C-v>` to horizontal selection.
- Leaves `skip_confirm_for_simple_edits` commented out rather than enabling the confirmation bypass.
- Reuses Oil, web-devicons, and the Lualine Oil extension already declared in `01_04`; no new explorer plugin is added.

### Python highlighting

- Adds a separate `NixOS4onePythonHighlight` FileType autocmd for Python buffers, calling `vim.treesitter.start(event.buf)`.
- Keeps Python activation separate from the existing Nix highlighting and formatting callback.
- Adds the `tree-sitter` CLI to the user package list. This addition does not establish that the CLI was required for highlighting; the Nix-provided grammars were already declared.

### Python diagnostics and type-checker wiring

- Removes `basedpyright` from `vim.lsp.enable(...)`; its package remains installed.
- Keeps `nixd`, `lua_ls`, and `ruff` enabled.
- Adds `nvim-lint` to the startup plugin list.
- Sets `require("lint").linters_by_ft = { python = { "mypy" } }`.
- Adds the `NixOS4oneLint` autocmd group to call `require("lint").try_lint()` on `BufReadPost` and `BufWritePost`. The autocmd itself has no filetype pattern; the linter assignment is Python-specific.
- Reuses the already-installed Mypy package. This is editor integration, not a new Mypy installation or a Mypy language-server configuration.
- Adds no explicit Mypy strictness options in this Neovim configuration. During development, the intended direction was to keep type-checker policy per project and defer ty.

## Reported implementation and testing

### Initial phase-five checkpoint

Oil setup required corrections to Lua table syntax and option spelling during development. The user subsequently marked the Oil foundation complete.

Python highlighting was tested manually, then made automatic. After an extra comma in the callback declaration was corrected, the user reported that a fresh-session check confirmed Tree-sitter activation without manually starting it. Matching-parenthesis highlighting alone was distinguished from proof of Tree-sitter activation.

At the initial phase-five checkpoint, the user reported that a normal-user health-check rerun left only the Blink sources notice and a newer-version notice. This earlier result should not be treated as validation of the subsequent Mypy integration.

### Mypy follow-up and Ruff decision

The Mypy wiring was developed in a subsequent follow-up, including corrections to the lint configuration and method name. Diagnostic signs, underlining, and a Lualine error count were observed, but the user reported that the displayed diagnostic was still attributed to Ruff. Those observations do not establish Mypy-specific validation.

In the subsequent development discussion, the user chose to continue with Ruff for the current Python linting setup. The saved snapshot nevertheless retains the Mypy assignment in nvim-lint and the enabled Ruff language server. The later workflow decision and the saved configuration are distinct checkpoints; the decision does not demonstrate that Mypy wiring was removed from this file.

These are historical development results, not an independent rerun of the saved configuration.

## Scope boundaries

Blink, Telescope, Lualine, Gitsigns setup, and Nix highlighting/formatting remain unchanged from `01_04`.

This snapshot does not enable ty, introduce dmypy, or add an explicit Lua Tree-sitter activation callback. The absence of a Lua callback does not establish that Lua highlighting was inactive at runtime. Removing Basedpyright and adding batch type-checker integration should not be described as replacing all of Basedpyright's language-server capabilities.

Gitsigns interaction testing in a local repository remained outstanding at the initial phase-five checkpoint.
