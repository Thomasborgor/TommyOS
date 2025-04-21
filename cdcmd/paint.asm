[BITS 16]
[ORG 32768]         ; The bootloader code starts at 0x7C00
mov [bootdev], dl
mov [SecsPerTrack], ax
mov [Sides], bx
cmp byte [si], 255
je no_filename
mov ah, 0x00     ; BIOS video service
mov al, 0x13     ; Video mode 13h (320x200, 256 colors)
int 0x10         ; BIOS interrupt for video services
mov di, filename_buf2
save_filename:
	lodsb
	cmp al, 0
	je no_more_chars
	stosb
	cmp di, 12
	jl save_filename
no_more_chars:

mov ax, filename_buf2
call os_file_exists
jc afterdjdjdj
mov ax, filename_buf2
call os_print_pcx
mov ax, 2000h			; Reset ES back to original value
mov es, ax
mov ax, filename_buf2
call os_remove_file
jmp after_the_thingy
no_filename: 
mov si, no_file_name
call os_print_string
ret
no_file_name db 'No input file specified.', 0

afterdjdjdj:
mov ah, 0x00     ;This might seem weird, but it is correct because if there is no existing file, it prints rando data and we just clear that out!
mov al, 0x13     
int 0x10         
after_the_thingy:

mov ah, 01h           ; Function 01h: Set Cursor Shape
mov ch, 06h           ; Standard start scanline
mov cl, 07h           ; Standard end scanline
int 10h               ; BIOS video interrupt

jmp start
mov cx, 10
mov dx, 10
mov word [temp_cx], 100
mov word [temp_dx], 50
	
draw_rect:
	push dx
	reset_cx:
	push cx
	draw_row:
		cmp word cx, [temp_cx]
		je inc_row
		inc cx
		mov ah, 0x0C
		mov bh, 0
		mov al, 4
		int 0x10
		jmp draw_row
	inc_row:
		pop cx
		cmp word dx, [temp_dx]
		je end_rect
		inc dx
		jmp reset_cx

	end_rect:
		pop dx

start:
    ; Set video mode 320x200 (256 colors)

    ; Initialize cursor position (starting in the middle of the screen)
    mov cx, 0      ; X position
    mov dx, 0      ; Y position
    mov byte [color], 0x0F  ; Initialize color to white (0x0F)

    ; Draw initial dot
    call draw_dot


main_loop:
    ; Wait for a keypress
	inc byte [color]
	cmp byte [color], 0x10
	je no_black
	drawing_dot:
	call draw_dot
	dec byte [color]
	thingasdasdasd:
	xor ah, ah
	int 0x16
    cmp ah, 0x48     ; Check if Up arrow (0x48)
    je move_up
    cmp ah, 0x50     ; Check if Down arrow (0x50)
    je move_down
    cmp ah, 0x4B     ; Check if Left arrow (0x4B)
    je move_left
    cmp ah, 0x4D     ; Check if Right arrow (0x4D)
    je move_right

    cmp ah, 0x49     ; PageUp key to increase color
    je color_up
    cmp ah, 0x51     ; PageDown key to decrease color
    je color_down
	
	cmp ah, 0x01
	je alt
	cmp al, '~'
	je save_file_pcx

	
    jmp main_loop    ; Loop back to wait for another keypress
	
no_black:
	sub byte [color], 2
	call draw_dot
	inc byte [color]
	jmp thingasdasdasd ;i was bored okay
	
save_file_pcx:
	;right now I just need to test something
	call draw_dot
	push ds
	push es
mov ax, 0xa000        ; DS = video segment
    mov ds, ax
    mov ax, 0x2000        ; ES = file buffer segment
    mov es, ax
    mov di, file_buffer
    add di, 80h           ; skip header area
    mov si, 0             ; start of image data
    mov cx, 64000           ; CX = Total pixels to encode
    xor dl, dl              ; DL = Run length counter
    mov bl, ds:[si]         ; BL = Current pixel value

get_sample_RLE:
    dec cx
    jz flush_and_exit       ; If cx == 0, write last run and exit

    inc si
    mov al, ds:[si]         ; Read next pixel
    inc dl                  ; Increment run length

    cmp al, bl              ; Is this pixel same as last?
    je check_run_length     ; If yes, continue the run

    ; --- New Pixel Encountered! Store the previous run ---
    cmp dl, 1
    je store_single_byte    ; If single pixel, store without RLE header

    ; Store RLE encoded run
    or dl, 0xC0
    mov byte es:[di], dl
    inc di
    mov byte es:[di], bl
    inc di

    xor dl, dl              ; Reset run counter
    mov bl, al              ; Update current pixel
    jmp get_sample_RLE

check_run_length:
    cmp dl, 63              ; Has run length exceeded max (63)?
    jne get_sample_RLE      ; If not, continue accumulating

    ; Store full run (max 63 pixels)
    or dl, 0xC0
    mov byte es:[di], dl
    inc di
    mov byte es:[di], bl
    inc di

    xor dl, dl              ; Reset run length
    jmp get_sample_RLE

store_single_byte:
    mov byte es:[di], bl
    inc di
    xor dl, dl              ; Reset run length
    mov bl, al
    jmp get_sample_RLE

