;;; Runtime Manipulation and Management of ELF Binaries

; Magic bytes
(define rt-elf.MAGIC0 127)
(define rt-elf.MAGIC1 69)
(define rt-elf.MAGIC2 76)
(define rt-elf.MAGIC3 70)

;;; ---------------------------------------------------------------------------
;;; File Header / Magic
;;; ---------------------------------------------------------------------------

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

