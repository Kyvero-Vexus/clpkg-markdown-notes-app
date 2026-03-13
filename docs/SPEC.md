# clpkg-markdown-notes-app — Full Specification

> Sanitized public version (internal tracker IDs removed).


**Repo target:** Kyvero-Vexus/clpkg-markdown-notes-app
**Status:** ACTIVE — fully tractable

---

## 1. Product Vision & Requirements

A **typed Common Lisp markdown notes library** providing note storage, organization, search, linking, and export. Think Obsidian's data model as a reusable CL package — no GUI, pure API. Designed as the notes backbone for CL-Emacs but usable standalone.

### 1.1 Capability Matrix

| Capability | Priority | Status |
|---|---|---|
| CommonMark parsing (full spec) | P0 | Actionable |
| YAML front-matter parsing | P0 | Actionable |
| Note CRUD (create/read/update/delete) | P0 | Actionable |
| Filesystem vault storage (flat + nested dirs) | P0 | Actionable |
| Wiki-style internal links (`[[note-name]]`) | P0 | Actionable |
| Tag system (front-matter + inline `#tag`) | P0 | Actionable |
| Full-text search (trigram index) | P1 | Actionable |
| Backlink graph (bidirectional link index) | P1 | Actionable |
| Template system (note templates) | P1 | Actionable |
| Daily notes (date-keyed auto-creation) | P1 | Actionable |
| Markdown → HTML export | P1 | Actionable |
| Markdown → Org-mode export | P2 | Actionable |
| Block-level references (`[[note#heading]]`, `[[note^blockid]]`) | P2 | Actionable |
| Embedded/transclusion (`![[note]]`) | P2 | Actionable |
| Attachment management (images, files) | P1 | Actionable |
| Note versioning (git-backed) | P2 | Actionable |
| Vault merge/sync conflict resolution | P3 | Actionable but complex — deferred to post-MVP |
| Markdown extensions (math, footnotes, tables) | P1 | Actionable |
| Graph visualization data export (JSON) | P2 | Actionable |
| Encryption at rest (per-note) | P2 | Actionable |
| Org-mode import | P2 | Actionable |
| Pandoc-compatible AST bridge | P3 | DEFERRED — scope creep risk; revisit after core stable |

### 1.2 Non-goals (explicit)

- No built-in GUI/TUI — this is a data/API library
- No real-time collaborative editing (CRDT) — different package scope
- No cloud sync service — vault is filesystem + optional git
- No plugin/extension system in v1 — CLOS generics are the extension point

---

## 2. Architecture

### 2.1 Module Map

```
clpkg-markdown-notes/
├── core/                  # Coalton — pure data transformations
│   ├── markdown.coal      # CommonMark parser → AST
│   ├── ast.coal           # Markdown AST types
│   ├── frontmatter.coal   # YAML front-matter parser
│   ├── wikilink.coal      # [[link]] and ![[embed]] parser
│   ├── tags.coal          # Tag extraction and normalization
│   ├── search-index.coal  # Trigram index builder (pure)
│   └── graph.coal         # Link graph operations (backlinks, reachability)
├── vault/                 # SBCL-typed CL — filesystem IO
│   ├── vault.lisp         # Vault root, note discovery, file IO
│   ├── note.lisp          # Note object (metadata + content + parsed AST)
│   ├── attachment.lisp    # Attachment management
│   ├── daily.lisp         # Daily notes auto-creation
│   ├── template.lisp      # Template instantiation
│   └── versioning.lisp    # Git-backed version tracking
├── index/                 # SBCL-typed CL — search & graph index
│   ├── search.lisp        # Full-text search engine
│   ├── backlinks.lisp     # Backlink index maintenance
│   ├── tag-index.lisp     # Tag → notes index
│   └── cache.lisp         # Index persistence (serialize to .vault-index/)
├── export/                # SBCL-typed CL — output formats
│   ├── html.lisp          # AST → HTML renderer
│   ├── orgmode.lisp       # AST → Org-mode renderer
│   └── json-graph.lisp    # Graph → JSON export
├── import/                # SBCL-typed CL — input formats
│   └── orgmode.lisp       # Org-mode → Markdown AST
└── crypto/                # SBCL-typed CL — optional encryption
    └── note-encrypt.lisp  # AES-256-GCM per-note encryption
```

