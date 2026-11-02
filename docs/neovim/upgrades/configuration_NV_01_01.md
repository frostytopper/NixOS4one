# Neovim upgrade notes — `configuration_NV_01_01`

## Change from the original: completion integration

This iteration adds **completion** to the existing system-managed Neovim configuration. The original already enabled the language servers but did not declare a completion engine. The change connects those existing servers to Blink rather than replacing the LSP setup or restructuring the NixOS configuration. [memory:1]

### What changed

- Added `blink-cmp` as the completion engine and `friendly-snippets` as the snippet collection.
- Configured Blink’s completion sources: language servers, filesystem paths, snippets, and buffer text.
- Enabled automatic display of completion documentation and selected Blink’s default keymap preset.
- Explicitly selected the Lua fuzzy matcher to keep this first pass independent of native matcher binaries.
- Added `blink.get_lsp_capabilities()` to the shared LSP configuration before enabling the existing servers: `basedpyright`, `nixd`, `lua_ls`, and `ruff`.

### Why this step came first

The initial completion work was deliberately bounded: use the existing `programs.neovim.configure` setup, add the missing completion layer, and leave the other upgrade tracks alone. No Home Manager, system-flake conversion, external plugin manager, or wholesale configuration rewrite was introduced. [memory:1]

Telescope mappings, explicit nixd/Alejandra formatting integration, Tree-sitter activation, and the later Oil, Lualine, and Git setup are not changes introduced by this snapshot.

## Testing and checkpoint

The first implementation required corrections to the embedded Lua. After those corrections, you reported a successful NixOS rebuild and Neovim launch while opening `configuration.nix` through `sudo`. That established a build-and-startup checkpoint—not yet confirmation that every completion source, snippet interaction, or acceptance/dismissal key behaved correctly. [memory:1]

Later, during the Telescope follow-up, you reported accurate suggestions and working Alejandra formatting. That provides subsequent confirmation of completion behavior, but belongs later in the testing chronology rather than being presented as validation already completed at the `01_01` checkpoint. [memory:3]