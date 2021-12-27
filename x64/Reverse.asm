%include        'func64.asm'
section .bss
    string  resb  256

section .text
    global _start
_start:
    mov     rbp, rsp
    ; get user input
    mov     rdi, 0
    mov     rsi, string
    mov     rdx, 256
    mov     rax, 0
    syscall
    
    mov     rdi, string
    call    reverse
    
    mov     rsi, rax
    mov     rdi, 1
    call    println
    
    mov     rdi, 0
    mov     rax, 60
    syscall

