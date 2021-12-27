; %include "func64.asm"
section .data
    sHello  db  'Hello, World!', 0Ah
    
section .text
global _start:
_start:
    mov     rbp, rsp
    
    mov     rdi, 1      ; STDOUT
    mov     rsi, sHello ; buffer addr
    mov     rdx, 14     ; number of chars to write
    mov     rax, 1      ; SYS_WRITE
    syscall 
    
    xor     rdi, rdi    ; value
    mov     rax, 60     ; sys_exit
    syscall
    

    