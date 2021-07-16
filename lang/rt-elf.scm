;;; Runtime Manipulation and Management of ELF Binaries

; Magic bytes
(define rt-elf.MAGIC0 127)
(define rt-elf.MAGIC1 69)
(define rt-elf.MAGIC2 76)
(define rt-elf.MAGIC3 70)

;;; ---------------------------------------------------------------------------
;;; File Header / Magic
;;; ---------------------------------------------------------------------------


(define rt-elf.elf64-half wyrm.encode-u16)
(define rt-elf.elf64-word wyrm.encode-u32)
(define rt-elf.elf64-xword wyrm.encode-u64)
(define rt-elf.elf64-addr wyrm.encode-u64)
(define rt-elf.elf64-off wyrm.encode-u64)

; Object file classes, elf-header-ident class
(define rt-elf.CLASS_NONE   0)
(define rt-elf.CLASS_32     1)
(define rt-elf.CLASS_64     2)

; Data encoding, elf-header-ident data
(define rt-elf.DATA_LSB     1)
(define rt-elf.DATA_MSB     2)

; Version, elf-header-ident version
(define rt-elf.REV_NONE     0)
(define rt-elf.REV_CURRENT  1)

; Type elf-header type
(define rt-elf.TYPE_NONE 0)
(define rt-elf.TYPE_REL 1)
(define rt-elf.TYPE_EXEC 2)
(define rt-elf.TYPE_DYN 3)
(define rt-elf.TYPE_CORE 4)

