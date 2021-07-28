(wyrm.include "rt-elf.scm")


(define elf-header-hello-world
    (rt-elf.elf-header-new
        `(ident . ,rt-elf.HEADER_IDENT_X86-64)
        `(type . ,rt-elf.TYPE_EXEC)
        `(machine . ,rt-elf.MACHINE_X86_64)
        `(version . ,rt-elf.REV_CURRENT)
        `(entry_point . #x401000)
        `(program_header_offset . #x40)
        `(section_header_offset . #x2038)
        `(flags . 0)
        `(elf_header_size . 64)
        `(program_header_entry_size . 56)
        `(program_header_entry_count . 4)
        `(section_header_entry_size . 64)
        `(section_header_entry_count . 5)
        `(string_table_index . 4)))


; Program Headers:
;  Type           Offset             VirtAddr           PhysAddr
;                 FileSiz            MemSiz              Flags  Align
;  LOAD           0x0000000000000000 0x0000000000400000 0x0000000000400000
;                 0x0000000000000144 0x0000000000000144  R      0x1000
;  LOAD           0x0000000000001000 0x0000000000401000 0x0000000000401000
;                 0x0000000000000027 0x0000000000000027  R E    0x1000
;  LOAD           0x0000000000002000 0x0000000000402000 0x0000000000402000
;                 0x000000000000000b 0x000000000000000b  R      0x1000
;  NOTE           0x0000000000000120 0x0000000000400120 0x0000000000400120
;                 0x0000000000000024 0x0000000000000024  R      0x4

(define ph-headers
    (rt-elf.program-header-new
        `(type . ,rt-elf.PT_LOAD)
        `(offset . #x0)
        `(vaddr . #x400000)
        `(paddr . #x400000)
        `(file_size . #x144)
        `(mem_size . #x144)
        `(flags . ,rt-elf.PF_R)
        `(align . #x1000)
))

(define ph-text
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

(define ph-rodata
    (rt-elf.program-header-new
        `(type . ,rt-elf.PT_LOAD)
        `(offset . #x2000)
        `(vaddr . #x402000)
        `(paddr . #x402000)
        `(file_size . #xb)
        `(mem_size . #xb)
        `(flags . ,rt-elf.PF_R)
        `(align . #x1000)
))

(define ph-node
    (rt-elf.program-header-new
        `(type . ,rt-elf.PT_NOTE)
        `(offset . #x120)
        `(vaddr . #x400120)
        `(paddr . #x400120)
        `(file_size . #x24)
        `(mem_size . #x24)
        `(flags . ,rt-elf.PF_R)
        `(align . #x4)
))


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


;; Note Data
(define note-data (wyrm.blob
    #x04 #x00 #x00 #x00 #x14 #x00 #x00 #x00
    #x03 #x00 #x00 #x00 #x47 #x4e #x55 #x00
    #x6c #x4b #x78 #xe4 #x31 #xf8 #x3d #x64
    #xaf #xe8 #xf6 #x22 #x12 #x73 #xdf #xf0
    #x71 #x41 #xa3 #xe0
))


;; Text Data
(define text-data (wyrm.blob
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

;; RoData
(define ro-data (string->wyrm.blob "Hello World"))

;; String Table
(define strtable (rt-elf.str-table
   '(""
     ".shstrtab"
     ".note.gnu.build-id"
     ".text"
     ".rodata")))


;  [ 0]                   NULL             0000000000000000  00000000
;       0000000000000000  0000000000000000           0     0     0
(define sh-null
    (rt-elf.section-new
        `(name_idx . #x0)
        `(type . ,rt-elf.SHT_NULL)
        `(flags . #x0)
        `(addr . #x0)
        `(offset . #x0)
        `(size . #x0)
        `(entsize . #x0)
        `(link . #x0)
        `(info . #x0)
        `(align . #x0)
))


;  [ 1] .note.gnu.build-i NOTE             0000000000400120  00000120
;       0000000000000024  0000000000000000   A       0     0     4
(define sh-note-id
    (rt-elf.section-new
        `(name_idx . #x0b)
        `(type . ,rt-elf.SHT_NOTE)
        `(flags . ,rt-elf.SHF_ALLOC)
        `(addr . #x400120)
        `(offset . #x120)
        `(size . #x24)
        `(entsize . #x0)
        `(link . #x0)
        `(info . #x0)
        `(align . #x4)
))

;  [ 2] .text             PROGBITS         0000000000401000  00001000
;       0000000000000027  0000000000000000  AX       0     0     16
(define sh-text
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

;  [ 3] .rodata           PROGBITS         0000000000402000  00002000
;       000000000000000b  0000000000000000   A       0     0     4
(define sh-rodata
    (rt-elf.section-new
        `(name_idx . #x00000024)
        `(type . ,rt-elf.SHT_PROGBITS)
        `(flags . ,rt-elf.SHF_ALLOC)
        `(addr . #x0000000000402000)
        `(offset . #x00002000)
        `(size . #xb)
        `(entsize . #x0)
        `(link . #x0)
        `(info . #x0)
        `(align . 4)
))


;  [ 4] .shstrtab         STRTAB           0000000000000000  0000200b
;       000000000000002c  0000000000000000           0     0     1
(define sh-strtab
    (rt-elf.section-new
        `(name_idx . #x01)
        `(type . ,rt-elf.SHT_STRTAB)
        `(flags . 0)
        `(addr . #x0)
        `(offset . #x0000200b)
        `(size . #x2c)
        `(entsize . #x0)
        `(link . #x0)
        `(info . #x0)
        `(align . 1)
))




(define hello-world-elf
    (rt-elf.segment-data-new
        (wyrm.encode-dict elf-header-hello-world rt-elf.elf-header64-encoding)

        (wyrm.encode-dict ph-headers rt-elf.program-header64-encoding)
        (wyrm.encode-dict ph-text rt-elf.program-header64-encoding)
        (wyrm.encode-dict ph-rodata rt-elf.program-header64-encoding)
        (wyrm.encode-dict ph-node rt-elf.program-header64-encoding)

        note-data
        (rt-elf.align #x1000)

        text-data
        (rt-elf.align #x1000)

        ro-data

        (rt-elf.str-table-encode strtable)

        (rt-elf.align #x4)
        (wyrm.encode-dict sh-null rt-elf.section64-encoding)
        (wyrm.encode-dict sh-note-id rt-elf.section64-encoding)
        (wyrm.encode-dict sh-text rt-elf.section64-encoding)
        (wyrm.encode-dict sh-rodata rt-elf.section64-encoding)
        (wyrm.encode-dict sh-strtab rt-elf.section64-encoding)
))


(wyrm.write-binary "test.hello-world.x86" (rt-elf.segment-encode hello-world-elf #x0))
