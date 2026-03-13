# clpkg-markdown-notes-app

Typed Common Lisp markdown notes/vault library with secure path-sandboxing, reusable APIs, and export/search primitives.

## Status

- Public sanitized planning/specification repository
- Product + architecture spec in `docs/SPEC.md`
- Security/verification summary in `docs/SECURITY-VALIDATION.md`
- Current vault guard implementation in `src/vault/vault.lisp`

## Design goals

- Package-first reusable API (not GUI-coupled)
- Strict typed Common Lisp boundaries (`declaim` / `ftype` / typed conditions)
- Deterministic security behavior for path traversal and symlink handling
- End-to-end usage-based verification matrix

## License

AGPL-3.0-or-later
