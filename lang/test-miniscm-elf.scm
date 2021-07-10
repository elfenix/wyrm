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
            (rt-elf.header-ident-encode rt-elf.HEADER_IDENT_X86-64)
        ))

    (test-assert "Half Encode Method"
        (wyrm.blob-eq?
            (rt-elf.elf64-half #x1234)
            (wyrm.blob-flatten #x34 #x12)
        ))

    (test-assert "Word Encode Method"
        (wyrm.blob-eq?
            (rt-elf.elf64-word #x12345678)
            (wyrm.blob-flatten #x78 #x56 #x34 #x12)
        ))

    (test-assert "Addr Encode Method"
        (wyrm.blob-eq?
            (rt-elf.elf64-addr #x12345678aabbccdd)
            (wyrm.blob-flatten #xdd #xcc #xbb #xaa #x78 #x56 #x34 #x12)
        ))

    (test-assert "Offset Encode Method"
        (wyrm.blob-eq?
            (rt-elf.elf64-off #x12345678aabbccdd)
            (wyrm.blob-flatten #xdd #xcc #xbb #xaa #x78 #x56 #x34 #x12)
        ))
)


;;; Sample elf header sourced from GCC compilation of hello world program
(define demo-elf-header
    (rt-elf.elf-header-new
        `(ident . ,rt-elf.HEADER_IDENT_X86-64)
        `(type . ,rt-elf.TYPE_DYN)
        `(machine . ,rt-elf.MACHINE_X86_64)
        `(version . ,rt-elf.REV_CURRENT)
        `(entry_point . #x10e0)
        `(program_header_offset . 64)
        `(section_header_offset . 15464)
        `(flags . 0)
        `(elf_header_size . 64)
        `(program_header_entry_size . 56)
        `(program_header_entry_count . 13)
        `(section_header_entry_size . 64)
        `(section_header_entry_count . 31)
        `(string_table_index . 30)))

(define demo-elf-header-encoded (wyrm.blob
    #x7f #x45 #x4c #x46 #x02 #x01 #x01 #x00
    #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00
    #x03 #x00 #x3e #x00 #x01 #x00 #x00 #x00
    #xe0 #x10 #x00 #x00 #x00 #x00 #x00 #x00
    #x40 #x00 #x00 #x00 #x00 #x00 #x00 #x00
    #x68 #x3c #x00 #x00 #x00 #x00 #x00 #x00
    #x00 #x00 #x00 #x00 #x40 #x00 #x38 #x00
    #x0d #x00 #x40 #x00 #x1f #x00 #x1e #x00))

(test-group "elf file header"
    (test-assert "Create Default Elf Header"
        (rt-elf.elf-header? demo-elf-header))
    (test-assert "Regenerate Elf header from GCC binary and readelf dump"
        (wyrm.blob-eq?
            (wyrm.encode-dict demo-elf-header rt-elf.elf-header64-encoding)
            demo-elf-header-encoded))
)
