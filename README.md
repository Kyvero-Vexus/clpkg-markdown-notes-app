# clpkg-markdown-notes

A typed Common Lisp package for markdown note management with vault storage, full-text search, backlink tracking, and template support.

## Features

- **Vault layer** — path-sandboxed note CRUD with atomic updates, trash semantics, and attachment storage with content-hash deduplication
- **Daily notes** — date-keyed auto-creation with template support
- **Templates** — `{{variable}}` extraction and instantiation
- **Full-text search** — trigram-based search engine with ranked results
- **Backlink index** — bidirectional link tracking with orphan detection
- **Tag index** — tag-based note organization and query
- **Coalton core** — typed AST, parser contracts, and HTML renderer/sanitizer
- **Security** — path traversal prevention, MIME allowlist, size policy enforcement

## Requirements

- SBCL 2.5+
- Quicklisp (for Coalton dependencies)

## Quick Start

```lisp
(load "src/vault/vault.lisp")
(load "src/vault/note.lisp")
(load "src/index/search.lisp")

(use-package :clpkg-markdown-notes/note)
(use-package :clpkg-markdown-notes/search)

;; Create and search notes
(create-note #P"/path/to/vault/" "hello" "# Hello World")
(let ((idx (make-search-index)))
  (index-note! idx "hello" "# Hello World")
  (search-notes idx "hello"))
```

## Testing

```bash
# Run all verification scripts
sbcl --script scripts/verify-attachment-storage.lisp
sbcl --script scripts/verify-daily-templates.lisp
sbcl --script scripts/verify-index-layer.lisp
sbcl --script scripts/verify-note-crud.lisp
sbcl --script scripts/verify-search-surface.lisp
sbcl --script scripts/verify-html-export-surface.lisp

# Run E2E suite
sbcl --script tests/e2e/markdown-e2e-scenarios.lisp
```

## Documentation

- [API Reference](docs/API.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Spec](docs/SPEC.md)

## License

MIT