flush_and_exit:
    ; Final byte or run needs to be written
    cmp dl, 0
    je exit_loop

    cmp dl, 1
    je store_last_byte

    ; Store the final run
    or dl, 0xC0
    mov byte es:[di], dl
    inc di
    mov byte es:[di], bl
    inc di
    jmp exit_loop

store_last_byte:
    mov byte es:[di], bl
    inc di

exit_loop:
	pop es ;file starts at 11080
	pop ds
	add di, 2

    mov cx, 768             ; 256 colors
    mov si, sample_palette  ; Address of sample palette

write_palette:
    mov al, ds:[si]
	mov es:[di], al
	inc si
	inc di
    loop write_palette      ; Repeat for all 256 colors
	
	
	mov ax, 0x0003
	int 0x10
	push di
	mov ax, filename_buf2
	call custom_create_file
	pop di
	jc error
	mov cx, di;DO THIS================================
	sub cx, file_buffer
	mov bx, file_buffer
	mov ax, filename_buf2
	call os_write_file
	jc error
	ret
	

filename_buf2 times 12 db 0


sample_palette:
	db 00, 00, 00, ;black
	db 00, 00, 192,  ;blue
	db 00, 192, 00, ;green
	db 00, 192, 192, ;cyan
	db 192, 00, 00, ;red
	db 192, 00, 192, ;magenta
	db 200, 150, 00, ;brown
	db 0xc0, 0xc0, 0xc0, ;light gray
	db 80, 80, 80, ;dark grey
	db 00, 00, 255,  ;light blue
	db 00, 255, 00, ;light green 
	db 00, 0xff, 255, ;light cyan 
	db 255, 00, 00, ;light red
	db 0xff, 00, 0xff, ;light magenta 
	db 192, 192, 0,;yellow
	db 0xff, 0xff, 0xff ;white
	times 720 db 0
	
error:
    mov ax, 0x0003
    int 0x10
    mov ax, 0x0e01
    int 0x10
    jmp $
	
alt:
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
	mov ah, 0x00
	mov al, 0x02
	int 0x10
	mov si, welcome
	call print
	ret

color_up:
    cmp byte [color], 0x0F  ; If color is already white, reset it
    je reset_color_up
    inc byte [color]         ; Else, increment color
    call draw_dot            ; Draw the new dot
    jmp main_loop

color_down:
    cmp byte [color], 0x00  ; If color is already black, reset it
    je reset_color_down
    dec byte [color]         ; Else, decrement color
    call draw_dot            ; Draw the new dot
    jmp main_loop

reset_color_up:
    mov byte [color], 0x00   ; Reset color to black
    call draw_dot            ; Draw the new dot
    jmp main_loop

reset_color_down:
    mov byte [color], 0x0F   ; Reset color to white
    call draw_dot            ; Draw the new dot
    jmp main_loop

move_up:
    cmp dx, 0               ; Check if we're at the top of the screen
    jle main_loop            ; If yes, don't move
	call draw_dot            ; Draw the dot at the new position
    dec dx	               ; Move the cursor up
    jmp main_loop

move_down:
    cmp dx, 199              ; Check if we're at the bottom of the screen (199 is the max Y)
    jge main_loop            ; If yes, don't move
    call draw_dot            ; Draw the dot at the new position
    inc dx                ; Move the cursor down
    jmp main_loop

move_left:
    cmp cx, 0                ; Check if we're at the left edge
    je adjust_left            ; If yes, don't move
	call draw_dot            ; Draw the dot at the new position
    dec cx               ; Move the cursor left
    jmp main_loop

move_right:
    cmp cx, 319              ; Check if we're near the right edge
    jge adjust_right         ; If yes, go to adjustment
    call draw_dot            ; Draw the dot at the new position
    inc cx                ; Move the cursor right
    jmp main_loop

adjust_right:
    mov cx, 0
    jmp main_loop
	
adjust_left:
	mov cx, 319
	jmp main_loop

; Subroutine to draw the current dot with the current color
draw_dot:
    mov ah, 0x0C             ; BIOS function to write pixel
    mov al, [color]          ; Use the color stored in [color]
    mov bh, 0x00             ; Page number (always 0 in mode 13h)

    ; Check if cx and dx are within bounds before drawing
    cmp cx, 319              ; If cx is greater than 319, skip drawing
    jg skip_draw
    cmp dx, 199              ; If dx is greater than 199, skip drawing
    jg skip_draw

    ; Draw a 3x3 dot
    int 0x10
skip_draw:
    ret
	
print:
    ; Print a null-terminated string pointed to by SI
    pusha
print_char:
    lodsb                   ; Load byte at SI into AL, increment SI
    cmp al, 0               ; Check if we've reached the null terminator
    je .done_printing       ; If null terminator, exit
    mov ah, 0x0E            ; BIOS teletype function (int 0x10, AH = 0x0E)
    int 0x10                ; Print the character in AL
    jmp print_char          ; Repeat for the next character

.done_printing:
    popa
    ret                     ; Return from the function

color db 0x0F                ; Variable to store current color
welcome db 'Welcome back!', 10, 13, 0
temp_cx dw 0
temp_dx dw 0
temp_byte db 0
file_buffer times 10000 db 0

%include "./extra/functions.asm"
disk_buffer db 24576
dirlist:
delay: