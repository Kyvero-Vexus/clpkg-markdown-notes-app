;;; template.lisp --- template instantiation with {{variable}} substitution

(defpackage #:clpkg-markdown-notes/template
  (:use #:cl)
  (:export
   #:template-record #:template-record-p #:make-template-record
   #:tmpl-name #:tmpl-content #:tmpl-variables
   #:instantiate-template
   #:extract-variables))

(in-package #:clpkg-markdown-notes/template)

(defstruct (template-record
             (:constructor make-template-record (&key name content variables))
             (:conc-name tmpl-))
  (name "" :type string)
  (content "" :type string)
  (variables '() :type list))

(declaim (ftype (function (string) (values list &optional)) extract-variables)
         (ftype (function (template-record list) (values string &optional)) instantiate-template))

(defun extract-variables (content)
  "Extract {{var}} placeholders from template content."
  (declare (type string content))
  (let ((vars '())
        (pos 0))
    (loop
      (let ((start (search "{{" content :start2 pos :test #'char=)))
        (unless start (return))
        (let ((end (search "}}" content :start2 (+ start 2) :test #'char=)))
          (unless end (return))
          (let ((var (subseq content (+ start 2) end)))
            (pushnew var vars :test #'string=))
          (setf pos (+ end 2)))))
    (nreverse vars)))

(defun instantiate-template (template bindings)
  "Instantiate a template with variable bindings (alist of (var . value))."
  (declare (type template-record template) (type list bindings))
  (let ((result (tmpl-content template)))
    (dolist (binding bindings)
      (let ((placeholder (format nil "{{~A}}" (car binding)))
            (value (cdr binding)))
        (setf result (%replace-all result placeholder value))))
    result))

(defun %replace-all (string old new)
  (declare (type string string old new))
  (let ((pos (search old string :test #'char=)))
    (if pos
        (concatenate 'string
                     (subseq string 0 pos)
                     new
                     (%replace-all (subseq string (+ pos (length old))) old new))
        string)))
