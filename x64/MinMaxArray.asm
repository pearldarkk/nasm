%include 'func64.asm'

section .bss
    buffer  resb  10000
    szArr   resd  1  
    arr     resd  100     
    min     resd  1
    max     resd  1

section .data
    sSizeReq    db  'Nhap kich thuoc mang n: ', 0
    sArrReq     db  'Nhap n phan tu cua mang: ', 0
    sMinResult  db  'Min: ', 0
    sMaxResult  db  'Max: ', 0

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
    mov     rdi, arr
    mov     esi, [szArr]
    mov     rdx, min
    call    findMin
    mov     rdi, arr
    mov     esi, [szArr]
    mov     rdx, max
    call    findMax

    ; println(min)
    mov     rdi, 1
    mov     rsi, sMinResult
    mov     rdx, 6
    mov     rax, 1
    syscall
    mov     edi, [min]  
    call    itoa
    mov     rdi, 1
    mov     rdx, rax
    call    println

    ; println(max)
    mov     rdi, 1
    mov     rsi, sMaxResult
    mov     rdx, 6
    mov     rax, 1
    syscall
    mov     edi, [max]  
    call    itoa
    mov     rdi, 1
    mov     rdx, rax
    call    println

    mov     rdi, 0
    mov     rax, 60
    syscall
    
findMin:                ; findMin(&arr, sizeof arr, &min) return array's min value in &min
    push    rbp
    mov     rbp, rsp
    push    rbx
    mov     r8d, 0ffffffffh
    xor     rbx, rbx
    .compare:
    cmp     [rdi], r8d  ; < min
    jb      .isMin
    .iterate:
    add     rdi, 4
    inc     ebx
    cmp     ebx, esi
    je      .finish
    jmp     .compare
    .isMin:
    mov     r8d, [rdi]  ; min = arr[i]
    jmp     .iterate

    .finish:
    mov     dword [rdx], r8d
    pop     rbx
    mov     rsp, rbp
    pop     rbp
    ret

findMax:                ; findMax(&arr, sizeof arr, &max) return array's max value in &max
    push    rbp
    mov     rbp, rsp
    push    rbx
    mov     r8d, 0
    xor     rbx, rbx
    .compare:
    cmp     [rdi], r8d  ; > max
    ja      .isMax
    .iterate:
    add     rdi, 4
    inc     ebx
    cmp     ebx, esi
    je      .finish
    jmp     .compare
    .isMax:
    mov     r8d, [rdi]  ; max = arr[i]
    jmp     .iterate

    .finish:
    mov     dword [rdx], r8d
    pop     rbx
    mov     rsp, rbp
    pop     rbp
    ret
