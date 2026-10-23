# Decision 02: The `vars` Attrset

A `let` block at the top holds `userName`, `fullName`, `hostName`.

- Interpolation points: user account, PostgreSQL user, tmux-main service.
- One edit personalizes a fresh install; nothing else needs finding.
- Password is deliberately NOT in vars — secrets do not belong in the file.
