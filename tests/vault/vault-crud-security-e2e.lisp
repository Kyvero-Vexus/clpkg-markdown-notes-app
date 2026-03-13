;;; vault-crud-security-e2e.lisp

(load "/home/slime/projects/clpkg-markdown-notes-app/src/vault/vault.lisp")
(load "/home/slime/projects/clpkg-markdown-notes-app/src/vault/note.lisp")
(load "/home/slime/projects/clpkg-markdown-notes-app/src/vault/attachment.lisp")

(use-package :clpkg-markdown-notes/note)
(use-package :clpkg-markdown-notes/attachment)
(use-package :clpkg-markdown-notes/vault)

(defun ms-since (start)
  (/ (- (get-internal-real-time) start)
     (/ internal-time-units-per-second 1000.0)))

(defun ok (x) (format t "PASS ~A~%" x))

(let* ((root (pathname (format nil "/tmp/clpkg-vault-e2e-~D/" (get-universal-time)))))
  (ensure-directories-exist (merge-pathnames #P".trash/" root))

  ;; CRUD happy path
  (let ((t0 (get-internal-real-time)))
    (create-note root "n1" "hello")
    (let ((r (read-note root "n1")))
      (assert (string= "hello" (note-content r))))
    (update-note root "n1" "updated")
    (delete-note root "n1" :trash t)
    (let ((elapsed (ms-since t0)))
      (format t "INFO crud-ms=~,2f~%" elapsed)
      (assert (< elapsed 500.0)))
    (ok "crud happy path + budget"))

  ;; traversal denial
  (handler-case
      (progn (create-note root "../escape" "x") (error "expected traversal deny"))
    (note-invalid-name () (ok "note traversal denied")))

  ;; attachment boundaries
  (let ((a (store-attachment root "img.txt" "blob" :mime "text/plain" :max-size 100)))
    (assert (attachment-record-p a))
    (ok "attachment happy path"))

  (handler-case
      (progn (store-attachment root "bad.bin" "abc" :mime "application/x-msdownload")
             (error "expected blocked mime"))
    (attachment-blocked-mime () (ok "blocked mime denied")))

  ;; symlink/path guard primitive still wired
  (handler-case
      (progn (resolve-vault-relative-path root "../bad")
             (error "expected traversal reject"))
    (vault-traversal-rejected () (ok "vault traversal guard"))))

(format t "VAULT CRUD+SECURITY E2E PASS~%")
(sb-ext:exit :code 0)
