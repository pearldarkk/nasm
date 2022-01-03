    GLOBAL _start
 
    SECTION .data
_lf         DB      10, 0
;
msgInN      DB      "N = ", 0
msgFib1     DB      "F(", 0
msgFib2     DB      ") = ", 0
decN        db      '40', 0xa
    SECTION .bss
lenStr      RESQ    1
numDec      RESQ    20
;
intN        RESQ    1
breakHeap   RESQ    1
;decN        RESB    20
ptrA        RESQ    1
ptrB        RESQ    1
;decA        RESB    101
;decB        RESB    101
 
    SECTION .text
_start:
        mov     rbp, rsp
;       message input number N
        mov     rsi, msgInN
        call    puts
;       input number N
        mov     rsi, decN   ; Source register
        mov     rdx, 20     ; Common counter
        ;call    gets
;       convert string number N to INT
        mov     rdi, decN
        call    atoi
        mov     rbx, rax
;       heap allocate
        mov     rax, 12
        mov     rdi, 0
        syscall
        mov     [ptrA], rax
        mov     rax, 12
        mov     rdi, [ptrA]
        add     rdi, 200
        syscall
        sub     rax, 100
        mov     [ptrB], rax
 
;       set two first fibonacci
        mov     rax, [ptrA]
        mov     byte [rax], 30h ; '0'
        inc     rax
        mov     BYTE [rax], 0 ; add value end string
;       set value B = "1/0"
        mov     BYTE [ptrB], 31h ; '0'
        mov     BYTE [ptrB + 1], 0 ; add value end string
;
        xor     rax, rax
    .fibL:
        mov     rsi, msgFib1
        call    puts
        mov     rdi, rax
        call    writeDEC
        mov     rsi, msgFib2
        call    puts
        test    rax, 1
        jnz     .fibChBr
;       print fibo
        mov     rsi, ptrA
        call    puts
;       add
        mov     rdx, ptrB
        mov     rsi, ptrB
        mov     rdi, ptrA
        call    addBigNum
        jmp     .fibContinue
    .fibChBr:
;       print fibo
        mov     rsi, ptrB
        call    puts
;       add
        mov     rdx, ptrA
        mov     rsi, ptrB
        mov     rdi, ptrA
        call    addBigNum
    .fibContinue:
;       Newline
        mov     rsi, _lf
        call    puts
        inc     rax
        cmp     rax, rbx
        jne     .fibL
;
        mov     rax, 12
        mov     rdi, [ptrA]
        syscall
;
        mov     rdi, 0
        mov     rax, 60
        syscall
        ret
 
