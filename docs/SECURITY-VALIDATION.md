# Security Validation Summary

Recent validated security behavior for vault guards:

- absolute-path input is rejected deterministically
- lexical traversal (`..`) is rejected before filesystem effects
- out-of-root canonical paths are rejected with typed condition
- broken symlink canonicalization now deterministically signals
  `vault-canonicalization-failed`
- escaped symlink targets are rejected as `vault-out-of-root`

Typed boundary requirements retained:

- explicit condition hierarchy for vault path errors
- strict SBCL `declaim`/`ftype` contracts on exported guard functions

## Threat Matrix (public)

- absolute path injection -> `vault-absolute-path-rejected`
- lexical traversal (`../`, `..\\`) -> `vault-traversal-rejected`
- canonical target outside root -> `vault-out-of-root`
- broken/unresolvable canonical target -> `vault-canonicalization-failed`
- invalid/non-directory root -> `vault-invalid-root`

Guard order contract: lexical rejection occurs before any filesystem side effects.

Additional IO verification evidence (temp perms + atomic rename):
- `docs/IO-VERIFICATION.md`
- `scripts/verify-vault-io.lisp`

This document is sanitized for public tracking and omits internal tracker IDs.
