section .bss	; uninitialized data
	buf	resb	32

section .text
global _start
_start:
	mov	edx, 32		; read max 32 bytes
	mov	ecx, buf	; addr buf
	mov	ebx, 0		; STDIN
	mov	eax, 3		; SYS_READ
	int 	0x80

	push	eax		; eax holds number of bytes read
	mov	ecx, buf	; addr buf
	pop	edx		; pop to edx register
	mov	ebx, 1		; STDOUT
	mov	eax, 4		; SYS_WRITE
	int	0x80

	mov	ebx, 0
	mov 	eax, 1		; SYS_EXIT
	int 	0x80
