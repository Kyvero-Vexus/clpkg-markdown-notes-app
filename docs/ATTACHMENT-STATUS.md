# Attachment Storage Status (l7nq.3)

Date: 2026-03-13

## Delivered

Implemented typed attachment storage in `src/vault/attachment.lisp`:

- hash-keyed dedupe pathing (`attachments/<hash>-<name>`)
- size policy enforcement (`attachment-too-large`)
- MIME allowlist enforcement (`attachment-blocked-mime`)
- typed return struct `attachment-record`

## Verification

```bash
sbcl --script scripts/verify-attachment-storage.lisp
```

Checks:
- write + readback record type
- dedupe key reuse
- oversize rejection
- blocked MIME rejection

## Follow-up

Use these attachment boundaries in l7nq.4 E2E security matrix with CRUD + traversal scenarios.
