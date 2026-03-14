;;; verify-daily-templates.lisp

(load "/home/slime/projects/clpkg-markdown-notes-app/src/vault/vault.lisp")
(load "/home/slime/projects/clpkg-markdown-notes-app/src/vault/note.lisp")
(load "/home/slime/projects/clpkg-markdown-notes-app/src/vault/daily.lisp")
(load "/home/slime/projects/clpkg-markdown-notes-app/src/vault/template.lisp")

(use-package :clpkg-markdown-notes/daily)
(use-package :clpkg-markdown-notes/template)
(use-package :clpkg-markdown-notes/note)

(defun ok (x) (format t "PASS ~A~%" x))

;; Daily note path format
(assert (string= "daily-2026-03-13" (daily-note-path 2026 3 13)))
(ok "daily note path")

;; Daily note creation
(let ((root (pathname (format nil "/tmp/clpkg-daily-~D/" (get-universal-time)))))
  (ensure-directories-exist (merge-pathnames #P"daily/" root))
  (let ((n (ensure-daily-note! root 2026 3 13)))
    (assert (note-record-p n))
    (assert (search "2026-03-13" (note-content n)))
    (ok "daily note creation"))
  ;; Idempotent
  (let ((n2 (ensure-daily-note! root 2026 3 13)))
    (assert (string= (note-content n2) (note-content (ensure-daily-note! root 2026 3 13))))
    (ok "daily note idempotent")))

;; Template variable extraction
(let ((vars (extract-variables "# {{title}} by {{author}}")))
  (assert (member "title" vars :test #'string=))
  (assert (member "author" vars :test #'string=))
  (ok "variable extraction"))

;; Template instantiation
(let* ((tmpl (make-template-record
              :name "test"
              :content "Hello {{name}}, today is {{date}}"
              :variables '("name" "date")))
       (result (instantiate-template tmpl '(("name" . "Alice") ("date" . "2026-03-13")))))
  (assert (string= "Hello Alice, today is 2026-03-13" result))
  (ok "template instantiation"))

;; Empty bindings
(let* ((tmpl (make-template-record :name "bare" :content "no vars here"))
       (result (instantiate-template tmpl '())))
  (assert (string= "no vars here" result))
  (ok "template no vars"))

(format t "DAILY+TEMPLATE CHECKS PASSED~%")
(sb-ext:exit :code 0)