### 2.2 Coalton Core Rationale

The `core/` module is **pure Coalton** because:
- Markdown parsing is a pure function (string → AST) — algebraic types shine
- Link graph operations are pure graph algorithms
- Trigram index construction is a pure fold over note contents
- Front-matter parsing is pure YAML subset → typed record
- All of these benefit from exhaustive pattern matching and are highly testable

### 2.3 Key Types (Coalton)

```coalton
;; Markdown AST
(define-type MdNode
  (MdDocument (List MdBlock)))

(define-type MdBlock
  (MdHeading UFix (List MdInline))            ; level, content
  (MdParagraph (List MdInline))
  (MdCodeBlock (Optional String) String)       ; lang, code
  (MdBlockquote (List MdBlock))
  (MdList Boolean (List (List MdBlock)))       ; ordered?, items
  (MdThematicBreak)
  (MdTable (List MdTableRow))
  (MdMath String)                              ; display math
  (MdFootnoteDef String (List MdBlock))
  (MdHtmlBlock String))

(define-type MdInline
  (MdText String)
  (MdEmphasis (List MdInline))
  (MdStrong (List MdInline))
  (MdCode String)
  (MdLink String (Optional String) (List MdInline))  ; url, title, children
  (MdImage String (Optional String) String)           ; url, title, alt
  (MdWikiLink String (Optional String))               ; target, display-text
  (MdWikiEmbed String)                                ; target
  (MdBlockRef String String)                          ; note, block-id
  (MdTag String)                                      ; #tag
  (MdInlineMath String)
  (MdFootnoteRef String)
  (MdHardBreak)
  (MdHtmlInline String))

;; Front-matter
(define-type FrontMatter
  (FrontMatter (Map String FmValue)))

(define-type FmValue
  (FmString String)
  (FmList (List String))
  (FmNumber Double-Float)
  (FmBool Boolean)
  (FmDate String))                              ; ISO 8601

;; Note metadata
(define-type NoteMeta
  (NoteMeta
    String              ; id (filename stem)
    (Optional String)   ; title (from H1 or front-matter)
    FrontMatter         ; parsed front-matter
    (List String)       ; tags (merged front-matter + inline)
    (List String)       ; outgoing wiki-links (targets)
    String))            ; vault-relative path

;; Link graph
(define-type LinkGraph
  (LinkGraph
    (Map String (List String))    ; forward: note → [targets]
    (Map String (List String))))  ; backward: note → [sources]

;; Search
(define-type SearchResult
  (SearchResult String Double-Float String))  ; note-id, score, snippet
```

### 2.4 SBCL-Typed Boundary (vault/index/export)

```lisp
;; Vault operations
(declaim (ftype (function (pathname &key (:recursive boolean))
                          (values vault &optional))
                open-vault))
(declaim (ftype (function (vault string string &key (:front-matter list)
                                                    (:template (or null string)))
                          (values note &optional))
                create-note))
(declaim (ftype (function (vault string) (values (or null note) &optional))
                find-note))
(declaim (ftype (function (vault string) (values list &optional))
                search-notes))
```

### 2.5 Public API Surface

