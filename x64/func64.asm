atoi:   ; ascii to int, return in eax
    push    rbp
    mov     rbp, rsp
    sub     rsp, 8
    push    rbx
    mov     [rbp - 8], rdi     
    mov     rsi, rdi
    xor     eax, eax
    xor     ecx, ecx
    mov     ebx, 10
    
    .iter:
    mul     ebx
    mov     cl, [rsi]
    inc     si
    cmp     cl, '0'
    js      .done
    cmp     cl, '9'
    jg      .done
    and     cl, 0xf
    add     eax, ecx
    jmp     .iter

    .done:
    div     ebx
    pop     rbx
    mov     rsp, rbp
    pop     rbp    
    ret    
    
atol:   ; ascii to ull, return in rax
    push    rbp
    mov     rbp, rsp
    sub     rsp, 8
    push    rbx
    mov     [rbp - 8], rdi     
    mov     rsi, rdi
    xor     rax, rax
    xor     rcx, rcx
    mov     rbx, 10
    
    .iter:
    mul     rbx
    mov     cl, [rsi]
    inc     rsi
    cmp     cl, '0'
    js      .done
    cmp     cl, '9'
    jg      .done
    and     cl, 0xf
    add     rax, rcx
    jmp     .iter

    .done:
    div     rbx
    pop     rbx
    mov     rsp, rbp
    pop     rbp    
    ret    
    
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

itoa:   ; int to ascii, return size in rax, pointer in rsi
    push    rbp    
    mov     rbp, rsp
    push    rbx
    push    rcx
    mov     ebx, edi      ; save int to ebx
    
    ; dynamic memory allocation to make room to create string
    xor     rdi, rdi     
    mov     rax, 12
    syscall                     ; sys_brk(0) fails, return current program break
    mov     rdi, rax
    add     rdi, 10             
    mov     rax, 12
    syscall                     ; sys_brk(current_break + 10)
    dec     rax
    mov     rsi, rax            ; rsi = *(str + 9)
    mov     eax, ebx
    mov     rdi, rsi
    mov     ebx, 10
    
    .iter:
    xor     edx, edx
    div     ebx
    or      dl, 0x30
    mov     [rdi], dl
    dec     di
    test    eax, eax
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
            
print:      ; print with 1 space
    mov     al, 0x20
    mov     [rsi + rdx], al
    inc     rdx
    mov     rax, 1
    syscall
    ret

printArray:  ; print n elements of array arr
    push    rbp
    mov     rbp, rsp
    sub     rsp, 0x10          ; align stack to call other functions
    mov     ecx, esi
    mov     [rbp - 8], rdi
        
    .iter:
    mov     rdi, [rbp - 8]
    mov     di, [rdi]
    and     edi, 0xff       ; get (byte) *[arr] to edi
    call    itoa            ; convert each element to ascii
    mov     rdi, [rbp - 8]
    inc     di
    mov     [rbp - 8], rdi 
    mov     [rbp - 0xc], ecx
    mov     rdi, 1
    movzx   rdx, ax
    call    print
    mov     ecx, [rbp - 0xc]
    dec     ecx
    test    ecx, ecx
    jnz     .iter
    
    mov     rsp, rbp
    pop     rbp
    ret    

reverse:    ; reverse(str) use stack to store each byte and pop to reverse the string str, return *st in rax, str.size in rdx
    push    rbp
    mov     rbp, rsp  
    mov     rsi, rdi
    xor     ax, ax
    xor     rcx, rcx
    cld                     ; clear direction flag DF
    
    .iterPush:              ; iterate string and push to stack
    lodsb                   ; al = byte ptr [esi]++
    cmp     al, 0xa
    jng     .pop
    push    ax              ; push 16bit
    inc     cx
    jmp     .iterPush

    .pop:
    mov     rdx, rcx
    mov     rsi, rdi        ; save begin of str
    .iterPop:               ; pop back
    pop     ax
    stosb                   ; byte ptr [rdi]-- = al
    dec     cx
    test    cx, cx
    jz      .done
    jmp     .iterPop
    
    .done:
    mov     rax, rsi
    mov     rsp, rbp
    pop     rbp
    ret  

