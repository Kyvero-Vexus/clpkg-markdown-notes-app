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

This document is sanitized for public tracking and omits internal tracker IDs.
