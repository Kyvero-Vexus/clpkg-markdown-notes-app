# Architecture Review: clpkg-markdown-notes-app

**Reviewer:** Gensym (General Manager)
**Date:** 2026-03-14
**Bead:** workspace-ceo_chryso-2mdp
**Scope:** API stability, type coverage, security audit

---

## 1. API Stability & Consistency

### 1.1 Package Naming — ✅ PASS

All packages follow `clpkg-markdown-notes/<subsystem>` convention:
- `clpkg-markdown-notes/vault`
- `clpkg-markdown-notes/note`
- `clpkg-markdown-notes/attachment`
- `clpkg-markdown-notes/search`
- `clpkg-markdown-notes/backlinks`
- `clpkg-markdown-notes/tags`

Consistent, predictable, no collisions.

### 1.2 Struct Naming & `:conc-name` — ✅ PASS

| Struct | `:conc-name` | Prefix consistent? |
|--------|-------------|-------------------|
| `note-record` | `note-` | ✅ |
| `attachment-record` | `attachment-` | ✅ |
| `search-index` | `si-` | ✅ |
| `index-entry` | `ie-` | ✅ |
| `backlink-index` | `bi-` | ✅ |
| `tag-index` | `ti-` | ✅ |

All exported accessor names match their `:conc-name` prefix. Clean.

### 1.3 Condition Hierarchy — ✅ PASS (with note)

- Vault layer: `vault-path-condition` → 5 subtypes, well-structured
- Note layer: `note-invalid-name`, `note-not-found` — correct but not subtyped under a common base
- Attachment: `attachment-too-large`, `attachment-blocked-mime` — same observation
- Search: `search-no-results` — condition, not error (correct!)

**Suggestion (non-blocking):** Consider a top-level `markdown-notes-condition` base type for handler-case grouping in downstream consumers.

### 1.4 API Surface vs. Spec — ⚠️ GAP

The spec (Section 2.5) defines a `defgeneric`-based API surface with methods like `open-vault`, `find-note`, `search`, etc. The implementation uses plain `defun` functions instead.

**Assessment:** This is acceptable for the current typed-struct approach (no CLOS inheritance needed yet), but the spec/implementation mismatch should be documented. The current API is functionally complete for the vault/note/attachment/index layers.

**Missing from spec surface:**
- `open-vault` / `close-vault` — not implemented (callers use `normalize-vault-root` directly)
- `rebuild-index` — not implemented
- `export-html` / `export-org` — Coalton stubs only
- `note-history` / `note-at-version` — not implemented (P2, expected)

These are expected gaps given the implementation phase.

### 1.5 Export Completeness — ✅ PASS

All exported symbols have corresponding implementations. No dangling exports.

---

## 2. Type Coverage (ftype Declarations)

### 2.1 vault.lisp — ✅ FULL COVERAGE

All 5 exported functions have `ftype` declarations:
- `normalize-vault-root`
- `resolve-vault-relative-path`
- `reject-escape-path`
- `validate-symlink-target-under-root`
- `%canonicalize-existing-target` (internal, also typed)

### 2.2 note.lisp — ✅ FULL COVERAGE

All 6 CRUD functions + 2 internal helpers have `ftype` declarations:
- `create-note`, `read-note`, `update-note`, `delete-note`, `rename-note`, `move-note`
- `%validate-note-name`, `%note-path`

### 2.3 attachment.lisp — ✅ FULL COVERAGE

- `allowed-mime-p`, `store-attachment` — both declared

### 2.4 search.lisp — ✅ FULL COVERAGE

- `extract-trigrams`, `index-note!`, `search-notes` — all declared

### 2.5 backlinks.lisp — ✅ FULL COVERAGE

- `register-links!`, `get-backlinks`, `get-forward-links`, `find-orphans` — all declared

### 2.6 tag-index.lisp — ✅ FULL COVERAGE

- `register-tags!`, `get-notes-by-tag`, `all-tags` — all declared

### 2.7 Coalton modules — ✅ TYPED BY DESIGN

All `.coal` files use explicit type signatures on every exported function.

**Summary:** 100% ftype coverage on all CL exports. Exemplary.

---

## 3. Security Audit

