# Note CRUD Status (l7nq.2)

Date: 2026-03-13

## Delivered

Implemented typed note CRUD boundary in `src/vault/note.lisp`:

- `create-note`
- `read-note`
- `update-note` (temp file + rename atomic replace)
- `delete-note` (default trash semantics)
- `rename-note`
- `move-note`

Typed contracts:
- strict `declaim/ftype` on exported APIs
- explicit error conditions: `note-invalid-name`, `note-not-found`

Sandbox integration:
- all paths are resolved through vault root normalization + relative path guards from `src/vault/vault.lisp`

## Verification

Executed:

```bash
sbcl --script scripts/verify-note-crud.lisp
```

Result: CRUD + guard behavior checks passed.

## Follow-up

Next bead `l7nq.3` can build attachment storage on top of this CRUD boundary.
