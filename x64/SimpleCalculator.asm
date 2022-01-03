%include    'func64.asm'

section .bss
    operand1    resb  22
    operand2    resb  22
    operator    resb  1
    result      resq  1
    remainder   resq  1
    negResult   resb  1
    
section .data
    sOperatorRequest db "Select operator:", 0Ah, "1. Addition", 0Ah, "2. Subtraction", 0Ah, "3. Multiplication", 0Ah, "4. Division", 0Ah, "0. Exit", 0Ah, "-> ", 0
    sOperandRequest  db "Input 2 operands in 2 separate lines: ", 0ah, 0
    sResultOutput    db "Result: ", 0
    sRemainderOutput db "Remainder: ", 0
    
section .text
global _start
_start:
    mov     rbp, rsp
    
    .startCalculating:
    ; Get operator choice
    mov     byte [negResult], 0
    mov     rdi, 1
    mov     rsi, sOperatorRequest
    mov     rdx, 0x56
    mov     rax, 1
    syscall
    mov     rdi, 0
    mov     rsi, operator
    mov     rdx, 3
    mov     rax, 0
    syscall

    mov     dl, [operator]
    cmp     dl, '0'
    jz     .finish
    
    mov     rdi, 1
    mov     rsi, sOperandRequest
    mov     rdx, 40
    mov     rax, 1
    syscall
    mov     rdi, 0
    mov     rsi, operand1
    mov     rdx, 22
    mov     rax, 0
    syscall
    mov     rdi, 0
    mov     rsi, operand2
    mov     rdx, 22
    mov     rax, 0
    syscall
                            ; convert 2 operand to integer
    mov     rdi, operand1
    call    atol
    mov     r12, rax
    mov     rdi, operand2
    call    atol
    mov     r13, rax                ; r13 = op2, r12 = op1
    
    ; calculating...
    mov     dl, [operator]           
    sub     dl, '1'                ; implement switch-case
    jz      .addition
    dec     dl
    jz      .subtraction
    dec     dl
    jz      .multiplication
    dec     dl
    jz      .division
    ;default
    jmp     .startCalculating
    
    .addition:
    add     r12, r13
    mov     [result], r12
    jmp     .printResult

    .subtraction:
    mov     rdx, r12        ; save r12
    sub     r12, r13
    js      .negativeResult
    mov     [result], r13
    jmp     .printResult
    .negativeResult:
    mov     byte [negResult], 1
    mov     r12, rdx
    sub     r13, r12
    mov     [result], r13
    jmp     .printResult

    .multiplication:
    mov     rax, r13
    mul     r12
    mov     [result], rax
    jmp     .printResult

    .division:
    xor     rdx, rdx
    mov     rax, r12
    div     r13
    mov     [result], rax
    mov     [remainder], rdx
    
    .printResult:
    mov     rdi, 1
    mov     rsi, sResultOutput
    mov     rdx, 9
    mov     rax, 1
    syscall
    mov     rdi, [result]
    call    ltoa            
    cmp     byte [negResult], 1
    jz     .addSign
    .continue:
    mov     rdi, 1
    mov     rdx, rax
    call    println

    ; if division, print remainder
    mov     dl, [operator]
    cmp     dl, '4'
    je      .printRemainder
    jmp     .startCalculating
    
    .printRemainder:
    mov     rdi, 1
    mov     rsi, sRemainderOutput
    mov     rdx, 12
    mov     rax, 1
    syscall
    mov     rdi, [remainder]
    call    ltoa            
    mov     rdi, 1
    mov     rdx, rax
    call    println
    jmp     .startCalculating    ; new loop

    .addSign:
    dec     rsi
    mov     byte [rsi], '-'
    inc     rax
    jmp     .continue

    .finish:
    mov     rdi, 0
    mov     rax, 60
    syscall
    
