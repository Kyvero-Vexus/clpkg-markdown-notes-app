;;; verify-core-coalton-surface.lisp

(defun slurp (path)
  (with-open-file (in path :direction :input)
    (let ((s (make-string (file-length in))))
      (read-sequence s in)
      s)))

(defun must-contain (content needle path)
  (unless (search needle content :test #'char=)
    (error "Missing required token ~S in ~A" needle path))
  (format t "PASS ~A contains ~S~%" path needle))

(defun check-file (path needles)
  (unless (probe-file path)
    (error "Missing required file: ~A" path))
  (let ((c (slurp path)))
    (dolist (n needles)
      (must-contain c n path))))

(let ((base "/home/slime/projects/clpkg-markdown-notes-app/src/core/"))
  (check-file (concatenate 'string base "ast.coal")
              '("module Core.AST" "data MdNode" "data MdBlock" "data MdInline" "data FrontMatter" "data NoteMeta"))
  (check-file (concatenate 'string base "markdown.coal")
              '("module Core.Markdown" "data ParseError" "parse-commonmark"))
  (check-file (concatenate 'string base "frontmatter.coal")
              '("module Core.FrontMatter" "data FrontMatterError" "parse-front-matter"))
  (check-file (concatenate 'string base "wikilink.coal")
              '("module Core.WikiLink" "data WikiRef" "extract-wikilinks"))
  (check-file (concatenate 'string base "tags.coal")
              '("module Core.Tags" "normalize-tag" "extract-tags")))

(format t "ALL CORE SURFACE CHECKS PASSED~%")
(sb-ext:exit :code 0)
