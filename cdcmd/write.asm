[bits 16]

mov cx, 0x2000
mov es, cx
mov [es:SecsPerTrack], ax ;why not prefixed with ES:? because then I would have to change pretty much all of functions.asm.
mov [es:Sides], bx
mov [es:bootdev], dl

mov di, test_txt
save_____that______filename:
	lodsb
	cmp al, 0
	je donasd
	mov [es:di], al
	inc di
	jmp save_____that______filename
donasd:
mov [es:di], byte 0
mov ax, 0x2000
mov ds, ax
mov es, ax


call clear
mov ax, test_txt
call os_file_exists
jc create_new_file



mov cx, 0x3000
mov ax, test_txt
call os_load_file



mov cx, bx            ; BX = file size
mov ax, 0xb800
mov es, ax
mov ax, 0x3000
mov ds, ax
mov si, 0
mov di, 160           ; start at line 1 (skip header)
xor bp, bp            ; page counter

populate_video_mem:
    lodsb
    cmp al, 0dh
    je parse_newline

    stosb
    inc di

    ; Check for end of page (4000 bytes per page)
    cmp di, 4000
    jb continue_loop

    ; Switch to next page
    inc bp
    mov ax, bp
    xor dx, dx
    mov bx, 256
    mul bx
    add ax, 0xb800
    mov es, ax
    xor di, di

continue_loop:
    loop populate_video_mem
    jmp prepare_the_screen

parse_newline:
    ; Calculate padding to end of current line
    mov ax, di
    xor dx, dx
    mov bx, 160
    div bx
    mov ax, 160
    sub ax, dx
    add di, ax
	inc si
    ; Same page-switch logic in case line wrap hits end of screen
    cmp di, 4000
    jb continue_loop

    inc bp
    mov ax, bp
    xor dx, dx
    mov bx, 256
    mul bx
    add ax, 0xb800
    mov es, ax
    xor di, di
    jmp continue_loop


create_new_file:
	mov ax, test_txt
	call custom_create_file
	

prepare_the_screen:
	mov ax, 0xb800
	mov es, ax
	mov ax, 0x2000
	mov ds, ax
	mov di, 0
	mov si, write_msg
	mov cx, 14
	write_welcome:
		lodsb
		stosb
		inc di;skib attrib byte
		loop write_welcome
	mov ax, 0x2000
	mov es, ax
	mov ds, ax
	mov ax, 0x0500 ;set page to 1
	int 0x10
	mov ah, 0x02
	mov bh, 0
	mov dx, 0x0100
	int 0x10
	;we have set ds and es properly, so now we just create the keystroke + printout loop!
	
	get_keystroke:
		xor ah, ah
		int 16h
		;al is the key (most of the time)
		cmp al, 8
		je backspace_do
		
		cmp al, 13
		je enter_do
		
		cmp al, '~'
		je write_file
		
		cmp ah, 0x48  ; Up arrow
		je up_key
		
		cmp ah, 0x50  ; Down arrow
		je down_key
		
		cmp ah, 0x4B  ; Left arrow
		je left_key
		
		cmp ah, 0x4D  ; Right arrow
		je right_key
		
		;im not adding arrow keys yet
		mov ah, 0eh
		int 0x10
		jmp get_keystroke
	
	up_key:
    ; Get cursor position
    mov ah, 0x03
    mov bh, [current_page]
    int 0x10

    ; Check if at the top of the current page
    cmp dh, 0x00
    jne move_cursor_up

    ; Check if there is a previous page
    cmp byte [current_page], 0
    je get_keystroke                 ; Already at the first page, no further scrolling

    ; Move to the previous page
    dec byte [current_page]
    mov ah, 0x05                ; Set active display page
    mov al, [current_page]
    int 0x10

    ; Move cursor to the last line of the new page
    mov dh, 24
    mov dl, 0
    mov ah, 0x02
    mov bh, [current_page]
    int 0x10
    jmp get_keystroke

move_cursor_up:
    ; Move cursor up within the page
    dec dh
    mov ah, 0x02
    mov bh, [current_page]
    int 0x10
    jmp get_keystroke

down_key:
    ; Get cursor position
    mov ah, 0x03
    mov bh, [current_page]
    int 0x10

    ; Check if at the bottom of the current page
    cmp dh, 24
    jne move_cursor_down

    ; Check if there is a next page
    cmp byte [current_page], 6 ;sneaky leaving the last page
    je get_keystroke                 ; Already at the last page, no further scrolling

    ; Move to the next page
    inc byte [current_page]
    mov ah, 0x05                ; Set active display page
    mov al, [current_page]
    int 0x10

    ; Move cursor to the top of the new page
    mov dh, 0
    mov dl, 0
    mov ah, 0x02
    mov bh, [current_page]
    int 0x10
    jmp get_keystroke

move_cursor_down:
    ; Move cursor down within the page
    inc dh
    mov ah, 0x02
    mov bh, [current_page]
    int 0x10
    jmp get_keystroke

right_key:
	mov ah, 0x03
	mov bh, [current_page]
	int 0x10
	mov ah, 0x02
	int 0x10
	cmp dl, 0x4F  ; Prevent moving past the last column (79th column)
	je get_keystroke
	inc dl
	int 0x10
	jmp get_keystroke
	
left_key:
	mov ah, 0x03
	mov bh, [current_page]
	int 0x10
	mov ah, 0x02
	int 0x10
	cmp dl, 0x00  ; Prevent moving before the first column
	je get_keystroke
	dec dl
	int 0x10
	jmp get_keystroke
	

	backspace_do:
		call check_for_left_side_cursor
		jc get_keystroke ;bad cursor placement (no backspacing to the left side of the screen)
		
		mov si, backspace_msg
		call print
		
		jmp get_keystroke
		
	enter_do:
		call check_for_lowest_row
		jc get_keystroke
		
		mov si, enter_msg
		call print

		jmp get_keystroke
		