```lisp
;;; ---- Vault lifecycle ----
(defgeneric open-vault (path &key recursive watch) → vault)
(defgeneric close-vault (vault))
(defgeneric rebuild-index (vault &key force))

;;; ---- Note CRUD ----
(defgeneric create-note (vault name content &key front-matter template folder))
(defgeneric read-note (vault name) → note)
(defgeneric update-note (vault name new-content &key merge-front-matter))
(defgeneric delete-note (vault name &key trash))  ; trash by default, not rm
(defgeneric rename-note (vault old-name new-name &key update-links))
(defgeneric move-note (vault name new-folder &key update-links))

;;; ---- Query ----
(defgeneric search (vault query &key limit tags folder sort) → (list search-result))
(defgeneric find-by-tag (vault tag) → (list note-meta))
(defgeneric backlinks (vault name) → (list note-meta))
(defgeneric forward-links (vault name) → (list note-meta))
(defgeneric orphan-notes (vault) → (list note-meta))
(defgeneric all-tags (vault) → (list (cons string fixnum)))  ; tag + count
(defgeneric link-graph (vault) → link-graph)
(defgeneric daily-note (vault &key date) → note)

;;; ---- Export ----
(defgeneric export-html (note &key standalone css) → string)
(defgeneric export-org (note) → string)
(defgeneric export-graph-json (vault) → string)

;;; ---- Import ----
(defgeneric import-org-file (vault path &key folder))

;;; ---- Versioning ----
(defgeneric note-history (vault name &key limit) → (list version-entry))
(defgeneric note-at-version (vault name version) → note)
(defgeneric commit-vault (vault message))

;;; ---- Crypto ----
(defgeneric encrypt-note (vault name passphrase))
(defgeneric decrypt-note (vault name passphrase) → note)
```

### 2.6 Dependency Budget

| Dependency | Purpose | License |
|---|---|---|
| coalton | Core typed modules | MIT |
| alexandria | Utilities | Public Domain |
| cl-ppcre | Regex for MD parsing helpers | BSD |
| ironclad | AES-256-GCM encryption | BSD |
| local-time | Date handling for daily notes | MIT |
| bordeaux-threads | Index rebuilds in background | MIT |
| uiop | Filesystem operations (ASDF-bundled) | MIT |

All libre. No non-free dependencies.

---

## 3. Security Model

### 3.1 Threat Model

| Threat | Vector | Mitigation |
|---|---|---|
| Path traversal | Crafted note names (`../../etc/passwd`) | Canonicalize all paths; reject any that escape vault root |
| Markdown injection | XSS via HTML export | HTML export sanitizes by default; raw HTML blocks opt-in only |
| Symlink escape | Symlink pointing outside vault | Resolve symlinks and verify target within vault root |
| Front-matter injection | Malicious YAML | Subset YAML parser only (no `!!eval`, no anchors, no merge keys) |
| Encryption weakness | Weak passphrase | Use Argon2id KDF (memory=64MB, iterations=3) for key derivation |
| Index poisoning | Corrupt index cache | Checksummed index files; full rebuild on checksum mismatch |
| Data loss | Delete without confirmation | `delete-note` moves to `.trash/` by default; permanent delete requires `:trash nil` |
| Git credential leak | Versioning exposes .git | Never index/search inside `.git/` directory |
| Denial of service | Massive file as "note" | Max note size default 10MB; configurable |
| Template injection | Template with executable code | Templates are text-only with `{{variable}}` substitution; no eval |

### 3.2 Hardening Checklist

- [ ] All file paths canonicalized and sandboxed to vault root
- [ ] No `read-from-string` or `eval` on any note content
- [ ] HTML export uses allowlist of safe tags/attributes
- [ ] Encryption keys zeroed from memory after use
- [ ] `.vault-index/` contents are non-executable data only
- [ ] Temporary files created with restrictive permissions (600)

---

## 4. Performance Model

### 4.1 Budgets

