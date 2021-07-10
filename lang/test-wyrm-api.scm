;;; Verify Wyrm API

; Some constants
(define ascii-A 65)

; Basic Operators
(test-group "Bitwise Operators"
    (test "Bitwise And" #x8 (%_wrt.and #xff #x0f #x08))
    (test "Filtered Not" #xf0 (%_wrt.and #xf0 (%_wrt.not #x0f)))
    (test "Shift Left" #x02 (%_wrt.shift #x1 1))
    (test "Shift Right" #x01 (%_wrt.shift #x2 -1))
)

; MiniScheme Elf API
(test-group "Dictionary API"
    (test-assert "Create new dictionary" (wyrm.dict? (wyrm.dict-new '((my-key #f)))))
    (test-assert "Create empty dictionary" (wyrm.dict? (wyrm.dict-new)))
    (test "Get dictionary item" 42 (wyrm.dict-get (wyrm.dict-new '(my-key . 42)) 'my-key))
    (test "Get set dict item" 42 (wyrm.dict-get (wyrm.dict-set (wyrm.dict-new) 'my-key 42) 'my-key))
    (test "Get reset dict item" 43 (wyrm.dict-get (wyrm.dict-set (wyrm.dict-new '(my-key 42)) 'my-key 43) 'my-key))
    (test "Dictionary update single" 42 (wyrm.dict-get (wyrm.dict-update (wyrm.dict-new) '((my-key . 42))) 'my-key))
    (test "Dictionary update first" 42 (wyrm.dict-get (wyrm.dict-update (wyrm.dict-new) '((my-key . 42) (my-key2 . 43))) 'my-key))
    (test "Dictionary update second" 43 (wyrm.dict-get (wyrm.dict-update (wyrm.dict-new) '((my-key . 42) (my-key2 . 43))) 'my-key2))
)

; Blob API Test
(test-group "Blob API"
    (test-error "Throwing Exception" (wyrm.abort "Forced Error"))

    (test-error "Invalid Component Type" (%wyrm.blob-component-sz 'UseQuotedSymbolAsNoSize))
    (test "Single Char Component Size" 1 (%wyrm.blob-component-sz #x22))
    (test-error "Invalid List Component Size" (%wyrm.blob-component-list-sz 'NotAList))
    (test "Component List Size 1" 1 (%wyrm.blob-component-list-sz '(1)))
    (test "Component List Size 2" 2 (%wyrm.blob-component-list-sz '(1 2)))
    (test "Component Size List" 2 (%wyrm.blob-component-sz '(1 1)))
    (test "Component Size Blob" 16 (%wyrm.blob-component-sz (wyrm.blob-new 16)))
    (test "Component Size Str" 2 (%wyrm.blob-component-sz "AA"))
    (test "Component Size Recursed Blob" 16 (%wyrm.blob-component-sz (list (wyrm.blob-new 16))))

    (test "Create Flattened Blob Size" 16 (wyrm.blob-size (wyrm.blob-flatten (wyrm.blob-new 8) (wyrm.blob-new 8))))

    (test "Copy in Single Char" 1 (%wyrm.blob-component-in! (wyrm.blob-new 1) ascii-A 0))
    (test "Copy in String" 1 (%wyrm.blob-component-in! (wyrm.blob-new 1) "A" 0))
    (test "Copy in Blob" 2 (%wyrm.blob-component-in! (wyrm.blob-new 2) (string->wyrm.blob "AA") 0))
    (test "Copy in Blob Partial" 1 (%wyrm.blob-component-in! (wyrm.blob-new 1) (string->wyrm.blob "AA") 0))
    (test "Copy in Blob Empty" 0 (%wyrm.blob-component-in! (wyrm.blob-new 1) (string->wyrm.blob "") 0))
    (test-error "Flatten bad input" (%wyrm.blob-flatten-in! (wyrm.blob-new 1) 'NotAList 0))
    (test "Copy in Single Char Recurse" 1 (%wyrm.blob-flatten-in! (wyrm.blob-new 1) (list ascii-A) 0))
    (test "Copy in Blob Recurse" 16 (%wyrm.blob-flatten-in! (wyrm.blob-new 16) (list (wyrm.blob-new 8) (wyrm.blob-new 8)) 0))
    (test "Copy in Single Char Recurse^2" 1 (%wyrm.blob-flatten-in! (wyrm.blob-new 1) (list (list ascii-A)) 0))

    (test "Blob Flatten Simple" "A" (wyrm.blob->string (wyrm.blob-flatten ascii-A)))
    (test "Blob Flatten Simple x2" "AA" (wyrm.blob->string (wyrm.blob-flatten ascii-A ascii-A)))
    (test "Blob Flatten Simple x2" "AA" (wyrm.blob->string (wyrm.blob-flatten ascii-A ascii-A)))
    (test "Blob Flatten Hello World" "A Hello A World"
        (wyrm.blob->string (wyrm.blob-flatten ascii-A " Hello " (list ascii-A (list " ") (string->wyrm.blob "World")))))

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




(define test-encode-dict0 (wyrm.dict-new '(a . 42)))
(define test-encode-dict0-encoding '())

(define test-encode-dict1 (wyrm.dict-new '(a . 42)))
(define test-encode-dict1-encoding `((,wyrm.encode-u8 . a)))

(define test-encode-dict2 (wyrm.dict-new '(a . 42) '(b . #xff)))
(define test-encode-dict2-encoding `((u8 . a)
                                     (u16 . b)))


(define test-encode-dict3 (wyrm.dict-new `(sub . ,test-encode-dict1)))
(define test-encode-dict3-encoding `(((substruct . ,test-encode-dict1-encoding) . sub)))

(test-group "Mini-Scheme Binary Encoding"
    (test-assert "Intel Byte Order U8 Encode"
        (wyrm.blob-eq?
            (wyrm.blob-flatten (wyrm.u8 #x12))
            (wyrm.blob-flatten #x12)
        ))

    (test-assert "Intel Byte Order U16 Encode"
        (wyrm.blob-eq?
            (wyrm.blob-flatten (wyrm.u16 #x1234))
            (wyrm.blob-flatten #x34 #x12)
        ))

    (test-assert "Intel Byte Order U32 Encode"
        (wyrm.blob-eq?
            (wyrm.blob-flatten (wyrm.u32 #x12345678))
            (wyrm.blob-flatten #x78 #x56 #x34 #x12)
        ))

    (test-assert "Intel Byte Order U64 Encode"
        (wyrm.blob-eq?
            (wyrm.blob-flatten (wyrm.u64 #x12345678aabbccdd))
            (wyrm.blob-flatten #xdd #xcc #xbb #xaa #x78 #x56 #x34 #x12)
        ))

    (test-assert "U8 Encode Method"
        (wyrm.blob-eq?
            (wyrm.encode-u8 #x12)
            (wyrm.blob-flatten #x12)
        ))

    (test-assert "U16 Encode Method"
        (wyrm.blob-eq?
            (wyrm.encode-u16 #x1234)
            (wyrm.blob-flatten #x34 #x12)
        ))

    (test-assert "U32 Encode Method"
        (wyrm.blob-eq?
            (wyrm.encode-u32 #x12345678)
            (wyrm.blob-flatten #x78 #x56 #x34 #x12)
        ))

    (test-assert "U64 Encode Method"
        (wyrm.blob-eq?
            (wyrm.encode-u64 #x12345678aabbccdd)
            (wyrm.blob-flatten #xdd #xcc #xbb #xaa #x78 #x56 #x34 #x12)
        ))

   (test-assert "Dictionary Encode Empty"
        (wyrm.blob-eq?
            (wyrm.encode-dict test-encode-dict0 test-encode-dict0-encoding)
            (wyrm.blob-flatten)))

    (test-assert "LE Dictionary Encode"
        (wyrm.blob-eq?
            (wyrm.encode-dict test-encode-dict1 test-encode-dict1-encoding)
            (wyrm.blob-flatten 42)))

    (test-assert "LE Dictionary Encode Multi-Type"
        (wyrm.blob-eq?
            (wyrm.encode-dict test-encode-dict2 test-encode-dict2-encoding)
            (wyrm.blob-flatten 42 #xff 0)))

    (test-assert "LE Dictionary Encode Subs"
        (wyrm.blob-eq?
            (wyrm.encode-dict test-encode-dict3 test-encode-dict3-encoding)
            (wyrm.blob-flatten 42)))

    (test-assert "Dict0 is encoding" (wyrm.encode-field-set? test-encode-dict0-encoding))
    (test-assert "Dict1 is encoding" (wyrm.encode-field-set? test-encode-dict1-encoding))
    (test-assert "Dict2 is encoding" (wyrm.encode-field-set? test-encode-dict2-encoding))
    (test-assert "Dict3 is encoding" (wyrm.encode-field-set? test-encode-dict3-encoding))

    (test "Dictionary Size Empty" 0 (wyrm.encode-dict-size test-encode-dict0 test-encode-dict0-encoding))
    (test "Dictionary Size Single" 1 (wyrm.encode-dict-size test-encode-dict1 test-encode-dict1-encoding))
    (test "Dictionary Size Multi" 3 (wyrm.encode-dict-size test-encode-dict2 test-encode-dict2-encoding))
)
