;;; Runtime Manipulation and Management of ELF Binaries

; Magic bytes
(define rt-elf.MAGIC0 127)
(define rt-elf.MAGIC1 69)
(define rt-elf.MAGIC2 76)
(define rt-elf.MAGIC3 70)

;;; ---------------------------------------------------------------------------
;;; File Header / Magic
;;; ---------------------------------------------------------------------------

(define (rt-elf.u8 n) (%_wrt.and n 255))
(define (rt-elf.u16 n) `(,(rt-elf.u8 n) ,(rt-elf.u8 (%_wrt.shift n -8))))
(define (rt-elf.u32 n) (append (rt-elf.u16 n) (rt-elf.u16 (%_wrt.shift n -16))))
(define (rt-elf.u64 n) (append (rt-elf.u32 n) (rt-elf.u32 (%_wrt.shift n -32))))

(define rt-elf.elf64-half rt-elf.u16)
(define rt-elf.elf64-word rt-elf.u32)
(define rt-elf.elf64-addr rt-elf.u64)
(define rt-elf.elf64-off rt-elf.u64)

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

(define (rt-elf.header-ident class data version)
    (list 'rt-elf.header-ident class data version))

(define (rt-elf.header-ident? self)
    (eq? (car self) 'rt-elf.header-ident))

(define (rt-elf.header-ident-class self)
    (cadr self))

(define (rt-elf.header-ident-data self)
    (caddr self))

(define (rt-elf.header-ident-rev self)
    (car (cdddr self)))

(define (rt-elf.header-ident-encode self method)
    (method
        rt-elf.MAGIC0 rt-elf.MAGIC1 rt-elf.MAGIC2 rt-elf.MAGIC3
        (rt-elf.header-ident-class self)
        (rt-elf.header-ident-data self)
        (rt-elf.header-ident-rev self)  
        #x0 
        #x0 #x0 #x0 #x0 #x0 #x0 #x0 #x0))

(define rt-elf.HEADER_IDENT_AARCH64 (rt-elf.header-ident rt-elf.CLASS_64 rt-elf.DATA_LSB rt-elf.REV_CURRENT))
(define rt-elf.HEADER_IDENT_X86-64 (rt-elf.header-ident rt-elf.CLASS_64 rt-elf.DATA_LSB rt-elf.REV_CURRENT))

