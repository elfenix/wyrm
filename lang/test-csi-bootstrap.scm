
(import test)
(import (chicken file))
(import (chicken load))

(load-relative "csi-bootstrap.scm")


;; Setup test environment
(define test-dir-name "csi-bootstrap-test-data")
(define test-blob-file (string-append test-dir-name "/blob-action.u8"))

; Some constants
(define ascii-A 65)

(create-directory test-dir-name)
(delete-file* test-blob-file)




(test-group "Framework Verifications"
    (test-assert "Identify Chicken Scheme" (eq? wyrm.runtime 'csi))
)

(test-group "Blob API"
    (test-assert "Internal blob create works" (_wyrm.blob? (_wyrm.blob-make #f #f)))
    (test-assert "Public API blob create" (wyrm.blob? (wyrm.blob-new 32)))
    (test "Blob size matches" 32 (wyrm.blob-size (wyrm.blob-new 32)))
    (test "Convert string to blob" ascii-A (wyrm.blob-peekb (string->wyrm.blob "A") 0))
    (test "Convert blob to string" "Hello" (wyrm.blob->string (string->wyrm.blob "Hello")))
    (test "Read/Write blob to file" "Hello World"
        (begin
            (wyrm.write-binary test-blob-file (string->wyrm.blob "Hello World"))
            (wyrm.blob->string (wyrm.read-binary test-blob-file))
        ))
    (test-assert "Get/Set Byte at Offsets"
        (let ((test_vec (wyrm.blob-new 4)))
            (begin
                (wyrm.blob-pokeb! test_vec 0 #xff)
                (wyrm.blob-pokeb! test_vec 1 #x00)
                (and (eq? (wyrm.blob-peekb test_vec 0) #xff)
                     (eq? (wyrm.blob-peekb test_vec 1) #x00))
            )))
)


(test-exit)
