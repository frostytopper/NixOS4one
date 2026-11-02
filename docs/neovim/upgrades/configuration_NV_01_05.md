# Neovim upgrade notes — `configuration_NV_01_05`

## Changes from `01_04`: Oil activation and Python tooling

This iteration replaces the netrw explorer mapping with Oil, adds automatic Python Tree-sitter highlighting, and wires Mypy into nvim-lint while removing Basedpyright from the enabled language servers.

### Oil activation

- Configures the already-installed Oil plugin as the default directory explorer.
- Replaces `<leader>e` → `:Ex` with Oil's parent-directory view and adds `<leader>E` to toggle a floating explorer.
- Enables the icon column and hidden-file visibility, restores window options when leaving Oil, and configures unlisted, hidden-on-close explorer buffers.
- Configures a rounded floating window with padding and no transparency.
- Adds `q` and Escape as close keys, disables Oil's `<C-h>` and `<C-l>` bindings, and explicitly assigns `<C-s>` to vertical selection and `<C-v>` to horizontal selection.
- Leaves `skip_confirm_for_simple_edits` commented out rather than enabling the confirmation bypass.
- Reuses Oil, web-devicons, and the Lualine Oil extension already declared in `01_04`; no new explorer plugin is added.

### Python highlighting

- Adds a separate `NixOS4onePythonHighlight` FileType autocmd for Python buffers, calling `vim.treesitter.start(event.buf)`.
- Keeps Python activation separate from the existing Nix highlighting and formatting callback.
- Adds the `tree-sitter` CLI to the user package list. The snapshot records the addition but does not establish that this CLI was required for highlighting; the Nix-provided grammars were already declared.

### Python diagnostics and type-checker wiring

- Removes `basedpyright` from `vim.lsp.enable(...)`; its package remains installed.
- Keeps `nixd`, `lua_ls`, and `ruff` enabled.
- Adds `nvim-lint` to the startup plugin list.
- Sets `require("lint").linters_by_ft = { python = { "mypy" } }`.
- Adds the `NixOS4oneLint` autocmd group to attempt linting after buffer reads and writes through `require("lint").try_lint()`.
- Reuses the already-installed Mypy package. This is editor integration, not a new Mypy installation or a Mypy language-server configuration.
- Adds no global Mypy strictness policy; the stated direction was to keep type-checker policy per project and defer ty.

## Implementation and testing

Oil setup required corrections to Lua table syntax and option spelling before reaching the working checkpoint. You subsequently marked the Oil foundation complete.

Python highlighting was tested manually, then made automatic. An extra comma in the callback declaration was corrected, and a fresh-session check confirmed Tree-sitter activation without manually starting it. Matching-parenthesis highlighting alone was explicitly distinguished from proof of Tree-sitter activation.

At the phase-five checkpoint, your normal-user health-check rerun left only the Blink sources notice and a newer-version notice.

The Mypy wiring was developed in a subsequent follow-up, including corrections to the lint configuration and method name. Diagnostic signs, underlining, and a Lualine error count were observed, but later you reported that the displayed diagnostic was still attributed to Ruff. That visual result should not be treated as conclusive Mypy-specific validation. The saved snapshot establishes Mypy wiring; a diagnostic explicitly attributed to Mypy remains a separate verification point.

## Scope boundaries

Blink, Telescope, Lualine, Gitsigns setup, and Nix highlighting/formatting remain unchanged from `01_04`.

This snapshot does not enable ty, introduce dmypy, or add an explicit Lua Tree-sitter activation callback. Removing Basedpyright and adding batch type-checker integration should not be described as replacing all of Basedpyright's language-server capabilities.

Gitsigns interaction testing in a local repository remained outstanding at the phase-five checkpoint.