ltoh:  ; ltoh([in] val, [out] hexString) convert int64 to hex string return szArr in rax
    push    rbp    
    mov     rbp, rsp
    mov     rax, rdi
    mov     rdi, rsi            
    mov     r10, rdi            ; save rdi
    mov     r8, 16
    push    "#"                 ; pivot
    .getDigit:
    xor     rdx, rdx
    div     r8
    cmp     edx, 0Ah
    jl      .xor30
    add     edx, 37h            ; if a - f -> "a"-"f"
    jmp     .saveDigit
    
    .xor30:
    xor     edx, 30h            ; if 0 - 9 -> "0" - "9"
    .saveDigit:
    push    dx
    test    rax, rax
    jz      .toString
    jmp     .getDigit

    .toString:                   ; get char from stack to hexString
    pop     ax
    cmp     ax, "#"
    jz      .done
    stosb
    jmp     .toString

    .done:
    sub     rdi, r10
    mov     rax, rdi
    mov     rsp, rbp
    pop     rbp
    ret   

strncmp:           ; work similar to strncmp() in C
    push    rbp
    mov     rbp, rsp

    cld
    mov     rcx, rdx
    .iter:
    lodsb
    mov     dl, byte [rdi]
    cmp     al, dl
    jnz     .exit
    inc     rdi
    dec     cx
    jnz     .iter

    .equal:
    mov     rax, 0
    pop     rdi
    pop     rsi
    mov     rsp, rbp
    pop     rbp
    ret

    .exit:
    mov     rax, rcx
    mov     rsp, rbp
    pop     rbp
    ret

strlencalc:     ; calculate strlen(&rdi), return in rax
    push    rbp
    mov     rbp, rsp
    mov     rax, 0
    
    .iter:
    cmp     byte [rdi], 0xa
    jz      .finished
    cmp     byte [rdi], 0
    jz      .finished
    inc     rdi
    inc     rax
    jmp     .iter
    
    .finished:
    mov     rsp, rbp
    pop     rbp
    ret

bigSum:
    push    rbp
    mov     rbp, rsp
    sub     rsp, 0x20     
    push    rbx   
    mov     [rbp - 8], rdi
    mov     [rbp - 0x10], rsi
    mov     [rbp - 0x18], rdx    
    call    reverse             ; reverse(op1)
    mov     rdi, [rbp - 0x10]   
    call    reverse             ; reverse(op2)
    mov     rdi, [rbp - 8]
    mov     rsi, [rbp - 0x10]
    mov     rdx, [rbp - 0x18]
    xor     rax, rax
    xor     r8, r8
    mov     bh, 0x30
    mov     bl, 0xa
    
    .calc:
    mov     cl, [rsi + r8]
    cmp     cl, bl
    jz      .swap                    ; if one string's shorter, swap 
    sub     cl, bh
    mov     ah, cl                  ; + carry of the previous 
    mov     cl, [rdi + r8]
    cmp     cl, bl
    jz      .load                    ; if this is the longer string, load the rest (with carry) to complete
    sub     cl, bh
    add     al, cl                  ; digit2 + carry
    add     al, ah                  ; digit1 + digit2
    xor     ah, ah                  ; prepare div
    div     bl                
    add     ah, bh                  ; char(remainder)
    mov     cl, ah
    mov     [rdx + r8], cl
    inc     r8
    jmp     .calc
    
    .swap:
    xchg    rsi, rdi
    
    .load:
    mov     cl, [rsi + r8]
    add     al, cl                  ; + carry of the previous sum calc
    cmp     al, bl                  ; meets end and have no carry
    jz      .finish
    cmp     al, bh
    jl      .carry                   ; if still have carry
    sub     al, bh
    xor     ah, ah
    div     bl
    add     ah, bh              
    mov     cl, ah
    mov     [rdx + r8], cl
    inc     r8
    jmp     .load
    
    .carry:
    add     al, 23h                ; 0xd + carry + 0x23 = char(carry)
    mov     [rdx + r8], al
    
    .finish:
    mov     rdi, [rbp - 8]
    call    reverse             ; reverse(op1)
    mov     rdi, [rbp - 0x10]       
    call    reverse             ; reverse(op2)
    mov     rdi, [rbp - 0x18]
    call    reverse             ; reverse(sum)   
    mov     rax, [rbp - 0x18]   
    pop     rbx
    mov     rsp, rbp
    pop     rbp
    ret 