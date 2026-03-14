# clpkg-markdown-notes — API Reference

## Packages

### clpkg-markdown-notes/vault
Path sandbox and canonical IO primitives.

| Symbol | Type | Description |
|--------|------|-------------|
| `normalize-vault-root` | function | Canonicalize vault root pathname |
| `resolve-vault-relative-path` | function | Resolve path within vault (rejects traversal) |
| `vault-traversal-rejected` | condition | Signaled on path escape attempt |

### clpkg-markdown-notes/note
Typed note CRUD with atomic updates and trash semantics.

| Symbol | Type | Description |
|--------|------|-------------|
| `note-record` | struct | Note record (content, path, metadata) |
| `create-note` | function | `(vault-root name content) → note-record` |
| `read-note` | function | `(vault-root name) → note-record` |
| `update-note` | function | `(vault-root name content) → note-record` |
| `delete-note` | function | `(vault-root name &key trash) → t` |
| `note-invalid-name` | condition | Signaled on invalid note name |

### clpkg-markdown-notes/attachment
Attachment storage with dedupe and policy enforcement.

| Symbol | Type | Description |
|--------|------|-------------|
| `attachment-record` | struct | Attachment record (key, path, mime, size, deduped-p) |
| `store-attachment` | function | `(vault-root name content &key mime max-size) → attachment-record` |
| `allowed-mime-p` | function | `(mime allowed-list) → boolean` |
| `attachment-too-large` | condition | Signaled when content exceeds max-size |
| `attachment-blocked-mime` | condition | Signaled on disallowed MIME type |

### clpkg-markdown-notes/daily
Date-keyed daily note auto-creation.

| Symbol | Type | Description |
|--------|------|-------------|
| `daily-note-path` | function | `(year month day) → string` |
| `ensure-daily-note!` | function | `(vault-root year month day &key template) → note-record` |
| `daily-note-exists-p` | function | `(vault-root year month day) → boolean` |

### clpkg-markdown-notes/template
Template instantiation with `{{variable}}` substitution.

| Symbol | Type | Description |
|--------|------|-------------|
| `template-record` | struct | Template (name, content, variables) |
| `extract-variables` | function | `(content) → list-of-strings` |
| `instantiate-template` | function | `(template bindings) → string` |

### clpkg-markdown-notes/search
Trigram-based full-text search engine.

| Symbol | Type | Description |
|--------|------|-------------|
| `search-index` | struct | Index container |
| `index-note!` | function | `(index path content) → index` |
| `search-notes` | function | `(index query) → list-of-(path . score)` |
| `extract-trigrams` | function | `(text) → list-of-strings` |

### clpkg-markdown-notes/backlinks
Bidirectional backlink index.

| Symbol | Type | Description |
|--------|------|-------------|
| `backlink-index` | struct | Forward + backward link maps |
| `register-links!` | function | `(index source targets) → index` |
| `get-backlinks` | function | `(index target) → list-of-sources` |
| `get-forward-links` | function | `(index source) → list-of-targets` |
| `find-orphans` | function | `(index all-notes) → list` |

### clpkg-markdown-notes/tags
Tag index for notes.

| Symbol | Type | Description |
|--------|------|-------------|
| `tag-index` | struct | Tag → notes mapping |
| `register-tags!` | function | `(index note-path tags) → index` |
| `get-notes-by-tag` | function | `(index tag) → list` |
| `all-tags` | function | `(index) → list` |

## Coalton Modules

### Core.AST
Markdown AST node types.

### Core.Search
Typed trigram index + link graph (Trigram, TrigramIndex, LinkEdge, LinkGraph).

### Export.Html
HTML renderer + sanitizer (HtmlConfig, SanitizePolicy, render-to-html, sanitize-html).
