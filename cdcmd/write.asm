[bits 16]
[org 32768]
mov [buffer], word si
mov [SecsPerTrack], ax
mov [Sides], bx
mov [bootdev], dl
cmp byte [si], 0xFF
je no_input_file
mov ax, si
call os_file_exists
jnc yeah

create_file:
mov ax, [buffer]
call custom_create_file

mov word [offset_counter], 43007
yeah:
mov si, [buffer]
mov di, test_txt
save_test_loop:
	lodsb
	cmp al, 0
	je done_storing
	stosb
	jmp save_test_loop
done_storing:
mov byte [di], 0



call clear
mov ah, 0x05

mov al, 0
int 0x10
mov ah, 0x02
mov dx, 0x0100
int 0x10
mov ax, test_txt
mov cx, 43008			; Load file ?? after program start
	call os_load_file


	; Now BX contains the number of bytes in the file, so let's add
	; the load offset to get the last byte of the file in RAM

	add bx, 43008
	mov [end_of_file], bx

	ready:
	mov cx, 0			; Lines to skip when rendering
	mov word [skiplines], 0
		pusha
	mov ah, 5
	mov al, [current_page]
	int 0x10
	mov dh, 1			; Move cursor to near top
	mov dl, 0
	mov bh, [current_page]
	call os_move_cursor

	popa

txt_start:
    mov si, 43008               ; Start of text data (file in memory)
    mov al, 0                   ; Initialize current page
    mov [current_page], al      ; Start at page 0
    mov dh, 1                  ; Start at the first row (line 0)
    mov dl, 0                   ; Start at the first column
    mov bh, 0                   ; Start on page 0

print_file:
    lodsb                       ; Load a character from the file
    cmp al, 0                   ; Check if end of file
    je finished

    cmp al, 0x0A                ; Check if newline character
    jne print_char2

    ; Handle newline: move to the next line
    call handle_newline
    jmp print_file

print_char2:
    ; Print the character to the screen
    mov ah, 0x0E                ; BIOS teletype function

    int 0x10

    ; Advance cursor position
    inc dl                      ; Move to the next column
    cmp dl, 80                  ; Check if we reached the end of the line
    jne print_file

    ; Handle line wrap (go to the next line)
    call handle_newline
    jmp print_file

handle_newline:
    ; Move to the next row
    inc dh                      ; Move cursor down one line
    cmp dh, 24                  ; Check if we reached the bottom of the screen
    jle reset_cursor            ; If not, just reset column to 0

    ; Move to the next page
    inc byte [current_page]     ; Increment current page
    cmp byte [current_page], 8  ; Limit to 8 pages
    ja finished                 ; End if no more pages

    mov ah, 0x05                ; BIOS: Set active display page
    mov al, [current_page]
    int 0x10

    ; Reset cursor to the top-left of the new page
    xor dh, dh                  ; Row 0
    xor dl, dl                  ; Column 0
    mov ah, 0x02                ; BIOS: Set cursor position
    mov bh, [current_page]
    int 0x10
    ret

reset_cursor:
    xor dl, dl                  ; Reset column to 0
    mov ah, 0x02                ; BIOS: Set cursor position
    mov bh, [current_page]
    int 0x10
    ret

no_input_file:
	mov si, no_file
	call print
	ret
	
	
no_file db 'No input file specified.', 0


different_finished:
call clear

finished:

mov ah, 5
mov al, 0
int 0x10
mov byte [current_page], 0

main:
	xor dx, dx
	mov ah, 0x02
	mov bh, [current_page]
	int 0x10
	mov si, write_msg
	call print
	mov ah, 2
	mov bh, [current_page]
	mov dh, 1
	mov dl, 0
	int 0x10
	
key_loop:
	mov ah, 0x02        ; Get current cursor position
	mov bh, [current_page]
	int 0x10

	; Check if cursor is at the bottom-right corner (row 0x18, col 0x4F)
	cmp dh, 0x18
	jne check_cursor      ; Not at the last row, continue
	cmp dl, 0x4F
	jne check_cursor      ; Not at the last column, continue
	jmp block_keys        ; At bottom-right, block key input except arrows

check_cursor:
	xor ah, ah
	mov ah, 0x00
	int 0x16  ; Wait for keypress
		
	; Handle key inputs
	cmp al, 0x08  ; Backspace
	je backspace
		
	cmp al, 0x0D  ; Enter key
	je enter_key
		
	cmp ah, 0x48  ; Up arrow
	je up_key
		
	cmp ah, 0x50  ; Down arrow
	je down_key
		
	cmp ah, 0x4B  ; Left arrow
	je left_key
		
	cmp ah, 0x4D  ; Right arrow
	je right_key
	
	cmp al, '~'
	je write_file
		
	cmp ah, 0x01  ; Alt key (example functionality)
	je alt
	
	cmp al, 3
	je clear_page


	; Default: print character
	call print_char_and_check_wrap
	jmp key_loop
	
