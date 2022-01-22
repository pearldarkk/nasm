%include 'func64.asm'

section .data
    isELF32             db  0
    sError              db  "Error occured!", 0
    sRequestFilename    db  "Enter link to ELF file: ", 0
    ; ELF Header
    sElfHeader          db  0xa, "ELF Header: ", 0xa, 0
    sMagic              db  "Magic: ", 0
    sClass              db  "Class: ", 0
    sData               db  "Data: ", 0
    sVersion            db  "Version: ", 0
    sOSABI              db  "OS/ABI: ", 0
    sABIVersion         db  "ABI Version: ", 0
    sType               db  "Type: ", 0
    sMachine            db  "Machine: ", 0
    sEntryPointAddress  db  "Entry Point Address: ", 0
    sStartProgram       db  "Start of Program Headers: ", 0
    sStartSection       db  "Start of Section Headers: ", 0
    sFlags              db  "Flags: ", 0
    sSizeProgram        db  "Size of Program Headers: ", 0
    sSizeSection        db  "Size of Section Headers: ", 0
    sNumberSection      db  "Number of Section Headers: ", 0
    sStringTableIndex   db  "Section Header String Table Index: ", 0

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
    mov     rdx, 26
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
    mov     rdi, [fd]
    mov     rsi, [filedata]
    mov     rdx, [filesize]
    mov     rax, 0
    syscall

    ; begin parsing file
    mov     rbx, [filedata]
    ;ELF_HEADER:
    mov     edi, dword [rbx]    ; e->ident[0..3]
    cmp     edi, 0x7f454c46     ; \x7fELF
    jnz     .errorExit

    ; magic 
    mov     r12, 0
    .printMagicBytes:
    movzx   edi, byte [rbx + r12]
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
