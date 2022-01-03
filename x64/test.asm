;%include 'func64.asm'

section .data
    n   dq  2000000000
    
section .text
global _start:
_start:
    mov     rdi, [n]
    call    ltoa
    mov     rdx, rax
    mov     rdi, 1
    call    println
    
    mov     rdi, 0
    mov     rax, 60
    syscall
    
ltoa:   ; long long (64bit integer) to ascii, return strlen in rcx, pointer in rax
    push    rbp    
    mov     rbp, rsp
    push    rbx
    push    rcx
    mov     rbx, rdi      ; save int to ebx
    
    ; dynamic memory allocation to make room to create string
    xor     rdi, rdi     
    mov     rax, 12
    syscall                     ; sys_brk(0) fails, return current program break
    mov     rdi, rax
    add     rdi, 20             
    mov     rax, 12
    syscall                     ; sys_brk(current_break + 10)
    dec     rax
    mov     rsi, rax            ; rsi = *(str + 20)
    mov     rax, rbx
    mov     rdi, rsi
    mov     rbx, 10
    
    .iter:
    xor     rdx, rdx
    div     rbx
    or      dl, 0x30
    mov     [rdi], dl
    dec     rdi
    test    rax, rax
    jz      .done
    jmp     .iter

    .done:
    sub     rsi, rdi
    mov     rax, rsi
    mov     rsi, rdi
    inc     rsi
    pop     rcx
    pop     rbx
    mov     rsp, rbp
    pop     rbp
    ret   
    
println:    ; print with linefeed by append linefeed to string
    mov     al, 0xa
    mov     [rsi + rdx], al
    inc     rdx
    mov     rax, 1
    syscall
    ret