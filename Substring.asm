%include        'func64.asm'
section .bss
    string      resb    105
    substr      resb    11
    arr         resb    100
    size        resd    1
    
section .data
    strReq      db  's = ', 0
    substrReq   db  'c = ', 0
    
section .text
global _start:
_start:
    mov     rbp, rsp
    sub     rsp, 0x10
    ; get user input for str
    mov     rdi, 1
    mov     rsi, strReq
    mov     rdx, 4
    mov     rax, 1
    syscall
    mov     rdi, 0
    mov     rsi, string
    mov     rdx, 100
    mov     rax, 0
    syscall
    
    ; get user input for str
    mov     rdi, 1
    mov     rsi, substrReq
    mov     rdx, 4
    mov     rax, 1
    syscall
    mov     rdi, 0
    mov     rsi, substr
    mov     rdx, 10
    mov     rax, 0
    syscall
    
    ; start counting...
    mov     rax, arr
    mov     [rbp - 8], rax
    xor     eax, eax

    .iter:
    mov     rdi, substr
    mov     rsi, string
    movzx   rdx, ax
    call    pos
    mov     rdi, [rbp - 8]
    cmp     eax, -1
    jz      .finish
    stosb                      
    mov     [rbp - 8], rdi
    inc     eax           
    jmp     .iter
    
    .finish:
    sub     rdi, arr        ; find size
    mov     [size], edi       ; save to size variable
    call    itoa
    mov     rdi, 1
    mov     rdx, rax
    call    println
    
    mov     rdi, arr
    mov     rsi, [size]
    call    printArray
    
    mov     rdi, 0          ; exit program
    mov     rax, 60
    syscall

pos:    ; pos(substr, str, i) return in eax first position of substring substr in source string str from index i, if fail return -1
    push    rbp
    mov     rbp, rsp
    sub     rsp, 8h
    mov     [rbp - 8], rsi
    add     rsi, rdx
    
    .iter:
    xor     rcx, rcx
    .strcmp:
    mov     dh, [rdi + rcx]
    cmp     dh, 0xa                  
    jz      .found                  ; meet end of substr
    mov     dl, [rsi + rcx]
    cmp     dl, 0xa
    jz      .notfound               ; meet end of str
    inc     rcx
    cmp     dl, dh
    je      .strcmp
    inc     rsi                     ; next loop
    jmp     .iter
    
    .found:
    sub        rsi, [rbp - 8]
    mov        eax, esi    ; res
    jmp        .finish
    .notfound:
    mov        eax, -1
    jmp        .finish

    .finish:
    mov        rsp, rbp
    pop        rbp
    ret         