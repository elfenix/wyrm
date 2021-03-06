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


; String Table Tests
; ------------------
(define demo-str-table (rt-elf.str-table
    '("ELF"
      "File"
      "Format"
      "Is"
      "Awesome")))

(define demo-str-table2 (rt-elf.str-table
    '("1234"
      "6789")))

(define demo-str-table3-encoded (wyrm.blob
                   #x00 #x2e #x73 #x68 #x73
    #x74 #x72 #x74 #x61 #x62 #x00 #x2e #x6e
    #x6f #x74 #x65 #x2e #x67 #x6e #x75 #x2e
    #x62 #x75 #x69 #x6c #x64 #x2d #x69 #x64
    #x00 #x2e #x74 #x65 #x78 #x74 #x00 #x2e
    #x72 #x6f #x64 #x61 #x74 #x61 #x00
))

(define demo-str-table3 (rt-elf.str-table
   '(""
     ".shstrtab"
     ".note.gnu.build-id"
     ".text"
     ".rodata")))

;;; String Table
(test-group "elf string table"
    (test-assert "Create new string table"
        (rt-elf.str-table? (rt-elf.str-table '())))
    (test "Length of string table"
        5 (rt-elf.str-table-length demo-str-table))
    (test "Size of string table memory"
        10 (rt-elf.str-table-sz demo-str-table2))
    (test "Grab Element 0"
        "ELF" (rt-elf.str-table-item demo-str-table 0))
    (test "Grab Element 1"
        "6789" (rt-elf.str-table-item demo-str-table2 1))
    (test-assert "Encoded String Table"
        (wyrm.blob-eq?
            demo-str-table3-encoded
            (rt-elf.str-table-encode demo-str-table3)
        ))
)

;; Section Header Tests
;; --------------------

(define demo-text-section-encoded (wyrm.blob
    #x1e #x00 #x00 #x00 #x01 #x00 #x00 #x00
    #x06 #x00 #x00 #x00 #x00 #x00 #x00 #x00
    #x00 #x10 #x40 #x00 #x00 #x00 #x00 #x00
    #x00 #x10 #x00 #x00 #x00 #x00 #x00 #x00
    #x27 #x00 #x00 #x00 #x00 #x00 #x00 #x00
    #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00
    #x10 #x00 #x00 #x00 #x00 #x00 #x00 #x00
    #x00 #x00 #x00 #x00 #x00 #x00 #x00 #x00))

(define demo-text-section
    (rt-elf.section-new
        `(name_idx . #x0000001e)
        `(type . ,rt-elf.SHT_PROGBITS)
        `(flags . ,(+ rt-elf.SHF_ALLOC rt-elf.SHF_EXEC))
        `(addr . #x0000000000401000)
        `(offset . #x00001000)
        `(size . #x0000000000000027)
        `(entsize . #x0)
        `(link . #x0)
        `(info . #x0)
        `(align . 16)
))


(test-group "elf section header"
    (test-assert "Create new section header"
        (rt-elf.section? (rt-elf.section-new)))
    (test-assert "Blob matches recorded header"
        (wyrm.blob-eq?
            (wyrm.encode-dict demo-text-section rt-elf.section64-encoding)
            demo-text-section-encoded))
)


;; Program Header Tests
;; --------------------

(define demo-exec-program-encoded (wyrm.blob
    #x01 #x00 #x00 #x00 #x05 #x00 #x00 #x00
    #x00 #x10 #x00 #x00 #x00 #x00 #x00 #x00
    #x00 #x10 #x40 #x00 #x00 #x00 #x00 #x00
    #x00 #x10 #x40 #x00 #x00 #x00 #x00 #x00
    #x27 #x00 #x00 #x00 #x00 #x00 #x00 #x00
    #x27 #x00 #x00 #x00 #x00 #x00 #x00 #x00
    #x00 #x10 #x00 #x00 #x00 #x00 #x00 #x00))

(define demo-exec-program
    (rt-elf.program-header-new
        `(type . ,rt-elf.PT_LOAD)
        `(offset . #x0000000000001000)
        `(vaddr . #x0000000000401000)
        `(paddr . #x0000000000401000)
        `(file_size . #x0000000000000027)
        `(mem_size . #x0000000000000027)
        `(flags . ,(+ rt-elf.PF_X rt-elf.PF_R))
        `(align . #x1000)
))

(test-group "elf section header"
    (test-assert "Create new program header"
        (rt-elf.program-header? (rt-elf.program-header-new)))
    (test-assert "Encode matches elf sample"
        (wyrm.blob-eq?
            (wyrm.encode-dict demo-exec-program rt-elf.program-header64-encoding)
            demo-exec-program-encoded
         ))
)

;; Segment Data Tests
;; --------------------

(define demo-exec-text-bin (wyrm.blob
  #xb8 #x01 #x00 #x00 #x00              ; mov    $0x1,%eax
  #xbf #x01 #x00 #x00 #x00              ; mov    $0x1,%edi
  #x48 #xbe #x00 #x20 #x40 #x00 #x00    ; movabs $0x402000,%rsi
  #x00 #x00 #x00
  #xba #x0b #x00 #x00 #x00              ; mov    $0xb,%edx
  #x0f #x05                             ; syscall
  #xb8 #x3c #x00 #x00 #x00              ; mov    $0x3c,%eax
  #xbf #x00 #x00 #x00 #x00              ; mov    $0x0,%edi
  #x0f #x05                             ; syscall
))

(define demo-exec-text-segment (rt-elf.segment-data-new demo-exec-text-bin))

(test-group "elf segment data"
    (test-assert "Create Alignment 1024"
        (rt-elf.align? (rt-elf.align 1024)))
    (test-assert "Create new segment data"
        (rt-elf.segment-data? (rt-elf.segment-data-new)))
    (test-assert "Identity encode"
        (wyrm.blob-eq?
            demo-exec-text-bin
            (rt-elf.segment-encode demo-exec-text-segment #x1000)
        ))
    (test-assert "4 byte alignment"
        (wyrm.blob-eq?
            (wyrm.blob-flatten #x1 #x0 #x0 #x0)
            (rt-elf.segment-encode (rt-elf.segment-data-new
                (wyrm.blob-flatten #x1)
                (rt-elf.align 4))
              #x0)
        ))
    (test-error "Invalid segment data"
        (rt-elf.segment-encode (rt-elf.segment-data-new 'junk)))
)
