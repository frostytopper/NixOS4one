# Neovim upgrade notes — `configuration_NV_01_03`

Companion to [the matching NixOS configuration snapshot](./configuration_NV_01_03.nix). Configuration details below describe that saved snapshot. Testing notes summarize user-reported development results; they are not a fresh build or execution of the snapshot during documentation review.

## Change from `01_02`: automatic Nix Tree-sitter highlighting

This iteration adds an explicit Tree-sitter highlighting startup call for Nix buffers. It reuses the parser declaration already present in `01_02` rather than adding another parser installation mechanism.

### What changed

- Adds `vim.treesitter.start(event.buf)` to the existing Nix `FileType` callback in the `NixOS4oneNixTools` autocmd group.
- Requests Tree-sitter highlighting when that callback runs for a Nix buffer.
- Reuses the existing `nvim-treesitter.withAllGrammars` declaration. This change adds no plugins, packages, runtime parser downloads, or additional configuration framework.
- Leaves the buffer-local `<leader>nf` formatting mapping in the same callback, unchanged.

## Reported inspection and testing

During development, inspection of a Nix editing buffer distinguished parser and highlighting-query availability from an active Tree-sitter highlighter. The reported inspection identified activation, rather than installation, as the missing step for that buffer.

Manual activation reportedly succeeded, with the highlighter check returning `true`. The startup call was then made persistent in the Nix FileType callback. The user subsequently reported that the same check returned `true` in a fresh session without manual activation, supporting the automatic-highlighting checkpoint.

The development testing also reported working completion and diagnostics. An apparent formatting failure was attributed to entering the Space n f mapping sequence too slowly; formatting then worked after correcting the input timing, without another configuration change.

A warning on the module's `config` argument was inspected separately during development and identified as nixd's unused-argument diagnostic, not a Tree-sitter failure. The argument remains unchanged in this snapshot.

These are historical results from the development environment, not an independent rerun of the saved configuration.

## Scope boundaries

This is highlighting activation only, not a Tree-sitter navigation upgrade. It adds no folding, indentation configuration, text objects, structural movement, theme changes, or explicit activation for additional languages.

Blink, Telescope, the enabled language servers, and nixd/Alejandra formatting remain unchanged from `01_02`.

The snapshot also contains an unrelated `##edit` comment near the desktop configuration. It is not part of the Neovim upgrade.
