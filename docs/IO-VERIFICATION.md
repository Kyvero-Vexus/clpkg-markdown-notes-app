# Vault Canonical IO Verification

This verification note documents filesystem assumptions and checks for vault-safe IO primitives.

## Matrix scope

- traversal rejection before side effects (`../` and equivalent lexical escapes)
- canonical path containment checks under normalized root
- temporary write permissions for atomic replace flow
- atomic replace via temp-write + rename

## Verification script

- script: `scripts/verify-vault-io.lisp`
- runtime: SBCL

Checks performed:

1. resolve in-root relative path (`docs/SPEC.md`) successfully
2. reject traversal path (`../escape`) with typed `vault-traversal-rejected`
3. write temp file with restrictive `0600` permissions
4. atomically replace target file via `rename-file`

## Platform assumptions

- Linux rename semantics used for atomic replacement within same filesystem.
- Permission assertion uses `sb-posix:stat` mode bits on SBCL.
- Script is designed for repository-local validation and deterministic guard behavior.

This document is sanitized for public publication and omits internal tracker identifiers.