enter_msg db 10, 13, 0


check_for_lowest_row:
	mov ah, 0x03
	mov bh, [current_page]
	int 0x10
	cmp dh, 24 ;max row, no lower or else we will scroll and mess up stuff
	je set_carry_bit_ret
	
	jmp no_carry_bit
	
		
check_for_left_side_cursor:
	mov ah, 0x03
	mov bh, [current_page]
	int 0x10
	cmp dl, 0
	je set_carry_bit_ret
	no_carry_bit:
	clc
	ret
	
	set_carry_bit_ret:
		stc
		ret

write_file:
    mov ax, 0xb800
    mov es, ax
    mov ax, cs
    mov ds, ax
    mov byte [temp_dh], 0

    xor di, di
    mov di, write_buffer
    xor cx, cx

start_new_page:
    mov dx, 160         ; skip header line (1 row = 160 bytes)
    mov bx, 24          ; only process 24 lines per page (lines 1–24)

read_row:
    push bx
    mov si, dx
    mov cx, 80
    mov bx, buffer_buffer

read_chars:
    mov al, [es:si]
    mov [bx], al
    add si, 2
    inc bx
    loop read_chars

    ; Trim trailing spaces
    dec bx
trim_spaces:
    cmp byte [bx], ' '
    jne insert_crlf
    dec bx
    cmp bx, buffer_buffer
    jge trim_spaces

insert_crlf:
    inc bx
    mov byte [bx], 0x0D
    inc bx
    mov byte [bx], 0x0A
    inc bx

    ; Append buffer_buffer to write_buffer
    mov si, buffer_buffer
copy_line:
    mov al, [si]
    mov [di], al
    inc si
    inc di
    cmp al, 0x0A
    jne copy_line

    pop bx
    add dx, 160         ; next row
    dec bx
    jnz read_row

    ; After 24 rows, prepare next page
    inc byte [temp_dh]
    cmp byte [temp_dh], 8
    je done_reading_pages

    ; Update ES to next video page
    mov ch, 0
    mov cl, [temp_dh]
    mov ax, 0xb800
do_the_thing:
    add ax, 0x100
    loop do_the_thing
    mov es, ax
	mov dx, 0
	mov bx, 25
    jmp read_row

done_reading_pages:

remove_trailing_crlfs:
    cmp di, write_buffer
    jbe no_crlf_trim

    dec di
    cmp byte [di], 0x0A
    jne no_crlf_trim
    dec di
    cmp byte [di], 0x0D
    jne no_crlf_trim
    jmp remove_trailing_crlfs

no_crlf_trim:
    inc di
    mov byte [di], 0

    ; Clear video pages
    mov ax, 0x2000
    mov ds, ax
    mov es, ax
    mov byte [current_page], 0
    mov cx, 7
clear_loop:
    call clear
    inc byte [current_page]
    loop clear_loop
    mov ax, 0x0500
    int 0x10

    ; Write buffer to file
    mov ax, test_txt
    call os_remove_file

    mov ax, write_buffer
    call find_string_length
	;add ax, 500
    mov cx, ax
    mov ax, test_txt
    mov bx, write_buffer
    call os_write_file
    call clear
    retf

find_string_length: ;in ax=location of string
    mov bx, ax
    xor cx, cx
find_length_loop:
    cmp byte [ds:bx], 0
    je we_are_done_here
    inc cx
    inc bx
    jmp find_length_loop
we_are_done_here:
    mov ax, cx
    ret

; Data section
buffer_buffer times 81 db 0
temp_dl dw 0
temp_dh db 0
si_offset dw 0
write_buffer_offset dw 0


print:
	mov ah, 0x0e
print_char:
	lodsb                   ; Load byte at SI into AL, increment SI
	cmp al, 0               ; Check if we've reached the null terminator
	je .done_printing       ; If null terminator, exit
	int 0x10
	jmp print_char          ; Repeat for the next character

.done_printing:

	ret                     ; Return from the function

	
clear:
	pusha
	mov ah, 07h        ; Scroll up function
	mov al, 0          ; Clear entire screen (scroll all lines)
	mov bh, 0x07
	mov cx, 0000h      ; Upper left corner (row 0, col 0)
	mov dx, 184FH      ; Lower right corner (row 24, col 79)
	int 10h
	popa

	ret
	
delay:
	pusha 
	mov bx, 2
    ; Input: BX = number of ticks to wait (1 tick ≈ 55ms)
    mov ah, 00h        ; Function 00h: Get current clock count
    int 1Ah            ; Call BIOS to get tick count
    add bx, dx         ; Calculate target tick count (DX = current count)
wait_loop:
    mov ah, 00h        ; Function 00h: Get current clock count
    int 1Ah            ; Call BIOS to get tick count
    cmp dx, bx         ; Compare current tick count with target
    jb wait_loop       ; If current tick count is less than target, wait
	popa
    ret                ; Return after the delay
	



prompt db '> ', 0
write_msg db "Writing Editor", 10, 13, 0
newline db 10, 13, 0
welcome db 'Welcome back!', 10, 13, 0

test_txt times 12 db 0
skiplines dw 0
backspace_msg db 0x08, 0x20, 0x08, 0 ;go backwards, print blank (moves us forwards), go backwards, null
disk_buffer equ 24576
%include "./extra/functions.asm"


current_page db 0
offset_counter dw 0
end_of_file dw 0
final_page db 0
dirlist times 2048 db 0
write_buffer:
buffer: