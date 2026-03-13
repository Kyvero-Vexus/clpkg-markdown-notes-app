# Vault CRUD + Security E2E Status (l7nq.4)

Date: 2026-03-13

## Delivered

Added end-to-end matrix runner:

- `tests/vault/vault-crud-security-e2e.lisp`
- `scripts/run-vault-crud-security-e2e.lisp`

Scenarios covered:
- CRUD happy path (create/read/update/delete-to-trash)
- traversal denial on note API
- attachment happy path
- blocked MIME rejection
- vault lexical traversal guard check

Performance check included:
- CRUD batch budget assertion under 500ms (baseline local gate)

## Run

```bash
sbcl --script scripts/run-vault-crud-security-e2e.lisp
```
