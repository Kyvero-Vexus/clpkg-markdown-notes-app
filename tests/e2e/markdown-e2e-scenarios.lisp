;;; markdown-e2e-scenarios.lisp — E2E scenario suite for markdown notes

(load "/home/slime/projects/clpkg-markdown-notes-app/src/vault/vault.lisp")
(load "/home/slime/projects/clpkg-markdown-notes-app/src/vault/note.lisp")
(load "/home/slime/projects/clpkg-markdown-notes-app/src/vault/attachment.lisp")
(load "/home/slime/projects/clpkg-markdown-notes-app/src/index/search.lisp")
(load "/home/slime/projects/clpkg-markdown-notes-app/src/index/backlinks.lisp")
(load "/home/slime/projects/clpkg-markdown-notes-app/src/index/tag-index.lisp")

(use-package :clpkg-markdown-notes/vault)
(use-package :clpkg-markdown-notes/note)
(use-package :clpkg-markdown-notes/attachment)
(use-package :clpkg-markdown-notes/search)
(use-package :clpkg-markdown-notes/backlinks)
(use-package :clpkg-markdown-notes/tags)

(defvar *pass* 0)
(defvar *fail* 0)
(defun ok (x) (incf *pass*) (format t "PASS E~2,'0D: ~A~%" *pass* x))

(let* ((root (pathname (format nil "/tmp/clpkg-md-e2e-~D/" (get-universal-time)))))
  (ensure-directories-exist (merge-pathnames #P".trash/" root))
  (ensure-directories-exist (merge-pathnames #P"attachments/" root))

  ;; E01: Create and read note
  (create-note root "hello" "# Hello World")
  (let ((n (read-note root "hello")))
    (assert (string= "# Hello World" (note-content n)))
    (ok "create + read note"))

  ;; E02: Update note
  (update-note root "hello" "# Updated")
  (let ((n (read-note root "hello")))
    (assert (string= "# Updated" (note-content n)))
    (ok "update note"))

  ;; E03: Delete to trash
  (create-note root "temp" "delete me")
  (delete-note root "temp" :trash t)
  (ok "delete to trash")

  ;; E04: Path traversal denied
  (handler-case
      (progn (create-note root "../escape" "x") (error "expected deny"))
    (note-invalid-name () (ok "path traversal denied")))

  ;; E05: Vault traversal guard
  (handler-case
      (progn (resolve-vault-relative-path root "../bad") (error "expected deny"))
    (vault-traversal-rejected () (ok "vault traversal guard")))

  ;; E06: Attachment store + dedupe
  (let* ((a1 (store-attachment root "img.txt" "blob" :mime "text/plain" :max-size 1000))
         (a2 (store-attachment root "img.txt" "blob" :mime "text/plain" :max-size 1000)))
    (assert (string= (attachment-key a1) (attachment-key a2)))
    (assert (attachment-deduped-p a2))
    (ok "attachment store + dedupe"))

  ;; E07: Attachment size policy
  (handler-case
      (progn (store-attachment root "big.bin" "0123456789" :mime "text/plain" :max-size 2)
             (error "expected too-large"))
    (attachment-too-large () (ok "attachment size policy")))

  ;; E08: Attachment MIME policy
  (handler-case
      (progn (store-attachment root "evil.exe" "x" :mime "application/x-msdownload")
             (error "expected blocked"))
    (attachment-blocked-mime () (ok "attachment MIME policy")))

  ;; E09: Search index + query
  (let ((idx (make-search-index)))
    (index-note! idx "hello" "# Updated")
    (index-note! idx "world" "World domination")
    (let ((results (search-notes idx "world")))
      (assert (> (length results) 0))
      (ok "search index + query")))

  ;; E10: Backlink registration + query
  (let ((bi (make-backlink-index)))
    (register-links! bi "hello" '("world"))
    (assert (member "hello" (get-backlinks bi "world") :test #'string=))
    (ok "backlink index"))

  ;; E11: Forward links
  (let ((bi (make-backlink-index)))
    (register-links! bi "a" '("b" "c"))
    (assert (= 2 (length (get-forward-links bi "a"))))
    (ok "forward links"))

  ;; E12: Orphan detection
  (let ((bi (make-backlink-index)))
    (register-links! bi "a" '("b"))
    (let ((orphans (find-orphans bi '("a" "b" "c"))))
      (assert (member "c" orphans :test #'string=))
      (ok "orphan detection")))

  ;; E13: Tag index register + query
  (let ((ti (make-tag-index)))
    (register-tags! ti "hello" '("greeting" "test"))
    (register-tags! ti "world" '("test"))
    (assert (= 2 (length (get-notes-by-tag ti "test"))))
    (ok "tag index"))

  ;; E14: All tags enumeration
  (let ((ti (make-tag-index)))
    (register-tags! ti "a" '("x" "y"))
    (register-tags! ti "b" '("y" "z"))
    (assert (= 3 (length (all-tags ti))))
    (ok "all tags enumeration"))

  ;; E15: Trigram extraction correctness
  (let ((tris (extract-trigrams "Common Lisp")))
    (assert (member "com" tris :test #'string=))
    (assert (member "lis" tris :test #'string=))
    (ok "trigram extraction"))

  ;; E16: Search returns ranked results
  (let ((idx (make-search-index)))
    (index-note! idx "exact" "common lisp programming common lisp")
    (index-note! idx "partial" "lisp is great")
    (let ((results (search-notes idx "common lisp")))
      (assert (string= "exact" (caar results)))
      (ok "search ranking")))

  ;; E17: Note CRUD full cycle
  (create-note root "lifecycle" "v1")
  (update-note root "lifecycle" "v2")
  (let ((n (read-note root "lifecycle")))
    (assert (string= "v2" (note-content n))))
  (delete-note root "lifecycle" :trash t)
  (ok "note CRUD lifecycle")

  ;; E18: Multiple notes coexist
  (create-note root "n1" "one")
  (create-note root "n2" "two")
  (create-note root "n3" "three")
  (assert (string= "one" (note-content (read-note root "n1"))))
  (assert (string= "three" (note-content (read-note root "n3"))))
  (ok "multiple notes coexist")

  ;; E19: Search empty index returns nothing
  (let ((idx (make-search-index)))
    (assert (null (search-notes idx "anything")))
    (ok "search empty index"))

  ;; E20: Backlinks empty index returns nil
  (let ((bi (make-backlink-index)))
    (assert (null (get-backlinks bi "nothing")))
    (ok "backlinks empty"))

  ;; E21: Tag index empty returns nil
  (let ((ti (make-tag-index)))
    (assert (null (get-notes-by-tag ti "nothing")))
    (ok "tag empty"))

  ;; E22: Cross-layer: create note + index + search + backlinks
  (create-note root "wiki-a" "See [[wiki-b]] for details")
  (create-note root "wiki-b" "Referenced from wiki-a")
  (let ((idx (make-search-index))
        (bi (make-backlink-index)))
    (index-note! idx "wiki-a" "See wiki-b for details")
    (index-note! idx "wiki-b" "Referenced from wiki-a")
    (register-links! bi "wiki-a" '("wiki-b"))
    (assert (> (length (search-notes idx "wiki")) 0))
    (assert (member "wiki-a" (get-backlinks bi "wiki-b") :test #'string=))
    (ok "cross-layer integration")))

(format t "~%E2E RESULTS: ~D/~D PASSED~%" *pass* (+ *pass* *fail*))
(assert (= 0 *fail*))
(sb-ext:exit :code 0)
