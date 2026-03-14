;;; encryption.lisp --- AES-256-GCM per-note encryption

(defpackage #:clpkg-markdown-notes/encryption
  (:use #:cl)
  (:export
   #:encryption-key #:encryption-key-p #:make-encryption-key
   #:ek-id #:ek-algorithm #:ek-created-at
   #:encrypted-note #:encrypted-note-p #:make-encrypted-note
   #:en-note-name #:en-ciphertext #:en-nonce #:en-key-id #:en-tag
   #:generate-key-metadata
   #:encrypt-note-content
   #:decrypt-note-content
   #:encryption-error))

(in-package #:clpkg-markdown-notes/encryption)

;;; ─── Conditions ───

(define-condition encryption-error (error)
  ((reason :initarg :reason :reader encryption-error-reason))
  (:report (lambda (c s) (format s "Encryption error: ~A" (encryption-error-reason c)))))

;;; ─── Key metadata ───

(defstruct (encryption-key
             (:constructor make-encryption-key (&key id algorithm created-at))
             (:conc-name ek-))
  (id "" :type string)
  (algorithm "AES-256-GCM" :type string)
  (created-at 0 :type integer))

;;; ─── Encrypted note ───

(defstruct (encrypted-note
             (:constructor make-encrypted-note (&key note-name ciphertext nonce key-id tag))
             (:conc-name en-))
  (note-name "" :type string)
  (ciphertext #() :type (simple-array (unsigned-byte 8) (*)))
  (nonce #() :type (simple-array (unsigned-byte 8) (*)))
  (key-id "" :type string)
  (tag #() :type (simple-array (unsigned-byte 8) (*))))

;;; ─── Operations ───

(declaim (ftype (function () (values encryption-key &optional)) generate-key-metadata)
         (ftype (function (encryption-key string string)
                          (values encrypted-note &optional))
                encrypt-note-content)
         (ftype (function (encryption-key encrypted-note)
                          (values string &optional))
                decrypt-note-content))

(defun generate-key-metadata ()
  "Generate key metadata (actual key material would use ironclad)."
  (make-encryption-key
   :id (format nil "key-~36R" (logand (sxhash (get-universal-time)) #xFFFFFFFF))
   :algorithm "AES-256-GCM"
   :created-at (get-universal-time)))

(defun encrypt-note-content (key note-name plaintext)
  "Encrypt note content. Stub: returns plaintext bytes as ciphertext placeholder."
  (declare (type encryption-key key) (type string note-name plaintext))
  (let ((bytes (map '(simple-array (unsigned-byte 8) (*))
                    #'char-code plaintext))
        (nonce (make-array 12 :element-type '(unsigned-byte 8) :initial-element 0))
        (tag (make-array 16 :element-type '(unsigned-byte 8) :initial-element 0)))
    (make-encrypted-note
     :note-name note-name
     :ciphertext bytes
     :nonce nonce
     :key-id (ek-id key)
     :tag tag)))

(defun decrypt-note-content (key encrypted)
  "Decrypt note content. Stub: returns ciphertext bytes as string."
  (declare (type encryption-key key) (type encrypted-note encrypted))
  (declare (ignore key))
  (map 'string #'code-char (en-ciphertext encrypted)))
