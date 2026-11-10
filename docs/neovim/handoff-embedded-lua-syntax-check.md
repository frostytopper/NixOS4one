## Handoff — embedded Lua syntax check in Neovim

Status: Proposed; not implemented. Resume after resolving the post-reboot access failure on `lati`.

### Goal

Check the Lua embedded in `configuration.nix` without opening `:terminal`, using line numbers, or saving edits first.

Keep this within the existing system-managed Neovim configuration: no new plugin, Home Manager, or system flake.

### Proposed behavior

Add one command:

```vim
:CheckConfigLua
```

When invoked from the configuration buffer, it will:

1. Read the current buffer, including unsaved edits.
2. Extract the text between two explicit Lua comments.
3. Open or refresh a dedicated scratch split with Lua highlighting.
4. Parse the extracted text using `loadstring()` without executing the returned function.
5. Display either `Lua syntax OK` or the parser’s error message.

### Source markers

Place these inside the existing heredoc:

```vim
          lua << EOF
          -- NIXOS4ONE_LUA_BEGIN

          -- Existing Lua configuration goes here.

          -- NIXOS4ONE_LUA_END
          EOF
```

Preserve consistent indentation throughout `customRC`; do not change the existing heredoc mode.

### Implementation outline

Define the command in the existing embedded Lua:

- Use `vim.api.nvim_buf_get_lines()` to read the source buffer.
- Match marker lines by trimmed, whole-line equality—not substring search, because the helper itself will contain the marker strings.
- Require exactly one opening marker and one closing marker, in the correct order.
- Extract only the lines between them.
- Use a reusable scratch buffer:
  - `buftype=nofile`
  - `bufhidden=hide`
  - `swapfile=false`
  - `filetype=lua`
- Compile the extracted string with `loadstring()`; never call the resulting function.
- Report errors with both the extracted Lua line number and corresponding source-buffer line number where practical.
- Reject invocation from the scratch buffer rather than checking its contents as though it were the configuration.

### Scope limits

- Syntax checking only—not plugin loading, LSP availability, or runtime behavior.
- Not Nix evaluation or validation of the surrounding Vimscript/heredoc.
- No automatic checks, mappings, external commands, or temporary files in the initial implementation.
- Keep the existing `sed`/`loadfile` workflow available as a manual fallback.

### Fail-fast verification

1. Run against the working configuration: expect `Lua syntax OK`.
2. Remove one Lua delimiter without saving: expect a useful syntax error.
3. Undo and rerun: expect success, reusing the scratch buffer.
4. Remove a marker temporarily: expect a clear boundary error, not a partial check.

No implementation or repository changes made.
