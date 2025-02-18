
mov si, message
print_loop:
	mov ah, 0x0e
	lodsb
	cmp al, 0
	je end
	int 0x10
	jmp print_loop
end:
jmp end


message db 'hi', 0