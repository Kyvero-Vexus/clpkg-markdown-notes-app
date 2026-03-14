;;; versioning.lisp --- git-backed note versioning

(defpackage #:clpkg-markdown-notes/versioning
  (:use #:cl)
  (:export
   #:version-record #:version-record-p #:make-version-record
   #:vr-hash #:vr-message #:vr-timestamp #:vr-author
   #:init-version-store!
   #:commit-note!
   #:note-history
   #:version-store-initialized-p))

(in-package #:clpkg-markdown-notes/versioning)

(defstruct (version-record
             (:constructor make-version-record (&key hash message timestamp author))
             (:conc-name vr-))
  (hash "" :type string)
  (message "" :type string)
  (timestamp 0 :type integer)
  (author "" :type string))

(declaim (ftype (function (pathname) (values boolean &optional)) init-version-store!)
         (ftype (function (pathname string string &key (:author string))
                          (values version-record &optional))
                commit-note!)
         (ftype (function (pathname string) (values list &optional)) note-history)
         (ftype (function (pathname) (values boolean &optional)) version-store-initialized-p))

(defun version-store-initialized-p (vault-root)
  "Check if vault has a .git directory."
  (declare (type pathname vault-root))
  (not (null (probe-file (merge-pathnames #P".git/" vault-root)))))

(defun init-version-store! (vault-root)
  "Initialize git repo in vault root if not already present."
  (declare (type pathname vault-root))
  (unless (version-store-initialized-p vault-root)
    (sb-ext:run-program "/bin/sh" (list "-c" (format nil "cd ~A && git init -q" (namestring vault-root)))
                        :output nil :error nil))
  (version-store-initialized-p vault-root))

(defun commit-note! (vault-root note-name message &key (author "vault"))
  "Stage and commit a note file. Returns version-record."
  (declare (type pathname vault-root) (type string note-name message author))
  (let* ((ts (get-universal-time))
         (hash (format nil "~36R" (logand (sxhash (format nil "~A~A~A" note-name message ts))
                                          #xFFFFFFFF))))
    (sb-ext:run-program "/bin/sh"
                        (list "-c" (format nil "cd ~A && git add ~A.md 2>/dev/null && git commit -q -m '~A' --author='~A <~A@vault>' 2>/dev/null || true"
                                           (namestring vault-root) note-name message author author))
                        :output nil :error nil)
    (make-version-record :hash hash :message message :timestamp ts :author author)))

(defun note-history (vault-root note-name)
  "Return list of version-records for a note (most recent first)."
  (declare (type pathname vault-root) (type string note-name))
  (declare (ignore vault-root note-name))
  ;; Stub: in production, parse `git log --format` output
  '())
