;;; Test Elf File Creation Support

(wyrm.include "rt-elf.scm")


(define test-elf-x86-ident-header 
    (wyrm.blob 
        #x7f #x45 #x4c #x46 
        #x02 #x01 #x01 #x00
        #x00 #x00 #x00 #x00
        #x00 #x00 #x00 #x00))



(test-group "Mini-Scheme Elf Support"
    (test-assert "Create ident header" (rt-elf.header-ident? (rt-elf.header-ident rt-elf.CLASS_64 rt-elf.DATA_LSB rt-elf.REV_NONE)))
    (test-assert "AArch64 Header" (rt-elf.header-ident? rt-elf.HEADER_IDENT_AARCH64))
    (test-assert "Intel x86-64 Header" (rt-elf.header-ident? rt-elf.HEADER_IDENT_X86-64))
    (test-assert "Intel Header Encoded"
        (wyrm.blob-eq? 
            test-elf-x86-ident-header
            (rt-elf.header-ident-encode rt-elf.HEADER_IDENT_X86-64 wyrm.blob)
        ))
    
    (test-assert "Intel Byte Order U8 Encode"
        (wyrm.blob-eq?
            (wyrm.blob-flatten (rt-elf.u8 #x12))
            (wyrm.blob-flatten #x12)
        ))

    (test-assert "Intel Byte Order U16 Encode"
        (wyrm.blob-eq?
            (wyrm.blob-flatten (rt-elf.u16 #x1234))
            (wyrm.blob-flatten #x34 #x12)
        ))

    (test-assert "Intel Byte Order U32 Encode"
        (wyrm.blob-eq?
            (wyrm.blob-flatten (rt-elf.u32 #x12345678))
            (wyrm.blob-flatten #x78 #x56 #x34 #x12)
        ))

    (test-assert "Intel Byte Order U64 Encode"
        (wyrm.blob-eq?
            (wyrm.blob-flatten (rt-elf.u64 #x12345678aabbccdd))
            (wyrm.blob-flatten #xdd #xcc #xbb #xaa #x78 #x56 #x34 #x12)
        ))
)