addBigNum:
        push    rbp
        mov     rbp, rsp
        sub     rsp, 20h
        push    rax
        push    rbx
        push    rcx
        mov     [rbp - 8], rdi
        mov     [rbp - 10h], rsi
        mov     [rbp - 18h], rdx
        mov     rdi, [rbp - 10h]
        call    strReversal     ; reverse string
        mov     rbx, rax        ; ebx = len(b)
        mov     rdi, [rbp - 8]
        call    strReversal     ; reverse string, eax = len(a)
        ;
        cmp     rax, rbx
        jl      .b_longer_than_a        ; len(a) > len(b)
        mov     QWORD [rbp - 20h], rax  ; local_var = len(a)
        je      .startLAddBN
        mov     rdi, rax
        mov     rsi, [rbp - 10h]
        call    insertZero      ; insertZero -> len(a) = len(b)
        jmp     .startLAddBN
    .b_longer_than_a:
        mov     rdi, rbx
        mov     rsi, [rbp - 8]
        call    insertZero      ; insertZero -> len(a) = len(b)
        mov     QWORD [rbp - 20h], rbx    ; local_var = len(b)
        ;
    .startLAddBN:
        xor     rcx, rcx        ; cmovr RCX
        xor     rdx, rdx        ; cmovr RAX
        mov     rsi, [rbp - 8]  ;
        mov     rdi, [rbp - 10h];
    .loopAddBN:
        movzx   rax, BYTE [rsi + rcx]   ; get char in string
        movzx   rbx, BYTE [rdi + rcx]   ; get char in string
        xor     al, 30H         ; char to dec
        xor     bl, 30H         ; char to dec
        add     al, bl          ; a[i] + b[i]
        add     al, dl          ; s = a[i] + b[i] + carry
        cmp     al, 10          ; s > 10
        jb      .addBN_not_reminder
        mov     dl, 1           ; carry = 1
        sub     al, 10          ; s = s - 10
        jmp     .contAddBN
    .addBN_not_reminder:
        mov     dl, 0           ; carry = 0
    .contAddBN:
        or      al, 30h         ; dec to char
        push    rax             ; push to stack
        inc     rcx
        cmp     rcx, QWORD [RBP - 20h]
        jne     .loopAddBN
        ;
        mov     rdi, [rbp - 10h]
        call    strReversal     ; reverse string
        mov     rdi, [rbp - 8]
        call    strReversal     ; reverse string
        ;
        test    dl, dl
        jz      .addBN_reminder_mty
        push    31h             ; PUSH '1' into stack when carry = 1
        add     QWORD [rbp - 20h], 1    ; local_var++
    .addBN_reminder_mty:
        mov     rdx, [rbp - 18h]
        xor     rcx, rcx
    .loopPopStrBN:              ; LIFO -> return correct string number
        pop     rax
        mov     BYTE [rdx + rcx], al
        inc     rcx
        cmp     rcx, QWORD [rbp - 20h]
        jne     .loopPopStrBN
        mov     BYTE [rdx + rcx], 0     ; add end string
        pop     rcx
        pop     rbx
        pop     rax
        leave
        ret
 
insertZero:             ; ARG: RSI pointer string number, RDI target string length
        push    rdx
        mov     rdx, rsi
        call    strLen      ; get strlen
    .loopInsertZR:
        mov     BYTE [rsi + rdx], '0'    ; str[len] = '0'
        inc     rdx         ; len++
        cmp     rdx, rdi    ; len == target_len ?
        jne     .loopInsertZR
        pop     rdx
        ret
 
strReversal:
        push    rcx
        push    rdx
        mov     rdx, rdi
        call    strLen
        cmp     BYTE [rdi + rdx], 10
        jne     .notFoundNL
        dec     rdx             ; not count /n
    .notFoundNL:
        push    rdx             ; for return strlen
;       reverse string with stack (FILO)
;       push char (left -> right) into stack
;       when pop out to array string reverse
        xor     rcx, rcx
    .loopPushStrRev:            ; push char into stack
        push    QWORD [rdi + rcx]; push value into stack
        inc     rcx             ; RCX++
        cmp     rcx, rdx        ; check end string
        jne     .loopPushStrRev
    .loopPopStrRev:             ; pop out char to array
        pop     rax             ; RAX = stack.top()
        stosb                   ; store AL to RDI
        dec     rcx             ; RCX--
        test    rcx, rcx        ; TEST same like AND but do not change register val but change flag val
        jnz     .loopPopStrRev
        pop     rax             ; for return strlen
        pop     rdx
        pop     rcx
        ret
 
writeDEC:           ; ARG: RDI - number
        push    rsi
        mov     rdi, rdi
        call    itoa
        mov     rsi, numDec
        call    puts
        pop     rsi
        ret
 