clear_page:
	call clear
	jmp check_cursor

	
write_file:



xor dx, dx
mov bh, 7
mov ah, 2
int 0x10
mov byte [current_page], 7
mov byte [final_page], 7
mov ah, 5
mov al, 7
int 0x10

check_loop3:
	xor dx, dx
	mov bh, [current_page]
	mov ah, 2
	int 0x10
	call check_space_vert
	jnc inc_final_page
	jmp done_checking
	
inc_final_page:
	dec byte [current_page]
	dec byte [final_page]
	mov ah, 5
	mov al, [final_page]
	int 0x10
	jmp check_loop3

done_checking:
mov ah, 5
mov al, 0;set first page
int 0x10
mov byte [current_page], 0
mov ah, 2
mov bh, 00h
mov dx, 0x0100
int 0x10

lea di, [write_buffer] ; Load address of write_buffer into DI

start_checking:
    ;mov ax, 00h
    ;int 16h
    ;we have already check that the pages after this one is blank.
    ;we have set the page to the first one.

    mov ah, 0x08          ; Read character at cursor position
    mov bh, [current_page]
    int 0x10
    stosb                 ; Store character into write_buffer

    mov ah, 0x03          ; Get current cursor position
    mov bh, [current_page]
    int 0x10

    mov ah, 0x02          ; Move cursor to the right
    mov bh, [current_page]
    inc dl
    int 0x10

    call check_all_space
    jc start_checking      ; Skip row if it contains only spaces

    mov ah, 0x03          ; Get current cursor position again
    mov bh, [current_page]
    int 0x10

    cmp dh, 24            ; Check if we're at the last row
    jne start_checking
    call check_all_space
    jnc end               ; End processing if all rows are checked
	
	special_loop:
		mov ah, 0x08
		mov bh, [current_page]
		int 0x10
		stosb
		 mov ah, 0x03          ; Get current cursor position
		mov bh, [current_page]
		int 0x10

		mov ah, 0x02          ; Move cursor to the right
		mov bh, [current_page]
		inc dl
		int 0x10
		call check_all_space
		jnc inc_page
		jmp special_loop
	
		

end:
    mov ax, test_txt    ; Placeholder commands
    call os_remove_file

    mov ax, write_buffer
    call os_string_length
	
    mov cx, ax
    mov ax, test_txt
    mov bx, write_buffer
    call os_write_file
	jc error
	mov ax, 0x0500
	mov byte  [current_page], 0
	clear_all_pages:
		int 0x10
		call clear
		inc byte [current_page]
		inc al
		cmp al, 7
		jng clear_all_pages
    mov ah, 5             ; Ignore placeholder commands
    mov al, 0
    int 0x10
    xor dx, dx
    mov ah, 2
    mov bh, 0
    int 0x10
    call clear

    mov si, welcome
    call print

    ret
error:
	mov ax, 0x0e41
	int 0x10
	ret
	
inc_page:
	inc byte [current_page]
	mov ah, 5
	mov al, [current_page]
	int 0x10
	xor dx, dx
	mov bh, [current_page]
	mov ah, 2
	int 0x10
	jmp start_checking

reset_screen: ;ign
    mov ah, 5
    mov al, 00h
    mov [current_page], al
    int 0x10
    mov ax, 0x0e01
    int 0x10
    jmp $

do_the_space_check:
    call check_all_space
    jnc start_checking

    mov byte [di], 32
    inc di
    jmp start_checking

check_space_vert:
    pusha
    mov bl, 25
    sub bl, dh
    xor bh, bh
    mov cx, bx
check_loop2:
    call check_all_space
    jc failed_all_space
    mov ah, 0x08
    mov bh, [current_page]
    int 0x10
    cmp al, ' '
    jne failed_all_space
    mov ah, 0x02
    mov bh, [current_page]
    int 0x10
    inc dh
    loop check_loop2
    inc byte [current_page]
    popa
    clc
    ret

check_all_space:
	mov ah, 0x03
	mov bh, [current_page]
	int 0x10
	mov [temp_dl], dl
	
    pusha
    mov bl, 79            ; Number of columns in a row
    sub bl, dl
    xor bh, bh
    mov cx, bx
check_loop:
    mov ah, 0x08          ; Read character at cursor position
    mov bh, [current_page]
    int 0x10
    cmp al, ' '           ; Compare to space
    jne failed_all_space  ; If non-space character found, exit
    mov ah, 0x02          ; Move cursor to the right
    mov bh, [current_page]
    int 0x10
    inc dl
    loop check_loop
    popa

    ; If all spaces, proceed to the next line
    mov ah, 0x02
    mov bh, [current_page]
    mov dl, 0
    inc dh
    int 0x10
    mov byte [di], 10     ; Add newline to write_buffer
    inc di
    mov byte [di], 13     ; Add carriage return to write_buffer
    inc di
    clc                   ; Clear carry flag (indicate success)
    ret
