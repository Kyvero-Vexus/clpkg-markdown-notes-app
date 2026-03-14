;;; verify-import-encryption.lisp

(defun slurp (path)
  (with-open-file (in path :direction :input)
    (let ((s (make-string (file-length in))))
      (read-sequence s in)
      s)))

(defun must-contain (content needle path)
  (unless (search needle content :test #'char=)
    (error "Missing required token ~S in ~A" needle path))
  (format t "PASS ~A contains ~S~%" (file-namestring path) needle))

;; Org-mode import surface
(let* ((path "/home/slime/projects/clpkg-markdown-notes-app/src/import/orgmode.coal")
       (c (slurp path)))
  (dolist (needle '("module Import.OrgMode" "data OrgImportConfig" "data OrgLine"
                    "classify-org-line" "org-to-markdown"))
    (must-contain c needle path)))

;; Encryption runtime
(load "/home/slime/projects/clpkg-markdown-notes-app/src/vault/encryption.lisp")
(use-package :clpkg-markdown-notes/encryption)

;; Generate key
(let ((key (generate-key-metadata)))
  (assert (encryption-key-p key))
  (assert (string= "AES-256-GCM" (ek-algorithm key)))
  (format t "PASS generate-key-metadata~%")

  ;; Encrypt
  (let ((enc (encrypt-note-content key "test-note" "Hello, encrypted!")))
    (assert (encrypted-note-p enc))
    (assert (string= "test-note" (en-note-name enc)))
    (assert (string= (ek-id key) (en-key-id enc)))
    (format t "PASS encrypt-note-content~%")

    ;; Decrypt roundtrip
    (let ((plain (decrypt-note-content key enc)))
      (assert (string= "Hello, encrypted!" plain))
      (format t "PASS decrypt roundtrip~%"))))

;; Error condition exists
(assert (subtypep 'encryption-error 'error))
(format t "PASS encryption-error condition~%")

(format t "IMPORT+ENCRYPTION CHECKS PASSED~%")
(sb-ext:exit :code 0)
