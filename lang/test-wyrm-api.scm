;;; Verify Wyrm API

; Some constants
(define ascii-A 65)

; Blob API Test
(test-group "Blob API"
    (test-assert "Internal blob create works" (_wyrm.blob? (_wyrm.blob-make #f #f)))
    (test-assert "Public API blob create" (wyrm.blob? (wyrm.blob-new 32)))
    (test "Blob size matches" 32 (wyrm.blob-size (wyrm.blob-new 32)))
    (test-assert "Compare Blob =" (eq? (wyrm.blob-cmp (string->wyrm.blob "A") (string->wyrm.blob "A")) 0))
    (test-assert "Compare Blob < [0]" (< (wyrm.blob-cmp (string->wyrm.blob "A") (string->wyrm.blob "B")) 0))
    (test-assert "Compare Blob > [0]" (> (wyrm.blob-cmp (string->wyrm.blob "B") (string->wyrm.blob "A")) 0))
    (test-assert "Compare Blob > [0*]" (> (wyrm.blob-cmp (string->wyrm.blob "B") (string->wyrm.blob "")) 0))
    (test-assert "Compare Blob < [0*]" (< (wyrm.blob-cmp (string->wyrm.blob "") (string->wyrm.blob "B")) 0))
    (test-assert "Compare Blob < [1]" (< (wyrm.blob-cmp (string->wyrm.blob "AA") (string->wyrm.blob "AB")) 0))
    (test-assert "Compare Blob < [1 extra]" (< (wyrm.blob-cmp (string->wyrm.blob "AA") (string->wyrm.blob "ABA")) 0))
    (test-assert "Compare Blob < [1 no recurse]" (< (wyrm.blob-cmp (string->wyrm.blob "AAC") (string->wyrm.blob "ABA")) 0))
    (test-assert "Compare Blob < [1 no recurse]" (> (wyrm.blob-cmp (string->wyrm.blob "ACA") (string->wyrm.blob "ABC")) 0))
    (test-assert "Compare Blob > [1 extra]" (> (wyrm.blob-cmp (string->wyrm.blob "ABA") (string->wyrm.blob "AA")) 0))
    (test-assert "Compare Blob Offset =" (eq? (wyrm.blob-cmp (string->wyrm.blob "BA") (string->wyrm.blob "CA") 1) 0))
    (test-assert "Blob[AA] = Blob[AA]" (wyrm.blob-eq? (string->wyrm.blob "AA") (string->wyrm.blob "AA")))
    (test-assert "not Blob[AA] = Blob[AB]" (not (wyrm.blob-eq? (string->wyrm.blob "AA") (string->wyrm.blob "AB"))))
    (test-assert "Compare Single Char <" (< (%wyrm.blob-cmp-char (string->wyrm.blob "A") (string->wyrm.blob "B") 0) 0))
    (test-assert "Compare Single Char >" (> (%wyrm.blob-cmp-char (string->wyrm.blob "B") (string->wyrm.blob "A") 0) 0))
    (test-assert "Compare Single Char =" (eq? (%wyrm.blob-cmp-char (string->wyrm.blob "B") (string->wyrm.blob "B") 0) 0))
    (test-assert "Compare Single Char < (Empty)" (< (%wyrm.blob-cmp-char (string->wyrm.blob "") (string->wyrm.blob "B") 0) 0))
    (test-assert "Compare Single Char < (Empty)" (> (%wyrm.blob-cmp-char (string->wyrm.blob "B") (string->wyrm.blob "") 0) 0))
    (test-assert "Compare Single Char = (Empty)" (eq? (%wyrm.blob-cmp-char (string->wyrm.blob "") (string->wyrm.blob "") 0) 0))
    (test "Convert string to blob" ascii-A (wyrm.blob-peekb (string->wyrm.blob "A") 0))
    (test "Convert blob to string" "Hello" (wyrm.blob->string (string->wyrm.blob "Hello")))
    (test "Read/Write blob to file" "Hello World"
        (begin
            (wyrm.write-binary test-blob-file (string->wyrm.blob "Hello World"))
            (wyrm.blob->string (wyrm.read-binary test-blob-file))
        ))
    (test "Copy in" "Hello"
        (begin
            (define buf (string->wyrm.blob "H3l1o"))
            (wyrm.blob-copy-in! buf 0 (string->wyrm.blob "Hell"))
            (wyrm.blob->string buf)
        ))
    (test "Append Values" "Hello World"
        (wyrm.blob->string (wyrm.blob-append (string->wyrm.blob "Hello ")
                                             (string->wyrm.blob "World")))
        )
    (test-assert "Get/Set Byte at Offsets"
        (let ((test_vec (wyrm.blob-new 4)))
            (begin
                (wyrm.blob-pokeb! test_vec 0 #xff)
                (wyrm.blob-pokeb! test_vec 1 #x00)
                (and (eq? (wyrm.blob-peekb test_vec 0) #xff)
                     (eq? (wyrm.blob-peekb test_vec 1) #x00))
            )))
    (test "Set Empty" 0 (wyrm.blob-set-list! (wyrm.blob-new 1) 0 '()))
    (test "Set Single" 1 (wyrm.blob-set-list! (wyrm.blob-new 1) 0 (list ascii-A)))
    (test "Set Chars" "HAAlo" 
        (begin
            (define buf (string->wyrm.blob "Hello"))
            (wyrm.blob-set-list! buf 1 (list ascii-A ascii-A))
            (wyrm.blob->string buf)    
        ))
    (test "Construct List" "AAA" 
        (wyrm.blob->string (wyrm.blob ascii-A ascii-A ascii-A)))
)
