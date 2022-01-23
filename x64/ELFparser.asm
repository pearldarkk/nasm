%include 'func64.asm'

; LOCAL VARIABLES LIST
; dw -2: e_shnum
; dw -4: e_shentsize
; dw -6: e_shstrndx
; dw -8: e_ehsize
; dq -10h: e_shoff
; dq -20h: e_phoff
; dw -12: e_phnum
; dw -14: e_phentsize

section .data
    isELF32             db  0
    isLittle            db  0
    sError              db  "Error occured!", 0
    sRequestFilename    db  "Enter link to ELF file: ", 0
    ; ELF Header
    sElfHeader          db  0xa, "ELF Header: ", 0xa, 0
    sMagic              db  9, "Magic: ", 0
    sClass              db  9, "Class: ", 0
    sELF32              db  9, "ELF32", 0
    sELF64              db  9, "ELF64", 0
    sData               db  9, "Data: ", 0
    sLittleEndian       db  9, "little endian", 0
    sBigEndian          db  9, "big endian", 0
    sVersion            db  9, "Version: ", 0
    sOSABI              db  9, "OS/ABI: ", 0
    sABIVersion         db  9, "ABI Version: ", 0
    sType               db  9, "Type: ", 0
    sMachine            db  9, "Machine: ", 0
    sEntryPointAddress  db  9, "Entry Point Address: ", 0
    sStartProgram       db  9, "Start of Program Headers: ", 0
    sStartSection       db  9, "Start of Section Headers: ", 0
    sFlags              db  9, "Flags: ", 0
    sSizeHeader         db  9, "Size of this header: ", 0    
    sSizeProgram        db  9, "Size of Program Headers: ", 0
    sNumberProgram      db  9, "Number of Program Headers: ", 0
    sSizeSection        db  9, "Size of Section Headers: ", 0
    sNumberSection      db  9, "Number of Section Headers: ", 0
    sStringTableIndex   db  9, "Section Header String Table Index: ", 0
    ; Section Header
    sSectionHeader      db  0ah, "Section Header: ", 0ah, 0
    sSectionHeaderTable db  "Name", 9, 9, "Type", 9, "Address", 9, "Offset", 9, "Size", 9, "EntSize", 9, "Flags", 9, "Link", 9, "Info", 9, "Align", 0ah, 0
    ; Program Header
    sProgramHeader      db  0ah, "Program Header: ", 0ah, 0
    sProgramHeaderTable db  "Type", 9, "Offset", 9, "VirtAddr", 9, "PhysAddr", 9, "FileSiz", 9, "MemSiz", 9, "Flags", 9, "Align", 0ah, 0 

section .bss
    filename        resb    512
    filesize        resq    1
    filedata        resq    1      
    fd              resd    1    
    fd_stat         resb    144     ; sizeof struct stat = 144
    hexString       resb    17
