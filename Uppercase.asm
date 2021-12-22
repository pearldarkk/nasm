%include 	'func.asm'
section .bss
	buf:	resb	32

section .text
global _start:
_start:
	push	32
	push	buf
	call	readConsole	
	
	push	eax
	push	buf
	call	toUpper
	push	buf
	call	writeConsole

	call	exitProcess

