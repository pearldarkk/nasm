atoi:   ; ascii to int, return in eax
    push    rbp
    mov     rbp, rsp
    sub     rsp, 8
    mov     [rbp - 8], rdi     
    mov     rsi, rdi
    xor     eax, eax
    mov     ebx, 10
    
    .iter:
    mul     ebx
    mov     dl, [rsi]
    inc     si
    cmp     dl, 0xa
    jz      .done
    and     dl, 0xf
    add     eax, edx
    jmp     .iter

    .done:
    xor     edx, edx    
    div     ebx
    mov     rsp, rbp
    pop     rbp    
    ret    

itoa:   ; int to ascii, return size in rax, pointer in rsi
    push    rbp    
    mov     rbp, rsp
    push    rcx
    mov     ebx, edi      ; save int to ebx
    
    ; dynamic memory allocation to make room to create string
    test    rdi, rdi     
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
    sub     rsp, 0x18          ; align stack to call other functions
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
    mov     [rbp - 0x14], ecx
    mov     rdi, 1
    movzx   rdx, ax
    call    print
    mov     ecx, [rbp - 0x14]
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

bigSum:
    push    rbp
    mov     rbp, rsp
    sub     rsp, 0x18        
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
    mov     bh, 0x30
    mov     bl, 0xa
    
    .calc:
    mov     ah, [rsi]
    inc     rsi
    cmp     ah, bl
    jz      .swap               ; if one string's shorter, swap 
    sub     ah, bh
    add     al, ah              ; + carry of the previous 
    mov     ah, [rdi]
    inc     rdi
    cmp     ah, bl
    jz      .load               ; if this is the longer string, load the rest (with carry) to complete
    sub     ah, bh
    add     al, ah
    xor     ah, ah              ; prepare div
    div     bl                
    add     ah, bh              ; char(remainder)
    mov     [rdx], ah
    inc     rdx
    jmp     .calc
    
    .swap:
    xchg    rsi, rdi
    
    .load:
    mov     ah, [rsi]
    inc     rsi
    add     al, ah              ; + carry of the previous sum calc
    cmp     al, bl              ; meets end and have no carry
    jz      .finish
    cmp     al, bh
    jl      .carry              ; if still have carry
    sub     al, bh
    xor     ah, ah
    div     bl
    add     ah, bh              
    mov     [rdx], ah
    inc     rdx
    jmp     .load
    
    .carry:
    add     al, 0x26            ; 0xa + carry + 0x20 = char(carry)
    mov     byte [edx + ecx], al
    
    .finish:
    mov     rdi, [rbp - 8]
    call    reverse             ; reverse(op1)
    mov     rdi, [rbp - 0x10]       
    call    reverse             ; reverse(op2)
    mov     rdi, [rbp - 0x18]
    call    reverse             ; reverse(sum)   
    mov     rax, [rbp - 0x18]   
    mov     rsp, rbp
    pop     rbp
    ret 