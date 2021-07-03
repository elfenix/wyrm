;;; Chicken Scheme Bootstrap

(import (chicken blob))
(import (chicken io))
(import (srfi-4))

(define wyrm.runtime 'csi)


;;; Blob API
;;;     wyrm.blob
;;;         -new sz: Build blob with sz in bytes
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

(define (string->wyrm.blob str)
    (define thiz_blob (string->blob str))
    (define thiz_u8 (blob->u8vector/shared thiz_blob))
    (_wyrm.blob-make thiz_blob thiz_u8))

(define (wyrm.blob->string self)
    (blob->string (_wyrm.blob-blob self)))

(define (wyrm.blob-pokeb! self offset value)
    (u8vector-set! (_wyrm.blob-u8 self) offset value))

(define (wyrm.blob-peekb self offset)
    (u8vector-ref (_wyrm.blob-u8 self) offset))

(define (wyrm.blob-size self)
    (blob-size (_wyrm.blob-blob self)))

(define-syntax wyrm.include
    (syntax-rules ()
        ((_ impl_file)
            (load-relative impl_file))))


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




