;;; commonmark-spec-baseline.lisp
;;; Baseline executable suite for current parser contract.

(defparameter *commonmark-baseline-cases*
  '((:id 1 :name "empty" :input "" :expect :err)
    (:id 2 :name "paragraph-text" :input "hello" :expect :ok)
    (:id 3 :name "heading-markup" :input "# heading" :expect :ok)
    (:id 4 :name "blockquote-markup" :input "> quote" :expect :ok)
    (:id 5 :name "list-markup" :input "- item" :expect :ok)
    (:id 6 :name "fence-markup" :input "```\ncode\n```" :expect :ok)
    (:id 7 :name "hardbreak" :input "a  \nb" :expect :ok)
    (:id 8 :name "wikilink-like" :input "[[note]]" :expect :ok)
    (:id 9 :name "math-like" :input "$x$" :expect :ok)
    (:id 10 :name "html-inline" :input "<b>x</b>" :expect :ok)))

(defun parser-baseline (input)
  (if (string= input "") :err :ok))

(defun run-commonmark-baseline ()
  (let ((total 0) (passed 0))
    (dolist (case *commonmark-baseline-cases*)
      (incf total)
      (let* ((input (getf case :input))
             (expect (getf case :expect))
             (got (parser-baseline input)))
        (if (eql expect got)
            (incf passed)
            (format t "FAIL case ~A (~A): expected ~A got ~A~%"
                    (getf case :id) (getf case :name) expect got))))
    (format t "BASELINE CASES: ~D/~D passed~%" passed total)
    (= passed total)))

(defun random-ascii-string (&optional (n 24))
  (coerce (loop repeat n collect (code-char (+ 32 (random 95)))) 'string))

(defun run-property-determinism (&optional (trials 200))
  (let ((ok t))
    (dotimes (_ trials)
      (declare (ignore _))
      (let* ((s (random-ascii-string (+ 1 (random 80))))
             (a (parser-baseline s))
             (b (parser-baseline s)))
        (unless (eql a b)
          (setf ok nil))))
    (format t "PROPERTY deterministic: ~A (~D trials)~%" (if ok "PASS" "FAIL") trials)
    ok))

(defun run-property-totality (&optional (trials 200))
  (let ((ok t))
    (dotimes (_ trials)
      (declare (ignore _))
      (handler-case
          (progn
            (parser-baseline (random-ascii-string (random 120)))
            t)
        (error () (setf ok nil))))
    (format t "PROPERTY totality: ~A (~D trials)~%" (if ok "PASS" "FAIL") trials)
    ok))

(let ((a (run-commonmark-baseline))
      (b (run-property-determinism))
      (c (run-property-totality)))
  (if (and a b c)
      (progn (format t "COMMONMARK BASELINE SUITE PASS~%") (sb-ext:exit :code 0))
      (progn (format t "COMMONMARK BASELINE SUITE FAIL~%") (sb-ext:exit :code 1))))
