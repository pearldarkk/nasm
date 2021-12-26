%include    'func64.asm'
section .bss
    num1    resb    21
    num2    resb    21
    sum     resb    21

section .text
global _start
_start:
    mov     rbp, rsp    
    ; get user input for num1    
    mov     rdx, 21
    mov     rsi, num1
    mov     rdi, 0
    mov     rax, 0
    syscall
    ; get user input for num2    
    mov     rdx, 21
    mov     rsi, num2
    mov     rdi, 0
    mov     rax, 0
    syscall
    
    mov     rdi, num1
    mov     rsi, num2
    mov     rdx, sum
    call    bigSum
    mov     rdi, 1
    mov     rsi, rax
    call    println
    
    mov     rdi, 0
    mov     rax, 60
    syscall
    
    
    
