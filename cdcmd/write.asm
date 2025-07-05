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



mov cx, bx

mov ax, 0xb800
mov es, ax
mov ax, 0x3000
mov ds, ax

mov si, 0
mov di, 160

populate_video_mem:
    lodsb               ; get byte from [DS:SI] into AL
    cmp al, 13          ; is it carriage return?
    je do_a_newline

    stosb               ; store AL at ES:DI (char)
    inc di              ; skip color byte
    loop populate_video_mem
    jmp prepare_the_screen

do_a_newline:
    mov bx, 160         ; bytes per line
    mov ax, di
    xor dx, dx
    div bx              ; get current line number in AX
    inc ax              ; go to next line
    mul bx              ; AX *= 160
    mov di, ax          ; DI = start of next line
    inc si              ; skip LF (optional depending on input)
    dec cx              ; adjust loop count manually
    jmp populate_video_mem
create_new_file:
	mov ax, test_txt
	call custom_create_file
	mov ax, 0xb800
	mov es, ax

prepare_the_screen:
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
		
		;im not adding arrow keys yet
		mov ah, 0eh
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
mov ax, 0x2000
mov ds, ax
mov di, write_buffer

mov si, 160
write_file_get_loop:
    push di                   ; Save di (write_buffer position)
    mov di, buffer_buffer     ; di = output buffer
    push si                   ; Save si (screen offset)
    call get_trimmed_row_into_buffer
    pop si                    ; Restore si
    
    pop di                    ; Restore write_buffer position
    call put_that_buffer_in_write_buffer

    add si, 160
    cmp si, 160*25
    jle write_file_get_loop

call trim_crlf_from_write_buffer

call clear

mov ax, 0x2000
mov es, ax
mov ds, ax

mov ax, test_txt
call os_remove_file

mov ax, write_buffer
call find_string_length

mov cx, ax
mov bx, write_buffer
mov ax, test_txt
call os_write_file

retf

	
	
; In: si = screen offset, di = output buffer
; Out: buffer_buffer contains trimmed row + CRLF
get_trimmed_row_into_buffer:
    push cx
    push bx

    mov cx, 80
    mov bx, di               ; Save start of buffer

get_row_loop:
    mov al, [es:si]
    mov [ds:di], al
    add si, 2
    inc di
    loop get_row_loop

; Trim trailing spaces
    dec di
trim_loop:
    cmp di, bx               ; di >= start of buffer?
    jb trim_done
    cmp byte [ds:di], 32
    jne trim_done
    dec di
    jmp trim_loop

trim_done:
    inc di
    mov byte [ds:di], 0x0D
    inc di
    mov byte [ds:di], 0x0A
    inc di
    mov byte [ds:di], 0

    pop bx
    pop cx
    ret
	
; In: di = write_buffer position, buffer_buffer contains trimmed row
put_that_buffer_in_write_buffer:
    push si
    push bx

    mov si, buffer_buffer

copy_loop:
    mov al, [ds:si]
    cmp al, 0
    je copy_done
    mov [ds:di], al
    inc si
    inc di
    jmp copy_loop

copy_done:
    pop bx
    pop si
    ret
	
trim_crlf_from_write_buffer:
    push si
    push di

    mov si, write_buffer

; Find null terminator
find_end:
    mov al, [ds:si]
    cmp al, 0
    je found_end
    inc si
    jmp find_end

found_end:
    dec si                ; Point to last character before null

trim_loop2:
    cmp si, write_buffer
    jb finish_trim        ; Avoid underflow beyond buffer start

    cmp byte [ds:si], 0x0A
    jne finish_trim       ; No LF found, stop
    mov byte [ds:si], 0   ; Erase LF

    dec si
    cmp si, write_buffer
    jb finish_trim

    cmp byte [ds:si], 0x0D
    jne finish_trim       ; No CR found, stop
    mov byte [ds:si], 0   ; Erase CR

    dec si
    jmp trim_loop2         ; Check for next CRLF pair

finish_trim:
    pop di
    pop si
    ret

	
si_offset dw 0
write_buffer_offset dw 0
	
something_went_wrong:
	mov ax, 0x0e01
	int 0x10
	jmp $
	
find_string_length: ;in ax=location of string
	mov bx, ax
	xor cx, cx
	find_length_loop:
		cmp byte [bx], 0
		je we_are_done_here
		inc cx
		inc bx
		jmp find_length_loop
	we_are_done_here:
		mov ax, cx
		ret
		

sample_data db 'blah blah blah sample data ', 10, 13, 'test test', 0
	
	
buffer_buffer times 81 db 0
temp_dl dw 0
temp_dh db 0
	
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