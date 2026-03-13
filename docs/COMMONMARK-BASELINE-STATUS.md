# CommonMark Baseline Test Status (kz9j)

Date: 2026-03-13

## Delivered in this pass

Added executable baseline suite and property checks:

- `test/core/commonmark-spec-baseline.lisp`
- `scripts/run-commonmark-baseline.lisp`

Checks included:
1. Baseline spec-case matrix (10 representative CommonMark examples)
2. Property: parser determinism (same input => same output)
3. Property: parser totality (random inputs do not signal errors)

## Command

```bash
sbcl --script scripts/run-commonmark-baseline.lisp
```

## Current scope note

This is a baseline harness aligned to the current parser contract (empty => error, non-empty => ok) and serves as the executable foundation for scaling up to full CommonMark corpus coverage.

## Next expansion

- import the official CommonMark example corpus
- map expected AST/shape assertions per example category
- enforce larger property corpus with seed reproducibility