failed_all_space:
    popa
    stc                   ; Set carry flag (indicate failure)
	mov ah, 0x03
	mov bh, [current_page]
	int 0x10
	mov ah, 0x02
	mov bh, [current_page]
	mov dl, [temp_dl]
	int 0x10
    ret



temp_dl db 0

block_keys:
	; Only allow arrow keys when at bottom-right
	xor ah, ah
	mov ah, 0x00
	int 0x16  ; Wait for keypress
	
	cmp al, 0x08
	je backspace
	
	cmp ah, 0x48  ; Up arrow
	je up_key
		
	cmp ah, 0x50  ; Down arrow
	je down_key
		
	cmp ah, 0x4B  ; Left arrow
	je left_key
		
	cmp ah, 0x4D  ; Right arrow
	je right_key
	
	cmp al, '~'
	je write_file
	


	; If not an arrow key, ignore and return to key loop
	jmp block_keys
	
handle_tab:
	mov ah, 0x05
	mov al, 0
	int 0x10
	ret


alt:
	mov ax, 0x0500
	int 0x10
	mov byte [current_page], 0
	call clear
	mov si, welcome
	call print
	ret
		
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
    je key_loop                 ; Already at the first page, no further scrolling

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
    jmp key_loop

move_cursor_up:
    ; Move cursor up within the page
    dec dh
    mov ah, 0x02
    mov bh, [current_page]
    int 0x10
    jmp key_loop

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
    je key_loop                 ; Already at the last page, no further scrolling

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
    jmp key_loop

move_cursor_down:
    ; Move cursor down within the page
    inc dh
    mov ah, 0x02
    mov bh, [current_page]
    int 0x10
    jmp key_loop

right_key:
	mov ah, 0x03
	mov bh, [current_page]
	int 0x10
	mov ah, 0x02
	int 0x10
	cmp dl, 0x4F  ; Prevent moving past the last column (79th column)
	je key_loop
	inc dl
	int 0x10
	jmp key_loop
	
left_key:
	mov ah, 0x03
	mov bh, [current_page]
	int 0x10
	mov ah, 0x02
	int 0x10
	cmp dl, 0x00  ; Prevent moving before the first column
	je key_loop
	dec dl
	int 0x10
	jmp key_loop
		
enter_key:
	mov ah, 0x03
	mov bh, [current_page]
	int 0x10
	cmp dh, 24
	je key_loop
	mov ah, 0x02
	int 0x10
	inc dh
	mov dl, 0x00
	cmp dh, 0x18  ; Prevent moving past the bottom row (24th row)
	ja key_loop
	int 0x10
	jmp key_loop
	
backspace:
	mov ah, 0x02
	int 0x10
	cmp dl, 0
	je key_loop
	mov al, 0x08         ; ASCII for backspace
	mov ah, 0x0e
	int 0x10             ; Move cursor back

	; Print a space to erase the character
	mov al, 0x20         ; ASCII for space
	int 0x10             ; Print the space

	; Move cursor back again
	mov al, 0x08         ; ASCII for backspace
	int 0x10             ; Move cursor back again
	mov ah, 0x02
	dec dl
	int 0x10
	jmp key_loop
	
print:
	pusha
print_char:
	lodsb                   ; Load byte at SI into AL, increment SI
	cmp al, 0               ; Check if we've reached the null terminator
	je .done_printing       ; If null terminator, exit
	call print_char_and_check_wrap
	jmp print_char          ; Repeat for the next character

.done_printing:
	popa
	ret                     ; Return from the function

; Print a character and check for line wrap
print_char_and_check_wrap:
    mov ah, 0x0E            ; BIOS teletype function (int 0x10, AH = 0x0E)
    int 0x10                ; Print the character in AL
    ; Get cursor position
    mov ah, 0x03
    mov bh, [current_page]
    int 0x10
    ; If cursor reaches the last column, stay there and prevent wrapping
    cmp dl, 0x4F
    jne .not_end_of_line
    ; If we're at the last column, prevent the cursor from wrapping
    cmp dh, 0x18            ; Check if at the bottom row
    je .prevent_wrap        ; If bottom row, prevent wrapping

.not_end_of_line:
    ret

.prevent_wrap:
    ; Stay at the last position (0x184F), don't wrap
    mov dl, 0x4F
    ret
	
clear:
	pusha
	mov ah, 0x03
	mov bh, [current_page]
	int 0x10
	
	mov ah, 0x02
	mov bh, [current_page]
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
	
	
%include "./extra/functions.asm"
prompt db '> ', 0
write_msg db "Writing Editor", 10, 13, 0
newline db 10, 13, 0
welcome db 'Welcome back!', 10, 13, 0
test_txt times 12 db 0
skiplines dw 0
disk_buffer equ 24576
dirlist dw 1024
write_buffer times 10000 db 0 ;large
current_page db 0
offset_counter dw 0
end_of_file dw 0
final_page db 0
buffer: