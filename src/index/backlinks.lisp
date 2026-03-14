;;; backlinks.lisp --- backlink index for wikilinks

(defpackage #:clpkg-markdown-notes/backlinks
  (:use #:cl)
  (:export
   #:backlink-index #:backlink-index-p #:make-backlink-index
   #:bi-forward #:bi-backward
   #:register-links! #:get-backlinks #:get-forward-links #:find-orphans))

(in-package #:clpkg-markdown-notes/backlinks)

(defstruct (backlink-index
             (:constructor make-backlink-index (&key (forward nil) (backward nil)))
             (:conc-name bi-))
  (forward '() :type list)   ; alist: (source . (target ...))
  (backward '() :type list)) ; alist: (target . (source ...))

(declaim (ftype (function (backlink-index string list) (values backlink-index &optional)) register-links!)
         (ftype (function (backlink-index string) (values list &optional)) get-backlinks)
         (ftype (function (backlink-index string) (values list &optional)) get-forward-links)
         (ftype (function (backlink-index list) (values list &optional)) find-orphans))

(defun register-links! (index source targets)
  (declare (type backlink-index index) (type string source) (type list targets))
  ;; Update forward map
  (let ((existing (assoc source (bi-forward index) :test #'string=)))
    (if existing
        (setf (cdr existing) targets)
        (push (cons source targets) (bi-forward index))))
  ;; Update backward map
  (dolist (target targets)
    (let ((entry (assoc target (bi-backward index) :test #'string=)))
      (if entry
          (pushnew source (cdr entry) :test #'string=)
          (push (cons target (list source)) (bi-backward index)))))
  index)

(defun get-backlinks (index target)
  (declare (type backlink-index index) (type string target))
  (cdr (assoc target (bi-backward index) :test #'string=)))

(defun get-forward-links (index source)
  (declare (type backlink-index index) (type string source))
  (cdr (assoc source (bi-forward index) :test #'string=)))

(defun find-orphans (index all-notes)
  "Return notes that have no backlinks and no forward links."
  (declare (type backlink-index index) (type list all-notes))
  (remove-if (lambda (note)
               (or (get-backlinks index note)
                   (get-forward-links index note)))
             all-notes))
