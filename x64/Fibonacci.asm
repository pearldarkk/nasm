%include    'func64.asm'
section .bss
    n   resb    4
section .text
global _start
_start:
    mov     rbp, rsp    
    ; get user input for n    
    mov     rdx, 4
    mov     rsi, n
    mov     rdi, 0
    mov     rax, 0
    syscall
    mov     rdi, n
    call    atoi                ; convert to int    
    mov     edi, eax            
    call    fibcalc             ; fibcalc(n)
    
    mov     rdi, 0
    mov     rax, 60
    syscall
    
fibcalc:    ; void 
    push    rbp
    mov     rbp, rsp
    sub     rsp, 0x28
    mov     [rbp - 0x1a], di    ; sizeof n = byte                     
    
    ; create space for f0, f1 and tmp in heap
    mov     rdi, 0
    mov     rax, 12
    syscall
    mov     rbx, rax        ; save current offset to rbx
    mov     rdi, rax
    add     rdi, 65         ; f0 f1 tmp = 21 bytes each
    mov     rax, 12
    syscall
    mov     [rbp - 8], rbx      ; f0
    add     rbx, 21
    mov     [rbp - 0x10], rbx   ; f1
    add     rbx, 21 
    mov     [rbp - 0x18], rbx   ; tmp  

    mov     bl, '0'             ; f0 = '0'
    mov     rdi, [rbp - 8]
    mov     [rdi], bl
    inc     rdi
    mov     byte [rdi], 0xa
    mov     bl, '1'             ; f1 = '1'
    mov     rdi, [rbp - 0x10]
    mov     [rdi], bl
    
    .print1:
    mov     rdi, 1
    mov     rsi, [rbp - 0x10]   ; print f1
    mov     rdx, 1
    call    println
    mov     cx, [rbp - 0x1a]
    dec     cx
    test    cx, cx
    jz      .finish
    mov     [rbp - 0x1a], cx
    
    .calc:
    mov     rdi, [rbp - 8]      ; tmp = f0 + f1
    mov     rsi, [rbp - 0x10]
    mov     rdx, [rbp - 0x18]
    call    bigSum                 ; sum(op1, op2, sum)
    mov     rdi, 1
    mov     rsi, rax
    call    println             ; write tmp
    mov     cx, [rbp - 0x1a]
    dec     cx
    test    cx, cx
    jz      .finish
    mov     [rbp - 0x1a], cx
    push    qword [rbp - 8]
    push    qword [rbp - 0x10]
    pop     qword [rbp - 8]             ; f0 = f1
    push    qword [rbp - 0x18]
    pop     qword [rbp - 0x10]          ; f1 = tmp
    pop     qword [rbp - 0x18]          ; tmp = f0 to be overwritten
    jmp     .calc
    
    .finish:
    ; free memory allocated in heap
    test    rdi, rdi
    mov     rax, 12
    syscall             ; get current program break
    mov     rdi, rax
    sub     rdi, 65
    mov     rax, 12
    syscall             ; free space
    mov     rsp, rbp
    pop     rbp
    ret            