itoa:               ; ARG: RDI - number
        push    rax
        push    rbx
        push    rcx
        push    rdx
        mov     rax, rdi
        mov     rdi, numDec
        xor     rcx, rcx        ; Cmovn RCX
        mov     rbx, 10         ; Divisor = 10
    .loopDivItoA:                        ; 
        xor     rdx, rdx        ; Cmovn RDX
        div     rbx             ; RAX / EBX = RAX remainder RDX
        push    dx              ; Storage DX in stack (LIFO)
        inc     cl              ; Counter++
        test    rax, rax        ; If RAX = 0 -> ZF = 1
        jnz     .loopDivItoA    ; Jump to .loopDivItoA if ZF = 0
    .loopItoA:                  ;
        pop     ax              ; Get value storage in top stack
        or      al, 30h         ; Convert dec to char
        stosb                   ; Store AL to RDI (that same `MOV BYTE PTR [RDI], AL` and `INC RDI`)
        dec     cl              ; Counter--
        test    cl, cl          ; If CL = 0 -> ZF = 1
        jnz     .loopItoA       ; Jump to .loopItoA if ZF = 0
        mov     BYTE [rdi], 0   ; Add '\0'
        ;mov     BYTE [rdi], 10  ; Add '\r'
        pop     rdx
        pop     rcx
        pop     rbx
        pop     rax
        ret         ; RET: RDI pointer to ASCII-string
 
atoi:               ; ARG: RDI pointer string buffer contain int
        push    rbx
        push    rcx
        xor     rcx, rcx        ; Cmovn RCX
        xor     rax, rax        ; Cmovn RAX
    .loopAtoI:
        movzx   rbx, BYTE [rdi + rcx] ; Get a char
        inc     rcx             ; Idex++ for next char
        cmp     bl, '0'         ; Compare char with char number 0
        jb      .eLoopAtoI      ; Jump to .eLoopAtoI if char < char 0
        cmp     bl, '9'         ; Compare char with char number 9
        ja      .eLoopAtoI      ; Jump to .eLoopAtoI if char < char 9
        xor     rbx, 30h        ; Convert character to number
        imul    rax, 10         ; Multiply previous number by ten
        add     rax, rbx        ; Add in current digit
        jmp     .loopAtoI       ; Jump to .loopAtoI
    .eLoopAtoI:
        ;mov     rdx, rcx        ; RDX count char (optional)
        pop     rcx
        pop     rbx
        ret         ; RET: RAX int value
 
puts:               ; ARG: RSI pointer string
        push    rcx             ; syscall uses RCX itself
        push    rdx             ; RDX (data) is used as the length of the message
        push    rax             ; RAX is the instruction to WRITE
        push    rdi             ; RDI (destination) is used as an instruction to WRITE
        ;;      rsi contain pointer string
        mov     rdx, rsi
        call    strLen          ; ret RDX as string length
        mov     rdi, 1          ; using STDOUT (see definition above)
        mov     rax, 1          ; Using WRITE
        syscall
        pop     rdi
        pop     rax
        pop     rdx
        pop     rcx
        ret
 
gets:               ; ARG: RSI - pointer string, RDX - string length
        push    rbp
        mov     rbp, rsp
        sub     rsp, 1
        push    rdi
        mov     rax, 0          ; General purpose register
        mov     rdi, 0          ; Destination Index
        syscall
        cmp     rax, rdx
        jl      .good
        cmp     BYTE [rsi + rdx - 1], 10
        je      .good
        mov     BYTE [rsi + rdx - 1], 10
        push    rdx             ; Storage strlen
    .cmovrTerm:
        mov     rax, 0          ; General purpose register
        mov     rdi, 0          ; Destination Index
        mov     rsi, [rbp - 1]  ; Source register
        mov     rdx, 1          ; Common counter
        syscall
        cmp     BYTE [rsi], 10
        jne     .cmovrTerm
        pop     rax
    .good:
        pop     rdi
        leave
        ret         ; RET: RAX - strlen
 
strLen:             ; ARG: RDX pointer string
        push    rsi
        mov     rsi, rdx
    .strlen_next:
        cmp     byte [rdx], 0
        jz      .strlen_done
        inc     rdx
        jmp     .strlen_next
    .strlen_done:
        sub     rdx, rsi
        pop     rsi
        ret         ; RET: RDX length string
 