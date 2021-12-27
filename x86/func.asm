readConsole:
	push	ebp
	mov	ebp, esp
	push	edx
	push	ecx
	push	ebx
	
	mov	edx, [ebp + 0xc]
	mov	ecx, [ebp + 8]
	mov	ebx, 0
	mov	eax, 3
	int 	0x80

	pop	ebx
	pop	ecx
	pop	edx
	mov	esp, ebp	
	pop	ebp
	ret	8

writeConsole:
	push	ebp
	mov	ebp, esp
	push	edx
	push	ecx
	push	ebx

	mov	edx, [ebp + 0xc]
	mov	ecx, [ebp + 8]
	mov	ebx, 1
	mov	eax, 4
	int 	0x80

	pop	ebx
	pop	ecx
	pop	edx
	mov	esp, ebp
	pop	ebp
	ret	8

exitProcess:
	mov	ebx, 0
	mov	eax, 1
	int 	0x80

toUpper:
        push    ebp
        mov     ebp, esp
        push    esi

        mov     esi, [ebp + 8]
        xor     eax, eax
        
        .iter:
        mov     al, [esi]
	inc	esi
        cmp     al, 0xa       	; if null
        jz      .done
	cmp	al, 'a'
	jl	.iter
	cmp	al, 'z'
	jg	.iter
	xor	al, 0x20
	dec	esi
        mov     [esi], al
        inc     esi
        jmp     .iter
        
        .done:
        mov     eax, [ebp + 8]
        pop     esi
        mov     esp, ebp
        pop     ebp
        ret	4

atoi:
	push	ebp
	mov	ebp, esp
	push	esi
	push	edx
	push	ebx

	mov	esi, [ebp + 8]
	xor	eax, eax
	mov	ebx, 10
	
	.iter:
	mul	ebx
	mov	dl, [esi]
	inc	esi
	cmp	dl, 0xa
	jz	.done
	and	dl, 0xf
	add	eax, edx
	jmp	.iter

	.done:
	xor	edx, edx	
	div	ebx
	pop	ebx
	pop	edx
	pop	esi
	mov	esp, ebp
	pop	ebp	
	ret	4

itoa:
	push	ebp	
	mov	ebp, esp
	push	edi
	push	edx
	push	ebx

	mov	edi, [ebp + 0xc]
	add	edi, 9
	mov	byte [edi], 0xa
	dec	edi
	mov	eax, [ebp + 8]
	mov	ebx, 10
	
	.iter:
	xor	edx, edx
	div	ebx
	or	dl, 30h
	mov	[edi], dl
	dec	edi
	test	eax, eax
	jz	.done
	jmp	.iter

	.done:
	add	edi, 9
	sub	edi, [ebp + 0xc]
	mov	eax, edi
	pop	ebx
	pop	edx
	pop	edi
	mov	esp, ebp
	pop	ebp
	ret	8

