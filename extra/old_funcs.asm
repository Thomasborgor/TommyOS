print_bcd:
    mov ah, 0x0E          ; BIOS teletype function
    mov bl, al            ; Copy original BCD value
    shr al, 4             ; Get the upper nibble (tens)
    add al, '0'           ; Convert to ASCII
    int 0x10              ; Print tens digit
    mov al, bl            ; Get original BCD value back
    and al, 0x0F          ; Mask out upper nibble, get units
    add al, '0'           ; Convert to ASCII
    int 0x10              ; Print units digit
	mov al, ':'
	int 0x10
    ret
	
print_time:
	mov ah, 0x0E
	mov al, 0x0a
	int 0x10
	mov al, 0x0d
	int 0x10
	mov ah, 0x02
	int 0x1A

	mov al, ch
	call print_bcd

	mov al, cl
	call print_bcd

	mov al, dh
	call print_bcd
	
	mov si, backspace_msg
	call print
	jmp second
	
print_date:
	mov ah, 0x0E
	mov al, 0x0a
	int 0x10
	mov al, 0x0d
	int 0x10
    ; display current time in hh:mm:ss format
    mov ah, 0x04
    int 0x1a  ; bios - get time
    mov al, dh
    call print_bcd
    mov al, dl
    call print_bcd
    mov al, cl
    call print_bcd
	mov si, backspace_msg
	call print
    jmp second
	
clear:
	pusha
	mov ah, 0x03
	mov bh, 0x00 
	int 0x10
	
	mov ah, 0x02
	mov dh, 0
	mov dl, 0
	int 0x10

    mov ax, 0x0700  ; function 07, AL=0 means scroll whole window
    mov bh, 0x07    ; character attribute = white on black
    mov cx, 0x0000  ; row = 0, col = 0
    mov dx, 0x184f  ; row = 24 (0x18), col = 79 (0x4f)
    int 0x10        ; call BIOS video interrupt

    popa
	ret
	
	