### 3.1 Path Traversal — ✅ PASS

- `resolve-vault-relative-path` rejects `../`, `..\`, and absolute paths **before** any filesystem operation
- `reject-escape-path` performs canonical prefix check after resolution
- `validate-symlink-target-under-root` resolves symlinks and re-checks containment
- Guard order is correct: lexical checks before filesystem effects

**Pen test results (from E2E):**
- `../escape` note name → `note-invalid-name` ✅
- `../bad` relative path → `vault-traversal-rejected` ✅
- Absolute path → `vault-absolute-path-rejected` ✅

### 3.2 Note Name Validation — ✅ PASS

`%validate-note-name` rejects: empty strings, `../`, `..\`, `/`, `\`. This prevents both path traversal and directory escape via note names.

### 3.3 Attachment Security — ✅ PASS

- MIME allowlist enforced (default: png/jpeg/webp/pdf/text)
- Size limit enforced (default 10MB)
- Content-addressed storage (MD5 key) prevents name-based overwrites
- Blocked MIME → `attachment-blocked-mime` condition

### 3.4 HTML Export — ⚠️ STUB ONLY

The Coalton `sanitize-html` function is a pass-through stub (`sanitize-html _ raw = raw`). This is a **known gap** — the HTML export layer is not yet production-ready.

**Risk:** Low (current), since no consumer uses it yet. Must be implemented before any HTML output is served.

### 3.5 No eval/read-from-string — ✅ PASS

Grep confirms zero uses of `eval`, `read-from-string`, or `compile` on user data across all source files.

### 3.6 Atomic Writes — ✅ PASS

`update-note` uses write-to-temp + `rename-file` pattern, preventing partial writes on crash.

### 3.7 Threat Model Coverage

| Threat | Mitigation Status |
|--------|------------------|
| Path traversal | ✅ Implemented + tested |
| Markdown/XSS injection | ⚠️ Stub sanitizer |
| Symlink escape | ✅ Implemented + tested |
| Front-matter injection | ⚠️ Stub parser (safe — returns empty) |
| Encryption weakness | ❌ Not yet implemented (P2) |
| Index poisoning | ❌ No checksums yet |
| Data loss | ✅ Trash default on delete |
| Git credential leak | N/A — versioning not implemented |
| DoS (massive file) | ✅ Attachment size limit; note size not enforced |
| Template injection | N/A — templates not implemented |

---

## 4. Code Quality Observations

### 4.1 Strengths
- Clean separation between Coalton pure core and CL IO boundary
- Consistent coding style across all files
- Proper use of CL condition system (not bare `error` strings)
- `declare` type annotations on all function parameters
- Mutation functions named with `!` suffix (`index-note!`, `register-links!`, etc.)

### 4.2 Improvement Suggestions (non-blocking)

1. **`move-note` folder validation is too restrictive:** It calls `%validate-note-name` on the folder, which rejects `/`. Folders inherently contain `/`. The function substitutes `/` with `-` as a workaround, which silently changes the user's intent.

2. **Search index uses alists:** The spec calls for hash-table-based trigram index for performance. Current alist approach is O(n) per lookup. Fine for small vaults, won't meet the <200ms target at 10k notes.

3. **Backlink index stale entry cleanup:** `register-links!` doesn't remove old backward entries when a source's targets change. If note A linked to B, then A is updated to link to C, B's backward map still shows A.

4. **No ASDF system definition:** Neither `.asd` file exists. The test suite uses raw `load` calls. This needs to be created before the package is usable as a dependency.

---

## 5. Verdict

| Category | Status |
|----------|--------|
| API stability | ✅ PASS |
| Naming consistency | ✅ PASS |
| ftype coverage | ✅ 100% |
| Security (implemented) | ✅ PASS |
| Security (stubs/gaps) | ⚠️ Known gaps documented |
| Test suite | ✅ 22/22 E2E passing |
| Production readiness | ⚠️ Needs ASDF, real parser, sanitizer |

**Overall: APPROVED for current phase.** The vault/note/attachment/index layers are solid. The Coalton core modules are typed stubs that need fleshing out (parser, search, wikilink extraction), which is expected and tracked in downstream beads.
