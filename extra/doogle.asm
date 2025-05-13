org 0x8000

lopp:
	xor ah, ah
	int 16h
	
	push ax
	mov ah, 0x0e
	int 0x10
	mov al, 0x20
	int 0x10
	pop ax
	
	mov al, ah
	mov ah, 0x0e
	int 0x10
	mov al, 10
	int 0x10
	mov al, 13
	int 0x10
	jmp lopp
	