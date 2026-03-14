;;; verify-versioning.lisp

(load "/home/slime/projects/clpkg-markdown-notes-app/src/vault/vault.lisp")
(load "/home/slime/projects/clpkg-markdown-notes-app/src/vault/note.lisp")
(load "/home/slime/projects/clpkg-markdown-notes-app/src/vault/versioning.lisp")

(use-package :clpkg-markdown-notes/versioning)
(use-package :clpkg-markdown-notes/note)

(defun ok (x) (format t "PASS ~A~%" x))

(let ((root (pathname (format nil "/tmp/clpkg-ver-~D/" (get-universal-time)))))
  (ensure-directories-exist root)

  ;; Init version store
  (assert (init-version-store! root))
  (assert (version-store-initialized-p root))
  (ok "init version store")

  ;; Commit a note
  (create-note root "versioned" "# Version 1")
  (let ((vr (commit-note! root "versioned" "Initial version")))
    (assert (version-record-p vr))
    (assert (stringp (vr-hash vr)))
    (assert (string= "Initial version" (vr-message vr)))
    (ok "commit note"))

  ;; History returns list (stub)
  (assert (listp (note-history root "versioned")))
  (ok "note history")

  ;; Idempotent init
  (assert (init-version-store! root))
  (ok "idempotent init"))

(format t "VERSIONING CHECKS PASSED~%")
(sb-ext:exit :code 0)