section .text
global _start
_start:
    mov     rbp, rsp
    sub     rsp, 40h
    ; get filename
    mov     rdi, 1
    mov     rsi, sRequestFilename
    mov     rdx, 25
    mov     rax, 1
    syscall
    mov     rdi, 0
    mov     rsi, filename
    mov     rdx, 512
    mov     rax, 0
    syscall 

    ; open file
    mov     rdi, filename
    call    strlencalc
    mov     byte [filename + rax], 0        ; null-terminated
    mov     rdi, filename
    mov     rsi, 0          ; read_only flag
    mov     rdx, 0
    mov     rax, 2
    syscall                 ; open(filename, O_RDONLY)
    cmp     eax, -1         ; fd returned
    jz      .errorExit
    mov     [fd], eax
    ; get file size
    mov     rdi, [fd]
    mov     rsi, fd_stat
    mov     rax, 5
    syscall                 ; fstat(fd, (struct stat) fd_stat)
    mov     rsi, fd_stat
    mov     rsi, qword [rsi + 48]    ; -> st_size
    mov     [filesize], rsi
    ; allocate mem
    xor     rdi, rdi
    mov     rax, 12
    syscall
    mov     rdi, rax
    mov     [filedata], rdi
    add     rdi, [filesize]
    mov     rax, 12
    syscall
    ; read file to filedata string
    mov     edi, [fd]
    mov     rsi, [filedata]
    mov     rdx, [filesize]
    mov     rax, 0
    syscall

    ; begin parsing file
    mov     rbx, [filedata]
    ;ELF_HEADER:
    mov     edi, dword [rbx]    ; e->ident[0..3]
    cmp     edi, 0x464c457f     ; \x7fELF
    jnz     .errorExit
    mov     rdi, 1
    mov     rsi, sElfHeader
    mov     rdx, 14
    mov     rax, 1
    syscall
    ; magic 
    mov     rdi, 1
    mov     rsi, sMagic
    mov     rdx, 9
    mov     rax, 1
    syscall
    mov     r12, 0
    .printMagicBytes:
    movzx   edi, byte [rbx + r12]
    mov     rsi, hexString
    call    ltoh
    mov     rdi, 1
    mov     rsi, hexString
    mov     byte [hexString + rax], 20h
    inc     rax
    mov     rdx, rax
    mov     rax, 1
    syscall
    inc     r12
    cmp     r12, 0x10
    jnz     .printMagicBytes
    mov     rdi, 1
    mov     rsi, hexString
    mov     rax, 0
    call    println

    ; class
    mov     rdi, 1
    mov     rsi, sClass
    mov     rdx, 8
    mov     rax, 1
    syscall
    mov     dil, [rbx + 4]
    cmp     dil, 1
    jz      .markELF32
    mov     rdi, 1
    mov     rsi, sELF64
    mov     rdx, 6
    call    println
    jmp     .endClass
    .markELF32:
    mov     byte [isELF32], 1
    mov     rdi, 1
    mov     rsi, sELF32
    mov     rdx, 6
    call    println
    .endClass:

    ; data
    mov     rdi, 1
    mov     rsi, sData
    mov     rdx, 6
    mov     rax, 1
    syscall
    mov     dil, [rbx + 4]
    cmp     dil, 1
    jz      .markLittleEndian
    mov     rdi, 1
    mov     rsi, sBigEndian
    mov     rdx, 11
    call    println
    jmp     .endData
    .markLittleEndian:
    mov     byte [isLittle], 1
    mov     rdi, 1
    mov     rsi, sLittleEndian
    mov     rdx, 14
    call    println
    .endData:

    ; version
    mov     rdi, 1
    mov     rsi, sVersion
    mov     rdx, 10
    mov     rax, 1
    syscall
    mov     dil, byte [rbx + 5]
    mov     rsi, hexString
    call    ltoh
    mov     rdi, 1
    mov     rsi, hexString
    mov     byte [hexString + rax], 0xa
    inc     rax
    mov     rdx, rax
    mov     rax, 1
    syscall

    ; OSA/ABI
    mov     rdi, 1
    mov     rsi, sOSABI
    mov     rdx, 10
    mov     rax, 1
    syscall
    mov     dil, byte [rbx + 7]
    mov     rsi, hexString
    call    ltoh
    mov     rdi, 1
    mov     rsi, hexString
    mov     byte [hexString + rax], 0xa
    inc     rax
    mov     rdx, rax
    mov     rax, 1
    syscall

    ; ABI version
    mov     rdi, 1
    mov     rsi, sABIVersion
    mov     rdx, 14
    mov     rax, 1
    syscall
    mov     dil, byte [rbx + 8]
    mov     rsi, hexString
    call    ltoh
    mov     rdi, 1
    mov     rsi, hexString
    mov     byte [hexString + rax], 0xa
    inc     rax
    mov     rdx, rax
    mov     rax, 1
    syscall

    ; e_type
    mov     rdi, 1
    mov     rsi, sType
    mov     rdx, 7
    mov     rax, 1
    syscall
    mov     di, word [rbx + 10h]
    mov     rsi, hexString
    call    ltoh
    mov     rdi, 1
    mov     rsi, hexString
    mov     byte [hexString + rax], 0xa
    inc     rax
    mov     rdx, rax
    mov     rax, 1
    syscall

    ; e_machine
    mov     rdi, 1
    mov     rsi, sMachine
    mov     rdx, 10
    mov     rax, 1
    syscall
    mov     di, word [rbx + 12h]
    mov     rsi, hexString
    call    ltoh
    mov     rdi, 1
    mov     rsi, hexString
    mov     byte [hexString + rax], 0xa
    inc     rax
    mov     rdx, rax
    mov     rax, 1
    syscall

    ; e_version
    mov     rdi, 1
    mov     rsi, sVersion
    mov     rdx, 10
    mov     rax, 1
    syscall
    mov     edi, dword [rbx + 14h]
    mov     rsi, hexString
    call    ltoh
    mov     rdi, 1
    mov     rsi, hexString
    mov     byte [hexString + rax], 0xa
    inc     rax
    mov     rdx, rax
    mov     rax, 1
    syscall

    mov     r12, 18h
    ; e_entry
    mov     rdi, 1
    mov     rsi, sEntryPointAddress
    mov     rdx, 22
    mov     rax, 1
    syscall
    cmp     byte [isELF32], 1
    jnz     .entry64
    .entry32:
    mov     edi, dword [rbx + r12]
    jmp     .endEntry
    .entry64:
    mov     rdi, qword [rbx + r12]
    add     r12, 4
    .endEntry:
    mov     rsi, hexString
    call    ltoh
    mov     rdi, 1
    mov     rsi, hexString
    mov     byte [hexString + rax], 0xa
    inc     rax
    mov     rdx, rax
    mov     rax, 1
    syscall
    add     r12, 4

    ; e_phoff
    mov     rdi, 1
    mov     rsi, sStartProgram
    mov     rdx, 27
    mov     rax, 1
    syscall
    cmp     byte [isELF32], 1
    jnz     .phoff64
    .phoff32:
    mov     edi, dword [rbx + r12]
    jmp     .endPhoff
    .phoff64:
    mov     rdi, qword [rbx + r12]
    add     r12, 4
    .endPhoff:
    mov     [rbp - 20h], rdi
    mov     rsi, hexString
    call    ltoh
    mov     rdi, 1
    mov     rsi, hexString
    mov     byte [hexString + rax], 0xa
    inc     rax
    mov     rdx, rax
    mov     rax, 1
    syscall
    add     r12, 4

    ; e_shoff
    mov     rdi, 1
    mov     rsi, sStartSection
    mov     rdx, 27
    mov     rax, 1
    syscall
    cmp     byte [isELF32], 1
    jnz     .shoff64
    .shoff32:
    mov     edi, dword [rbx + r12]
    mov     [rbp - 10h], edi
    jmp     .endShoff
    .shoff64:
    mov     rdi, qword [rbx + r12]
    mov     [rbp - 10h], rdi
    add     r12, 4
    .endShoff:
    mov     rsi, hexString
    call    ltoh
    mov     rdi, 1
    mov     rsi, hexString
    mov     byte [hexString + rax], 0xa
    inc     rax
    mov     rdx, rax
    mov     rax, 1
    syscall
    add     r12, 4

    ; e_flags
    mov     rdi, 1
    mov     rsi, sFlags
    mov     rdx, 8
    mov     rax, 1
    syscall
    mov     edi, dword [rbx + r12]
    mov     rsi, hexString
    call    ltoh
    mov     rdi, 1
    mov     rsi, hexString
    mov     byte [hexString + rax], 0xa
    inc     rax
    mov     rdx, rax
    mov     rax, 1
    syscall
    add     r12, 4

    ; e_ehsize
    mov     rdi, 1
    mov     rsi, sSizeHeader
    mov     rdx, 22
    mov     rax, 1
    syscall
    mov     di, word [rbx + r12]
    mov     [rbp - 8], di
    mov     rsi, hexString
    call    ltoh
    mov     rdi, 1
    mov     rsi, hexString
    mov     byte [hexString + rax], 0xa
    inc     rax
    mov     rdx, rax
    mov     rax, 1
    syscall
    add     r12, 2

    ; e_phentsize
    mov     rdi, 1
    mov     rsi, sSizeProgram
    mov     rdx, 26
    mov     rax, 1
    syscall
    mov     di, word [rbx + r12]
    mov     [rbp - 14h], di
    mov     rsi, hexString
    call    ltoh
    mov     rdi, 1
    mov     rsi, hexString
    mov     byte [hexString + rax], 0xa
    inc     rax
    mov     rdx, rax
    mov     rax, 1
    syscall
    add     r12, 2

    ; e_phnum
    mov     rdi, 1
    mov     rsi, sNumberProgram
    mov     rdx, 28
    mov     rax, 1
    syscall
    mov     di, word [rbx + r12]
    mov     [rbp - 12h], di
    mov     rsi, hexString
    call    ltoh
    mov     rdi, 1
    mov     rsi, hexString
    mov     byte [hexString + rax], 0xa
    inc     rax
    mov     rdx, rax
    mov     rax, 1
    syscall
    add     r12, 2

    ; e_shentsize
    mov     rdi, 1
    mov     rsi, sSizeSection
    mov     rdx, 26
    mov     rax, 1
    syscall
    mov     di, word [rbx + r12]
    mov     [rbp - 4], di
    mov     rsi, hexString
    call    ltoh
    mov     rdi, 1
    mov     rsi, hexString
    mov     byte [hexString + rax], 0xa
    inc     rax
    mov     rdx, rax
    mov     rax, 1
    syscall
    add     r12, 2

    ; e_shnum
    mov     rdi, 1
    mov     rsi, sNumberSection
    mov     rdx, 28
    mov     rax, 1
    syscall
    mov     di, word [rbx + r12]
    mov     [rbp - 2], di
    mov     rsi, hexString
    call    ltoh
    mov     rdi, 1
    mov     rsi, hexString
    mov     byte [hexString + rax], 0xa
    inc     rax
    mov     rdx, rax
    mov     rax, 1
    syscall
    add     r12, 2

    ; e_shstrndx
    mov     rdi, 1
    mov     rsi, sStringTableIndex
    mov     rdx, 37
    mov     rax, 1
    syscall
    mov     di, word [rbx + r12]
    mov     [rbp - 6], di
    mov     rsi, hexString
    call    ltoh
    mov     rdi, 1
    mov     rsi, hexString
    mov     byte [hexString + rax], 0xa
    inc     rax
    mov     rdx, rax
    mov     rax, 1
    syscall
    add     r12, 2

    ; Section Header
    mov     rdi, 1
    mov     rsi, sSectionHeader
    mov     rdx, 18
    mov     rax, 1
    syscall
    mov     rdi, 1
    mov     rsi, sSectionHeaderTable
    mov     rdx, 0x3d
    mov     rax, 1
    syscall

    mov     r12w, 0
    add     bx, [rbp - 10h]    ; -> e_shoff
    mov     ax, [rbp - 4]
    mov     r13w, [rbp - 6]     ; e_shstrndx
    mul     r13w
    mov     r13, rax
    add     r13, rbx            ; r13 = &Section contains section names
    
    .nextSection:
    ; name
    cmp     r12w, [rbp - 2]     ; -> e_shnum
    jz      .endSectionHeader
    mov     edi, dword [rbx]          ; sh_name
    cmp     byte [isELF32], 1
    jz      .sh_name32
    .sh_name64: ; actually im taking e_shoffset but i named this to show that this all is to take the correct sh_name
    add     rdi, [r13 + 18h]    ; -> sh_offset    
    add     rdi, [filedata]     ; rdi = &sectionname   
    jmp     .endSh_name
    .sh_name32:
    add     edi, [r13 + 10h]     ; -> sh_offset
    add     rdi, [filedata]     ; rdi = &sectionname
    .endSh_name:
    mov     rsi, rdi
    call    strlencalc
    mov     rdi, 1
    mov     rdx, rax
    mov     r15, rax            ; save len to r15
    mov     rax, 1
    syscall
    ; format output for better look
    mov     rdi, 1
    mov     rsi, hexString
    mov     byte [rsi], 9
    mov     rax, 1
    mov     rdx, 1
    cmp     r15, 8
    jl      .moreTab
    jmp     .printTab
    .moreTab:
    mov     byte [rsi + rdx], 9
    inc     rdx
    .printTab:
    mov     rsi, hexString
    syscall

    ; type
    mov     edi, dword [rbx + 4]
    mov     rsi, hexString
    call    ltoh
    mov     rdi, 1
    mov     rsi, hexString
    mov     byte [hexString + rax], 09
    inc     rax
    mov     rdx, rax
    mov     rax, 1
    syscall
    
    mov     r14, 0ch
    ; sh_addr
    cmp     byte [isELF32], 1
    jz      .sh_addr32
    .sh_addr64:
    add     r14, 4    
    mov     rdi, [rbx + r14]
    add     r14, 4   
    jmp     .endSh_addr
    .sh_addr32:
    mov     edi, [rbx + r14]
    .endSh_addr:
    mov     rsi, hexString
    call    ltoh
    mov     rdi, 1
    mov     rsi, hexString
    mov     byte [hexString + rax], 9
    inc     rax
    mov     rdx, rax
    mov     rax, 1
    syscall
    add     r14, 4

    ; sh_offset
    cmp     byte [isELF32], 1
    jz      .sh_offset32
    .sh_offset64:
    mov     rdi, [rbx + r14]
    add     r14, 4   
    jmp     .endSh_offset
    .sh_offset32:
    mov     edi, [rbx + r14]
    .endSh_offset:
    mov     rsi, hexString
    call    ltoh
    mov     rdi, 1
    mov     rsi, hexString
    mov     byte [hexString + rax], 9
    inc     rax
    mov     rdx, rax
    mov     rax, 1
    syscall
    add     r14, 4

    ; sh_size
    cmp     byte [isELF32], 1
    jz      .sh_size32
    .sh_size64:
    mov     rdi, [rbx + r14]
    add     r14, 4   
    jmp     .endSh_size
    .sh_size32:
    mov     edi, [rbx + r14]
    .endSh_size:
    mov     rsi, hexString
    call    ltoh
    mov     rdi, 1
    mov     rsi, hexString
    mov     byte [hexString + rax], 9
    inc     rax
    mov     rdx, rax
    mov     rax, 1
    syscall
    add     r14, 4

    add     r14, 8
    ; sh_entsize
    cmp     byte [isELF32], 1
    jz      .sh_entsize32
    .sh_entsize64:
    add     r14, 8
    mov     rdi, [rbx + r14]
    sub     r14, 10h        ; -> sh_link
    jmp     .endSh_entsize
    .sh_entsize32:
    add     r14, 4
    mov     edi, [rbx + r14]
    sub     r14, 0ch        ; -> sh_link
    .endSh_entsize:
    mov     rsi, hexString
    call    ltoh
    mov     rdi, 1
    mov     rsi, hexString
    mov     byte [hexString + rax], 9
    inc     rax
    mov     rdx, rax
    mov     rax, 1
    syscall
    
    ; sh_flags
    cmp     byte [isELF32], 1
    jz      .sh_flag32
    .sh_flag64:
    mov     rdi, [rbx + 8]
    jmp     .endSh_flag
    .sh_flag32:
    mov     edi, [rbx + 8]
    .endSh_flag:
    mov     rsi, hexString
    call    ltoh
    mov     rdi, 1
    mov     rsi, hexString
    mov     byte [hexString + rax], 9
    inc     rax
    mov     rdx, rax
    mov     rax, 1
    syscall

    ; sh_link
    mov     edi, [rbx + r14]
    mov     rsi, hexString
    call    ltoh
    mov     rdi, 1
    mov     rsi, hexString
    mov     byte [hexString + rax], 9
    inc     rax
    mov     rdx, rax
    mov     rax, 1
    syscall
    add     r14, 4

    ; sh_info
    mov     edi, [rbx + r14]
    mov     rsi, hexString
    call    ltoh
    mov     rdi, 1
    mov     rsi, hexString
    mov     byte [hexString + rax], 9
    inc     rax
    mov     rdx, rax
    mov     rax, 1
    syscall
    add     r14, 4

    ; sh_addalign
    cmp     byte [isELF32], 1
    jz      .sh_addalign32
    .sh_addalign64:
    mov     rdi, [rbx + r14]
    jmp     .endSh_addalign
    .sh_addalign32:
    mov     edi, [rbx + r14]
    .endSh_addalign:
    mov     rsi, hexString
    call    ltoh
    mov     rdi, 1
    mov     rsi, hexString
    mov     byte [hexString + rax], 0ah
    inc     rax
    mov     rdx, rax
    mov     rax, 1
    syscall

    inc     r12w
    mov     di, [rbp - 4]
    add     rbx, rdi
    jmp     .nextSection
    .endSectionHeader:

    ; Program Header
    mov     rdi, 1
    mov     rsi, sProgramHeader
    mov     rdx, 18
    mov     rax, 1
    syscall
    mov     rdi, 1
    mov     rsi, sProgramHeaderTable
    mov     rdx, 0x3a
    mov     rax, 1
    syscall

    mov     rbx, [filedata]
    add     rbx, [rbp - 20h]    ; + e_phoff => &Program header
    mov     r12w, 0

    .nextEntry:
    cmp     r12w, [rbp - 12h]   ; e_phnum
    jz      .endProgramHeader

    mov     r14, 0
    ; p_type
    mov     edi, [rbx + r14]
    mov     rsi, hexString
    call    ltoh
    mov     rdi, 1
    mov     rsi, hexString
    mov     byte [hexString + rax], 9
    inc     rax
    mov     rdx, rax
    mov     rax, 1
    syscall
    add     r14, 4

    ; p_offset
    cmp     byte [isELF32], 1
    jz      .p_offset32
    .p_offset64:
    add     r14, 4
    mov     rdi, [rbx + r14]
    add     r14, 4
    jmp     .endp_offset
    .p_offset32:
    mov     edi, [rbx + r14]
    .endp_offset:
    mov     rsi, hexString
    call    ltoh
    mov     rdi, 1
    mov     rsi, hexString
    mov     byte [hexString + rax], 9
    inc     rax
    mov     rdx, rax
    mov     rax, 1
    syscall
    add     r14, 4

    ; p_vaddr
    cmp     byte [isELF32], 1
    jz      .p_vaddr32
    .p_vaddr64:
    mov     rdi, [rbx + r14]
    add     r14, 4
    jmp     .endp_vaddr
    .p_vaddr32:
    mov     edi, [rbx + r14]
    .endp_vaddr:
    mov     rsi, hexString
    call    ltoh
    mov     rdi, 1
    mov     rsi, hexString
    mov     byte [hexString + rax], 9
    inc     rax
    mov     byte [hexString + rax], 9
    inc     rax
    mov     rdx, rax
    mov     rax, 1
    syscall
    add     r14, 4

    ; p_paddr
    cmp     byte [isELF32], 1
    jz      .p_paddr32
    .p_paddr64:
    mov     rdi, [rbx + r14]
    add     r14, 4
    jmp     .endp_paddr
    .p_paddr32:
    mov     edi, [rbx + r14]
    .endp_paddr:
    mov     rsi, hexString
    call    ltoh
    mov     rdi, 1
    mov     rsi, hexString
    mov     byte [hexString + rax], 9
    inc     rax
    mov     byte [hexString + rax], 9
    inc     rax
    mov     rdx, rax
    mov     rax, 1
    syscall
    add     r14, 4

    ; p_filesz
    cmp     byte [isELF32], 1
    jz      .p_filesz32
    .p_filesz64:
    mov     rdi, [rbx + r14]
    add     r14, 4
    jmp     .endp_filesz
    .p_filesz32:
    mov     edi, [rbx + r14]
    .endp_filesz:
    mov     rsi, hexString
    call    ltoh
    mov     rdi, 1
    mov     rsi, hexString
    mov     byte [hexString + rax], 9
    inc     rax
    mov     rdx, rax
    mov     rax, 1
    syscall
    add     r14, 4

    ; p_memsz
    cmp     byte [isELF32], 1
    jz      .p_memsz32
    .p_memsz64:
    mov     rdi, [rbx + r14]
    jmp     .endp_memsz
    .p_memsz32:
    mov     edi, [rbx + r14]
    .endp_memsz:
    mov     rsi, hexString
    call    ltoh
    mov     rdi, 1
    mov     rsi, hexString
    mov     byte [hexString + rax], 9
    inc     rax
    mov     rdx, rax
    mov     rax, 1
    syscall
    add     r14, 8

    ; p_flags
    cmp     byte [isELF32], 1
    jz      .p_flags32
    .p_flags64:
    mov     edi, [rbx + 4]
    jmp     .endp_flags
    .p_flags32:
    mov     edi, [rbx + 18h]
    .endp_flags:
    mov     rsi, hexString
    call    ltoh
    mov     rdi, 1
    mov     rsi, hexString
    mov     byte [hexString + rax], 9
    inc     rax
    mov     rdx, rax
    mov     rax, 1
    syscall

    ; p_flags
    cmp     byte [isELF32], 1
    jz      .p_align32
    .p_align64:
    mov     edi, [rbx + r14]
    add     r14, 8
    jmp     .endp_align
    .p_align32:
    mov     edi, [rbx + r14]
    add     r14, 4
    .endp_align:
    mov     rsi, hexString
    call    ltoh
    mov     rdi, 1
    mov     rsi, hexString
    mov     byte [hexString + rax], 0ah
    inc     rax
    mov     rdx, rax
    mov     rax, 1
    syscall

    inc     r12w
    mov     r14w, [rbp - 14h]        ; e_phentsize
    add     rbx, r14
    jmp     .nextEntry

    .endProgramHeader:

    ; done parsing
    .finished:
    mov     rdi, [fd]
    mov     rax, 3
    syscall                 ; close(fd)
    mov     rdi, 0
    mov     rax, 60
    syscall
    ; pop up error message then exit with code -1
    .errorExit:
    mov     rdi, 1
    mov     rsi, sError 
    mov     rdx, 14
    mov     rax, 1
    syscall
    mov     rdi, -1
    mov     rax, 60
    syscall
    