| Operation | Target | Measurement |
|---|---|---|
| Parse single note (1KB markdown) | < 1ms | Microbenchmark |
| Parse single note (100KB markdown) | < 50ms | Microbenchmark |
| Open vault (10,000 notes, cold index) | < 10s | Wall clock |
| Open vault (10,000 notes, warm index) | < 1s | Wall clock |
| Full-text search (10,000 notes) | < 200ms | Wall clock |
| Backlink lookup | < 1ms (index hit) | Microbenchmark |
| Create note | < 5ms (write + index update) | Wall clock |
| HTML export (single note) | < 10ms | Microbenchmark |
| Memory per vault (10,000 notes, indexed) | < 100MB | `sb-ext:dynamic-space-usage` |
| Incremental index update (1 note changed) | < 50ms | Wall clock |

### 4.2 Profiling Strategy

1. **Parser benchmarks:** CommonMark spec examples + large real-world markdown files
2. **Vault scale test:** Generate synthetic vault with 10k/50k/100k notes; measure open/search/backlink times
3. **Memory profiling:** `sb-sprof` on vault open with 10k notes
4. **Index persistence:** Measure serialize/deserialize times for index cache

### 4.3 Optimization Notes

- Trigram index stored as hash table of `(unsigned-byte 24)` → sorted note-id vectors
- Backlink graph stored as adjacency list in hash tables
- Lazy AST parsing: notes loaded as raw text, parsed on demand, AST cached
- Index is incrementally maintained on note CRUD; full rebuild only on cache miss
- Front-matter parsed separately from body to enable fast metadata scans

---

## 5. End-to-End Usage Test Matrix

### 5.1 Test Infrastructure

- **Test framework:** FiveAM for unit/integration
- **Fixture vaults:** Pre-built directory trees with known notes
- **Temporary vault helper:** Creates tmpdir vault, populates, cleans up

### 5.2 Scenario Matrix

| ID | Scenario | Covers | Type |
|---|---|---|---|
| E01 | Open vault, create note with front-matter + tags, read it back, verify content + metadata | CRUD, front-matter, tags | E2E |
| E02 | Create note A linking to B, verify A appears in B's backlinks | Wiki-links, backlink graph | E2E |
| E03 | Create 3 notes with tags, query by tag, verify correct results | Tag index | E2E |
| E04 | Full-text search across 100 notes, verify relevance ordering | Search | E2E |
| E05 | Rename note that is linked from 5 other notes, verify all links updated | Rename + link update | E2E |
| E06 | Delete note, verify it appears in `.trash/`, verify backlinks show broken link | Delete, trash | E2E |
| E07 | Create daily note for today, verify naming convention + template applied | Daily notes, templates | E2E |
| E08 | Export note with headings, code blocks, links, images to HTML, verify valid HTML | HTML export | E2E |
| E09 | Export note to Org-mode, verify valid org syntax | Org export | E2E |
| E10 | Import Org-mode file, verify converted note has correct content + metadata | Org import | E2E |
| E11 | Parse CommonMark spec examples (624 examples), verify correct AST | Parser correctness | Integration |
| E12 | Note with `[[link#heading]]` and `[[note^blockid]]`, verify resolution | Block references | E2E |
| E13 | Encrypt note, close vault, reopen, decrypt, verify content intact | Encryption | E2E |
| E14 | Open vault with 10,000 synthetic notes, search, verify < 200ms | Performance | Benchmark |
| E15 | Attempt path traversal (`../../etc/passwd`), verify rejected | Security | E2E |
| E16 | Note with embedded HTML, export, verify sanitized output | Security (XSS) | E2E |
| E17 | Concurrent create + search from 2 threads, verify no corruption | Thread safety | E2E |
| E18 | Incremental index: modify 1 note in 10k vault, verify index update < 50ms | Index performance | Benchmark |
| E19 | Note with math, footnotes, tables — verify parser handles extensions | MD extensions | E2E |
| E20 | Export link graph as JSON, verify all nodes/edges present | Graph export | E2E |
| E21 | `orphan-notes` on vault with 3 unlinked notes, verify correct list | Graph analysis | E2E |
| E22 | Template with `{{date}}`, `{{title}}` placeholders, verify substitution | Templates | E2E |

### 5.3 Coverage Target