; Machine Types
(define rt-elf.MACHINE_X86_64 #x3e)
(define rt-elf.MACHINE_AARCH64 #xb7)

(define (rt-elf.header-ident class data version)
    (list 'rt-elf.header-ident class data version))

(define (rt-elf.header-ident? self)
    (and (pair? self)
         (eq? (car self) 'rt-elf.header-ident)
         (eq? (length self) 4)))

(define (rt-elf.header-ident-class self)
    (cadr self))

(define (rt-elf.header-ident-data self)
    (caddr self))

(define (rt-elf.header-ident-rev self)
    (car (cdddr self)))

(define (rt-elf.header-ident-encode self)
  (if (rt-elf.header-ident? self)
      (wyrm.blob
          rt-elf.MAGIC0 rt-elf.MAGIC1 rt-elf.MAGIC2 rt-elf.MAGIC3
          (rt-elf.header-ident-class self)
          (rt-elf.header-ident-data self)
          (rt-elf.header-ident-rev self)
          #x0
          #x0 #x0 #x0 #x0 #x0 #x0 #x0 #x0)
      (wyrm.abort "rt-elf.header-ident-encode expected header-ident instance")))

(define rt-elf.HEADER_IDENT_AARCH64 (rt-elf.header-ident rt-elf.CLASS_64 rt-elf.DATA_LSB rt-elf.REV_CURRENT))
(define rt-elf.HEADER_IDENT_X86-64 (rt-elf.header-ident rt-elf.CLASS_64 rt-elf.DATA_LSB rt-elf.REV_CURRENT))


;;; Define encoding method for the 64-bit elf file header
(define rt-elf.elf-header-default
  `((_type . rt-elf.elf-header)
    (ident . #f)
    (type . #f)
    (machine . #f)
    (version . #f)
    (entry_point . #f)
    (program_header_offset . #f)
    (section_header_offset . #f)
    (flags . #f)
    (elf_header_size . #f)
    (program_header_entry_size . #f)
    (program_header_entry_count . #f)
    (section_header_entry_size . #f)
    (section_header_entry_count . #f)
    (string_table_index . 0)))

(define rt-elf.elf-header64-encoding
  `((,rt-elf.header-ident-encode . ident)
    (,rt-elf.elf64-half . type)
    (,rt-elf.elf64-half . machine)
    (,rt-elf.elf64-word . version)
    (,rt-elf.elf64-addr . entry_point)
    (,rt-elf.elf64-off . program_header_offset)
    (,rt-elf.elf64-off . section_header_offset)
    (,rt-elf.elf64-word . flags)
    (,rt-elf.elf64-half . elf_header_size)
    (,rt-elf.elf64-half . program_header_entry_size)
    (,rt-elf.elf64-half . program_header_entry_count)
    (,rt-elf.elf64-half . section_header_entry_size)
    (,rt-elf.elf64-half . section_header_entry_count)
    (,rt-elf.elf64-half . string_table_index)))

(define (rt-elf.elf-header-new . T)
  (wyrm.dict-update (apply wyrm.dict-new rt-elf.elf-header-default) T))

(define (rt-elf.elf-header? self)
  (eq? (wyrm.dict-get self '_type) 'rt-elf.elf-header))


;;; ---------------------------------------------------------------------------
;;; Elf String Table
;;; ---------------------------------------------------------------------------

(define (rt-elf.str-table n) (cons 'rt-elf.str-table n))
(define (rt-elf.str-table? n) (eq? (car n) 'rt-elf.str-table))
(define (rt-elf.str-table-length n) (length (cdr n)))
(define (rt-elf.str-table-item n k) (list-ref (cdr n) k))
(define (%rt-elf.str-table-str_sz n) (+ (string-length n) 1))
(define (%rt-elf.str-table-item_offset n k)
    (let ((prev_k (- k 1)))
        (if (zero? k)
            0
            (+ (%rt-elf.str-table-str_sz (rt-elf.str-table-item n prev_k))
               (%rt-elf.str-table-item_offset n prev_k)))))
(define (rt-elf.str-table-sz n) (%rt-elf.str-table-item_offset n (rt-elf.str-table-length n)))

(define (%rt-elf.str-table-encode-part ll)
  (if (pair? ll)
      (wyrm.blob-flatten (string->wyrm.blob (car ll))
                         #x00
                         (%rt-elf.str-table-encode-part (cdr ll)))
      (wyrm.blob)))

(define (rt-elf.str-table-encode self)
  (if (rt-elf.str-table? self)
      (%rt-elf.str-table-encode-part (cdr self))
      (wyrm.abort "rt-elf.str-table-encode expected str-table")))

;;; ---------------------------------------------------------------------------
;;; Elf Section Header
;;; ---------------------------------------------------------------------------

;;; Define encoding method for the 64-bit elf section header
(define rt-elf.section-default
  `((_type . rt-elf.elf-section)
    (name_idx . #f)                 ; Index of name in section table
    (type . #f)                     ; Section type
    (flags . #f)                    ; Section attributes
    (addr . #f)                     ; Virtual base address
    (offset . #f)                   ; Offset in file
    (size . #f)                     ; Size of the section
    (link . #f)                     ; Link to other section (specific to type)
    (info . #f)                     ; Information (specific to type)
    (align . #f)                    ; Alignment
    (entsize . #f)                  ; Entity size (if section has table)
   ))

(define rt-elf.section64-encoding
  `((,rt-elf.elf64-word . name_idx)
    (,rt-elf.elf64-word . type)
    (,rt-elf.elf64-xword . flags)
    (,rt-elf.elf64-addr . addr)
    (,rt-elf.elf64-off . offset)
    (,rt-elf.elf64-xword . size)
    (,rt-elf.elf64-word . link)
    (,rt-elf.elf64-word . info)
    (,rt-elf.elf64-xword . align)
    (,rt-elf.elf64-xword . entsize)
   ))


(define rt-elf.SHT_NULL 0)          ; Unused section
(define rt-elf.SHT_PROGBITS 1)      ; Defined by program
(define rt-elf.SHT_SYMTAB 2)        ; Symbol table
(define rt-elf.SHT_STRTAB 3)        ; String table
(define rt-elf.SHT_RELA 4)          ; "Rela" relocation entries
(define rt-elf.SHT_HASH 5)          ; Hash table
(define rt-elf.SHT_DYNAMIC 6)       ; Dynaminc link entries
(define rt-elf.SHT_NOTE 7)          ; Note information
(define rt-elf.SHT_NOBITS 8)        ; Uninitialize space
(define rt-elf.SHT_REL 9)           ; "REL" relocation entries
(define rt-elf.SHT_SHLIB 10)        ; Reserved
(define rt-elf.SHT_DYNSYM 11)       ; Dynamic loader entries

(define rt-elf.SHF_WRITE #x01)      ; Writeable data
(define rt-elf.SHF_ALLOC #x02)      ; Allocate memory
(define rt-elf.SHF_EXEC  #x04)      ; Executable instructions

(define (rt-elf.section-new . T)
  (wyrm.dict-update (apply wyrm.dict-new rt-elf.section-default) T))

(define (rt-elf.section? self)
  (eq? (wyrm.dict-get self '_type) 'rt-elf.elf-section))

;;; ---------------------------------------------------------------------------
;;; Elf Program Header
;;; ---------------------------------------------------------------------------

(define rt-elf.PT_NULL 0)         ; Unused entry
(define rt-elf.PT_LOAD 1)         ; Loadable segment
(define rt-elf.PT_DYNAMIC 2)      ; Dynamic linker table
(define rt-elf.PT_INTERP 3)       ; Program interpreter
(define rt-elf.PT_NOTE 4)         ; Note section
(define rt-elf.PT_SHLIB 5)        ; Reserved(?)
(define rt-elf.PT_PHDR 6)         ; Program header table

(define rt-elf.PF_X 1)            ; Execute permission
(define rt-elf.PF_W 2)            ; Writeable
(define rt-elf.PF_R 4)            ; Readable

;;; Define encoding method for the 64-bit elf section header
(define rt-elf.program-header-default
  `((_type . rt-elf.elf-program-header)
    (type . #f)                     ; Segment type
    (flags . #f)                    ; Segment attributes
    (offset . #f)                   ; Offset in file
    (vaddr . #f)                    ; Virtual base address
    (paddr . #f)                    ; Physical base address
    (file_size . #f)                ; Size of segment data in file
    (mem_size . #f)                 ; Size of segment in memory
    (align . #f)                    ; Alignment
   ))

(define rt-elf.program-header64-encoding
  `((,rt-elf.elf64-word . type)
    (,rt-elf.elf64-word . flags)
    (,rt-elf.elf64-off . offset)
    (,rt-elf.elf64-addr . vaddr)
    (,rt-elf.elf64-addr . paddr)
    (,rt-elf.elf64-xword . file_size)
    (,rt-elf.elf64-xword . mem_size)
    (,rt-elf.elf64-xword . align)
   ))

(define (rt-elf.program-header-new . T)
  (wyrm.dict-update (apply wyrm.dict-new rt-elf.program-header-default) T))

(define (rt-elf.program-header? self)
  (eq? (wyrm.dict-get self '_type) 'rt-elf.elf-program-header))

