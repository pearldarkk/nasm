section .data
	msg	db	'Hello, World!', 0Ah

section .text
global _start
_start:
	mov	ebx, 1	; STDOUT
	mov	ecx, msg;ecx = addr buf
	mov	edx, 14	; edx = number of chars written
	mov	eax, 4	; invoke SYS_WRITE
	int 	0x80	; request software interrupt

	mov	ebx, 0
	mov	eax, 1	; invoke SYS_EXIT(ebx)
	int	0x80