- Line coverage: > 90% on `core/` (Coalton — parser, graph, index)
- Line coverage: > 85% on `vault/`, `index/`, `export/`
- All P0/P1 capabilities have at least one E2E scenario
- CommonMark spec compliance: > 95% of spec examples pass
- All security mitigations have negative tests

---

## 6. Repo Bootstrap Plan

```
Kyvero-Vexus/clpkg-markdown-notes/
├── clpkg-markdown-notes.asd
├── clpkg-markdown-notes-test.asd
├── README.md
├── LICENSE                    # MIT or BSD-2
├── .gitignore
├── src/
│   ├── core/                  # Coalton modules
│   ├── vault/                 # Filesystem layer
│   ├── index/                 # Search & graph index
│   ├── export/                # Output renderers
│   ├── import/                # Input converters
│   └── crypto/                # Encryption
├── test/
│   ├── core/                  # Parser, graph, index unit tests
│   ├── vault/                 # Vault CRUD tests
│   ├── e2e/                   # End-to-end scenarios
│   ├── fixtures/              # Pre-built test vaults
│   ├── commonmark-spec/       # CommonMark spec test runner
│   └── benchmark/             # Performance benchmarks
└── docs/
    ├── API.md
    └── ARCHITECTURE.md
```

---

## 7. Child Bead Tree

### Phase 1: Parser Foundation (no deps)
- **stts.2** — Implement Coalton core: CommonMark parser + AST types
- **stts.3** — Implement Coalton core: front-matter parser + wiki-link/tag extraction

### Phase 2: Storage (depends on Phase 1)
- **stts.4** — Implement vault layer: note CRUD + filesystem operations + attachment management
- **stts.5** — Implement vault layer: daily notes + templates

### Phase 3: Indexing (depends on Phase 1+2)
- **stts.6** — Implement Coalton core: trigram search index + link graph
- **stts.7** — Implement index layer: search engine, backlink index, tag index, persistence

### Phase 4: Export/Import (depends on Phase 1)
- **stts.8** — Implement export: HTML renderer + sanitizer
- **stts.9** — Implement export: Org-mode renderer + JSON graph export
- **stts.10** — Implement import: Org-mode → MD converter

### Phase 5: Advanced (depends on Phase 2+3)
- **stts.11** — Implement block references + transclusion
- **stts.12** — Implement encryption (AES-256-GCM + Argon2id)
- **stts.13** — Implement git-backed versioning

### Verification
- **stts.14** — CommonMark spec test suite + parser property tests
- **stts.15** — Full E2E scenario suite (E01–E22) + coverage gate
- **stts.16** — Performance benchmarks + budget verification

### Review
- **stts.17** — Architecture review: API stability, type coverage, security audit
- **stts.18** — Documentation: API.md, ARCHITECTURE.md, README

---

## 8. Tractability Assessment

**Verdict: FULLY TRACTABLE.** CommonMark has a formal spec with test suite. Filesystem-backed note vaults are well-understood. All capabilities are implementable with existing CL infrastructure. Coalton is suitable for the pure parser/graph core.

**One note:** The CommonMark parser is the largest single implementation effort (~2000 lines of Coalton estimated). It should be the first thing built and tested against the official spec suite.

**Deferred items:**
- Pandoc AST bridge (P3) — deferred until core is stable; prerequisite: stable AST types frozen
- Vault merge/sync (P3) — deferred; prerequisite: versioning layer complete + CRDT research

---

## 9. Handoff Summary

- **Spec doc:** `docs/clpkg-markdown-notes-app-spec.md`
- **First executable step:** Create repo, bootstrap ASDF system, implement `stts.2` (Coalton CommonMark parser)
- **Critical path:** stts.2 → stts.4 → stts.6 → stts.7 → stts.15
- **Estimated total implementation beads:** 17

## 10. Active Bead Breakdown References

- `(internal-tracker)` detailed execution plan: `docs/stts-l7nq-vault-breakdown.md`
