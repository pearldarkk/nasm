%include 'func64.asm'

section .bss
    buffer  resb  10000
    szArr   resd  1  
    arr     resd  100     
    oddSum  resq  1
    evenSum resq  1

section .data
    sSizeReq        db  'Nhap kich thuoc mang n: ', 0
    sArrReq         db  'Nhap n phan tu cua mang: ', 0
    sOddSumResult   db  'Tong cac phan tu le: ', 0
    sEvenSumResult  db  'Tong cac phan tu chan: ', 0

section .text
global _start
_start:
    mov     rbp, rsp
    sub     rsp, 8

    ; Get size of array
    mov     rdi, 1
    mov     rsi, sSizeReq
    mov     rdx, 25
    mov     rax, 1
    syscall
    mov     rdi, 0
    mov     rsi, buffer
    mov     rdx, 10
    mov     rax, 0
    syscall 
    mov     rdi, buffer
    call    atoi
    mov     [szArr], eax

    ; Get elements of array
    mov     rdi, 1
    mov     rsi, sArrReq
    mov     rdx, 25
    mov     rax, 1
    syscall    
    xor     rbx, rbx
    .getArrayBuffer:                   ; get element until receives n elements
    mov     rdi, 0
    mov     rsi, buffer
    mov     rdx, 10000
    mov     rax, 0
    syscall 
    
    mov     rdi, buffer
    mov     r12, arr
    .getElement:                 ; separate buffer to get elements
    push    rdi
    call    atoi
    mov     [r12 + rbx*4], eax
    inc     ebx
    cmp     [szArr], ebx              
    je      .doneGetArray        ; got enough elements
    pop     rdi
    .iterBuffer:
    cmp     byte [rdi], 0xa
    jz      .getArrayBuffer
    inc     rdi
    cmp     byte [rdi - 1], 0x20
    je      .getElement
    jmp     .iterBuffer

    .doneGetArray:
    add     rsp, 8
    mov     ecx, 0
    mov     rdi, arr
    mov     r8, 0
    mov     r9, 0
    .checkIndex:
    mov     r10d, [rdi]
    test    ecx, 1b
    jz      .calcEvenSum
    add     r9, r10             ; else it is odd-index
    jmp     .iterate
    .calcEvenSum:
    add     r8, r10
    .iterate:
    add     rdi, 4
    inc     ecx
    cmp     ecx, [szArr]
    jnz     .checkIndex      
    ; end loop
    mov     [evenSum], r8
    mov     [oddSum], r9

    ; println(evenSum)
    mov     rdi, 1
    mov     rsi, sEvenSumResult
    mov     rdx, 24
    mov     rax, 1
    syscall
    mov     rdi, [evenSum]
    call    ltoa
    mov     rdx, rax
    mov     rdi, 1
    call    println

    ; println(oddSum)
    mov     rdi, 1
    mov     rsi, sOddSumResult
    mov     rdx, 22
    mov     rax, 1
    syscall
    mov     rdi, [oddSum]
    call    ltoa
    mov     rdx, rax
    mov     rdi, 1
    call    println
    
    mov     rdi, 0
    mov     rax, 60
    syscall
    
