;;; Chicken Scheme Bootstrap

(import (chicken blob))
(import (chicken io))
(import (chicken condition))
(import (chicken bitwise))
(import (srfi-4))
(import (srfi-1))

;;; Portabe language primitives
(define wyrm.runtime 'csi)

(define-syntax wyrm.include
    (syntax-rules ()
        ((_ impl_file)
            (load-relative impl_file))))

(define (wyrm.abort obj)
    (abort obj))

;;; Dictionary API
;;;     wyrm.dict
;;;       - -new . Key Values: Construct new dictionary
;;;       - ?: Determine if item is dictionary
;;;       - -get key (default): Get key value or return default
;;;       - -set key value: Return new dictionary with key set to value
(define (wyrm.dict-new . key_values)
  `(wyrm.dict . ,key_values))

(define (wyrm.dict? self)
  (eq? (car self) 'wyrm.dict))

(define (wyrm.dict-get self key #!optional (default #f))
  (let ((key_pair (assoc key (cdr self))))
    (if key_pair
        (cdr key_pair)
        default)))

(define (wyrm.dict-set self key value)
  `(wyrm.dict . ,(cons `(,key . ,value) (cdr self))))

;;; Blob API
;;;     wyrm.blob
;;;         -new sz: Build blob with sz in bytes
;;;         -append self other: Create new blob by appending other to self
;;;         -cmp self other: Compare set to other using C integer comparison idiom
;;;         -copy-in! self offset other: Copy all bytes from other to self starting at offset
;;;         -eq? self other: True if blob is equivalent ot other
;;;         -pokeb! self offset value: Set byte at offset to value
;;;         -peekb self offset: Get byte at offset
;;;         -size self: Get size of the blob
(define-record-type _wyrm.blob
    (_wyrm.blob-make blob u8)
    _wyrm.blob?
    (blob _wyrm.blob-blob)
    (u8 _wyrm.blob-u8))

(define (wyrm.blob-new sz)
    (define thiz_blob (make-blob sz))
    (define thiz_u8 (blob->u8vector/shared thiz_blob))
    (_wyrm.blob-make thiz_blob thiz_u8))

(define (wyrm.blob . T)
    (begin
        (define thiz_blob (wyrm.blob-new (length T)))
        (wyrm.blob-set-list! thiz_blob 0 T)
        thiz_blob))

(define (%wyrm.blob-component-sz comp)
    (cond
        ((wyrm.blob? comp) (wyrm.blob-size comp))
        ((list? comp) (%wyrm.blob-component-list-sz comp))
        ((string? comp) (string-length comp))
        ((integer? comp) 1)
        (#t (wyrm.abort "Unknown Component Type"))))

(define (%wyrm.blob-component-list-sz ll)
    (if (pair? ll)
        (+ (%wyrm.blob-component-sz (car ll)) (%wyrm.blob-component-list-sz (cdr ll)))
        (if (list? ll)
            0
            (wyrm.abort "Unexpected Type in Component list Size"))))

(define (wyrm.blob-flatten . T)
    (define blob-sz (%wyrm.blob-component-list-sz T))
    (define thiz_blob (wyrm.blob-new blob-sz))
    (%wyrm.blob-flatten-in! thiz_blob T 0)
    thiz_blob)

(define (%wyrm.blob-component-in! self component offset)
    (cond
        ((wyrm.blob? component) (wyrm.blob-copy-in! self offset component))
        ((list? component) (%wyrm.blob-flatten-in! self component offset))
        ((string? component) (%wyrm.blob-component-in! self (string->wyrm.blob component) offset))
        ((integer? component) (begin
            (wyrm.blob-pokeb! self offset component)
            1))
        (#t (wyrm.abort "Unexpected Type in Component In"))
    ))

(define (%wyrm.blob-flatten-in! self ll offset)
    (if (pair? ll)
        (let ((this_size (%wyrm.blob-component-in! self (car ll) offset)))
            (+ this_size (%wyrm.blob-flatten-in! self (cdr ll) (+ offset this_size))))
        (if (list? ll)
            0
            (wyrm.abort "Unexpected Type in Blob Input Flatten"))))

(define (wyrm.blob-copy-in! self offset other #!optional (start 0) (count 0))
    (if (and (< start (wyrm.blob-size other)) (< offset (wyrm.blob-size self)))
        (begin
            (wyrm.blob-pokeb! self offset (wyrm.blob-peekb other start))
            (wyrm.blob-copy-in! self (+ offset 1) other (+ start 1) (+ count 1)))
        count
    ))

(define (wyrm.blob-append self other)
    (define total_size (+ (wyrm.blob-size self) (wyrm.blob-size other)))
    (define rblob (wyrm.blob-new total_size))
    (begin
        (wyrm.blob-copy-in! rblob 0 self)
        (wyrm.blob-copy-in! rblob (wyrm.blob-size self) other)
        rblob
    ))

(define (string->wyrm.blob str)
    (define thiz_blob (string->blob str))
    (define thiz_u8 (blob->u8vector/shared thiz_blob))
    (_wyrm.blob-make thiz_blob thiz_u8))

(define (%wyrm.blob-cmp-char first second offset)
    (cond 
        ((and (< offset (wyrm.blob-size first)) (< offset (wyrm.blob-size second)))
            (- (wyrm.blob-peekb first offset) (wyrm.blob-peekb second offset)))
        ((< offset (wyrm.blob-size first))
            1)
        ((< offset (wyrm.blob-size second))
            -1)
        (#t 0)))

(define (wyrm.blob-cmp first second #!optional (start 0))
    (if (or (< start (wyrm.blob-size first)) (< start (wyrm.blob-size second)))
        (let ((thiz_char (%wyrm.blob-cmp-char first second start)))
            (if (eq? thiz_char 0)
                (wyrm.blob-cmp first second (+ start 1))
                thiz_char))
        0))

(define (wyrm.blob-eq? first second)
    (eq? (wyrm.blob-cmp first second) 0))

(define (wyrm.blob->string self)
    (blob->string (_wyrm.blob-blob self)))

(define (wyrm.blob-pokeb! self offset value)
    (u8vector-set! (_wyrm.blob-u8 self) offset value))

(define (wyrm.blob-peekb self offset)
    (u8vector-ref (_wyrm.blob-u8 self) offset))

(define (wyrm.blob-size self)
    (blob-size (_wyrm.blob-blob self)))

(define (wyrm.blob-set-list! self offset ll)
   (if (pair? ll)
        (begin
            (u8vector-set! (_wyrm.blob-u8 self) offset (car ll))
            (+ 1 (wyrm.blob-set-list! self (+ offset 1) (cdr ll))))
        0))

(define wyrm.blob? _wyrm.blob?)


;;; Simple File IO
;;;     Read and Write raw binary files.

(define (wyrm.write-binary filename blob)
    (begin
        (define binfile (open-output-file filename #:binary))
        (write-u8vector (_wyrm.blob-u8 blob) binfile)
        (close-output-port binfile)
        #t
    ))

(define (wyrm.read-binary filename)
    (begin
        (define binfile (open-input-file filename #:binary))
        (define bincontents (read-string #f binfile))
        (close-input-port binfile)
        (string->wyrm.blob bincontents)
    ))


;;; ---------------------------------------------------------------------------
;;; Runtime Functions
;;; ---------------------------------------------------------------------------

(define %_wrt.and bitwise-and)
(define %_wrt.not bitwise-not)
(define %_wrt.shift arithmetic-shift)

