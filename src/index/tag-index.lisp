;;; tag-index.lisp --- tag index for notes

(defpackage #:clpkg-markdown-notes/tags
  (:use #:cl)
  (:export
   #:tag-index #:tag-index-p #:make-tag-index
   #:ti-entries
   #:register-tags! #:get-notes-by-tag #:all-tags))

(in-package #:clpkg-markdown-notes/tags)

(defstruct (tag-index
             (:constructor make-tag-index (&key (entries nil)))
             (:conc-name ti-))
  (entries '() :type list)) ; alist: (tag . (note-path ...))

(declaim (ftype (function (tag-index string list) (values tag-index &optional)) register-tags!)
         (ftype (function (tag-index string) (values list &optional)) get-notes-by-tag)
         (ftype (function (tag-index) (values list &optional)) all-tags))

(defun register-tags! (index note-path tags)
  (declare (type tag-index index) (type string note-path) (type list tags))
  (dolist (tag tags)
    (let ((entry (assoc tag (ti-entries index) :test #'string=)))
      (if entry
          (pushnew note-path (cdr entry) :test #'string=)
          (push (cons tag (list note-path)) (ti-entries index)))))
  index)

(defun get-notes-by-tag (index tag)
  (declare (type tag-index index) (type string tag))
  (cdr (assoc tag (ti-entries index) :test #'string=)))

(defun all-tags (index)
  (declare (type tag-index index))
  (mapcar #'car (ti-entries index)))
