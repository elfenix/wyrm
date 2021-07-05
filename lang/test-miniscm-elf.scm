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
)
