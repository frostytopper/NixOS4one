# Verified workstation and Neovim baseline — 2026-11-06

The maintainer rebuilt the system successfully, launched a fresh Neovim
instance without startup errors, and reported successful completion,
formatting, and cursor diagnostic popup tests. Tokyo Night Night is active.
The maintainer also confirmed that the persistent tmux session works
properly as configured. This update promotes the supplied working
configuration to the repository root without refactoring or expanding it.

## Editor wiring

- Nix: nixd with Alejandra formatting; `Space nf` formats Nix buffers.
- Python: ty supplies language intelligence and type checking; Ruff supplies
  linting, formatting, and code actions. Ruff hover is disabled in favor of ty.
- `Space f` selects nixd for Nix and Ruff for Python formatting.
- `Space d` opens diagnostics under the cursor.
- Blink supplies completion capabilities to the language servers and uses
  its Lua fuzzy matcher.
- Lua language-server settings recognize Neovim's `vim` global and runtime.
- Tokyo Night is installed through the Nix plugin package list and selected
  with `colorscheme tokyonight-night`.
- Telescope: `Space ff` finds files, `Space fg` opens live grep, `Space fb`
  lists buffers, and `Space fh` searches help.
- mypy remains installed for explicit project use; the previous automatic
  nvim-lint invocation is removed. nvim-lint itself remains installed.

## Verification record

Reported by the maintainer, not independently executed by the assistant:

- System rebuild succeeded.
- Fresh Neovim startup succeeded without errors.
- nixd appeared for a Nix buffer; ty and Ruff appeared for a Python buffer.
- File finding and opening through Telescope succeeded.
- Telescope live grep opened; an actual matching search result was not
  separately reported in this checkpoint.
- Completion and formatting tests passed.
- Cursor diagnostic popup test passed.
- Tokyo Night Night became active after rebuilding.
- The persistent tmux session works properly as configured.

## Other changes promoted with the supplied configuration

- Hostname and timezone use `vars`; home and secret paths derive from the
  configured user's home.
- NIX_PATH uses `builtins.storePath pkgs.path` for the nixpkgs entry.
- Fish initializes the already-installed Zoxide package.
- Scheduled Nix store optimisation and nix-ld are enabled.
- tmux loads resurrect and continuum; Neovim session restoration is configured
  to use a saved `Session.vim`, with vim-obsession installed.
- The tmux-main system service starts an `editor` session containing Neovim,
  uses the user's runtime directory, and declares HOME and PATH explicitly.
- The configured user has lingering enabled.

These declarations are included in the successfully rebuilt configuration.
Persistent tmux operation is verified by the maintainer; a separate
reboot-restoration test is not inferred from that confirmation. This
checkpoint does not claim separate functional tests of Zoxide, nix-ld, or
the optimisation timer. The tmux runtime path and service dependency still
explicitly assume UID 1000.

## Scope

The root configuration is the new working baseline. No Home Manager, system
flake, extra plugin manager, or speculative configuration changes were added
while preparing this promotion. Earlier archived configurations remain
unchanged. Git history retains the preceding root configuration.
