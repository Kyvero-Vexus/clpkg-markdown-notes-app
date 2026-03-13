# Core Parser Status (wiq4 + 5wi9)

Date: 2026-03-13

## Delivered in this pass

### wiq4 — CommonMark parser + AST core

Added typed Coalton core module surfaces:

- `src/core/ast.coal`
- `src/core/markdown.coal`

Current baseline parser behavior is intentionally minimal but total:
- empty input -> `Err EmptyInput`
- non-empty input -> `Ok (MdDocument [MdParagraph ...])`

This establishes stable ADT and error surface for incremental parser expansion.

### 5wi9 — frontmatter + wikilink/tag extraction

Added typed module surfaces:

- `src/core/frontmatter.coal`
- `src/core/wikilink.coal`
- `src/core/tags.coal`

These define explicit types and extraction function signatures with total return paths.

## Verification

Executed:

```bash
sbcl --script scripts/verify-core-coalton-surface.lisp
```

Result: all required module/type/function surface checks passed.

## Next expansion targets

1. Implement delimiter-aware front-matter parser (`---` fenced header)
2. Implement lexical scanner for wiki links and embeds
3. Implement tag tokenizer with normalization/dedup
4. Extend markdown parser from paragraph baseline to heading/list/code-block forms
