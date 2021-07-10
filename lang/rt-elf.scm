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

