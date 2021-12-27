%include 	'func.asm'
section .bss
	a	resb	10
	b	resb	10
	s	resb	10

section .text
global _start
_start:
	push	10
	push	a
	call	readConsole
	push	10
	push	b	
	call	readConsole

	push	a
	call	atoi
	mov	edx, eax
	push	b
	call	atoi
	add	eax, edx
	push	s
	push	eax
	call	itoa
	
	push	eax
	push	s
	call	writeConsole
	
	call	exitProcess
