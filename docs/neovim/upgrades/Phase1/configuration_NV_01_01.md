# Neovim upgrade notes — `configuration_NV_01_01`

Companion to [the matching NixOS configuration snapshot](./configuration_NV_01_01.nix). Configuration details below describe that saved snapshot. Testing notes summarize user-reported development results; they are not a fresh build or execution of the snapshot during documentation review.

## Completion integration

This snapshot configures Blink completion within the system-managed `programs.neovim.configure` setup. It enables `basedpyright`, `nixd`, `lua_ls`, and `ruff`, and supplies shared completion capabilities through Blink.

### Completion configuration

- Declares `blink-cmp` as the completion engine and `friendly-snippets` as the snippet collection.
- Configures Blink's completion sources: language servers, filesystem paths, snippets, and buffer text.
- Enables automatic display of completion documentation and selects Blink's default keymap preset.
- Explicitly selects the Lua fuzzy matcher to keep this configuration independent of native matcher binaries.
- Sets shared LSP capabilities with `blink.get_lsp_capabilities()` before enabling the four language servers.

### Scope boundaries

The completion work stays within the existing NixOS configuration structure. It introduces no Home Manager configuration, system flake, external plugin manager, or wholesale configuration rewrite.

Telescope, Oil, Lualine, and Tree-sitter grammars are declared in the startup plugin list, but this snapshot does not add their later explicit setup or activation. It defines no Telescope mappings, explicit nixd/Alejandra formatting integration, Tree-sitter highlighting callback, or Gitsigns setup. `<leader>e` still opens netrw through `:Ex`.

## Reported testing and checkpoint

During development, the user reported a successful NixOS rebuild and Neovim startup after corrections to the embedded Lua. This established a build-and-startup checkpoint, not confirmation that every completion source, snippet interaction, or acceptance/dismissal key behaved correctly.

During the subsequent Telescope follow-up on October 23, 2026, the user reported accurate completion suggestions and working Alejandra formatting. Those results belong to the later configuration checkpoint: Alejandra integration is not configured in this snapshot. The completion report provides subsequent evidence of working suggestions, not exhaustive validation of all Blink sources and key interactions.
