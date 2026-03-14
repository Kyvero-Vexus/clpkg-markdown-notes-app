# clpkg-markdown-notes — Architecture

## Layer Diagram

```
┌─────────────────────────────────────────────┐
│              Coalton Core Layer             │
│  ast.coal  markdown.coal  frontmatter.coal  │
│  wikilink.coal  tags.coal  search.coal      │
│  Export: html.coal                          │
└──────────────────┬──────────────────────────┘
                   │ pure typed ADTs
┌──────────────────┴──────────────────────────┐
│              Index Layer (CL)               │
│  search.lisp  backlinks.lisp  tag-index.lisp│
└──────────────────┬──────────────────────────┘
                   │ indexes vault content
┌──────────────────┴──────────────────────────┐
│              Vault Layer (CL)               │
│  vault.lisp  note.lisp  attachment.lisp     │
│  daily.lisp  template.lisp                  │
└─────────────────────────────────────────────┘
```

## Design Principles

1. **Coalton-first for pure core** — AST types, parsers, and renderers are implemented in Coalton for total type safety.
2. **CL for IO and state** — Vault operations, indexing, and file system interaction use typed Common Lisp with `ftype` declarations and `safety 3` clean compilation.
3. **Typed conditions** — All error paths use structured conditions (`note-invalid-name`, `vault-traversal-rejected`, `attachment-too-large`, `attachment-blocked-mime`) rather than strings.
4. **Path sandboxing** — All vault IO is guarded by `resolve-vault-relative-path` which rejects traversal attempts (symlink, `..`, absolute escapes).
5. **Dedupe by content hash** — Attachments are keyed by MD5 hash for automatic deduplication.

## Module Boundaries

| Module | Depends On | Provides |
|--------|-----------|----------|
| Coalton Core | (none) | AST types, parser contracts |
| vault.lisp | (none) | Path sandbox, canonical IO |
| note.lisp | vault | Note CRUD |
| attachment.lisp | vault | Attachment storage + policy |
| daily.lisp | note | Daily note auto-creation |
| template.lisp | (none) | Template instantiation |
| search.lisp | (none) | Trigram search engine |
| backlinks.lisp | (none) | Backlink index |
| tag-index.lisp | (none) | Tag index |
| html.coal | Core.AST | HTML rendering |

## Security Model

- **Path traversal prevention** — `resolve-vault-relative-path` rejects `..`, symlinks escaping vault, and absolute paths.
- **MIME allowlist** — Attachment storage enforces configurable MIME type allowlist.
- **Size policy** — Configurable max attachment size with typed condition on violation.
- **Atomic writes** — Note updates use atomic file replacement.

## Testing Strategy

- **Surface verification scripts** — Symbol presence checks via SBCL `--script`
- **E2E scenario suite** — 22 scenarios covering CRUD, security guards, search, backlinks, tags, and cross-layer integration
- **Property tests** — Determinism and totality checks on parsers
