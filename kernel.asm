
bits 16

cli				; Clear interrupts
	mov ax, 0
	mov ss, ax			; Set stack segment and pointer
	mov sp, 2000h
	mov bp, 0
	sti				; Restore interrupts

	cld				; The default direction for string operations
					; will be 'up' - incrementing address in RAM

	mov ax, 2000h			; Set all segments to match where kernel is loaded
	mov ds, ax			; After this, we don't need to bother with
	mov es, ax			; segments ever again, as TommyOS and its programs
	mov fs, ax
	mov gs, ax
	
	start2:
	mov [bootdev], dl
	push es
	mov ah, 8			; Get drive parameters
	int 13h
	pop es
	and cx, 3Fh			; Maximum sector number
	mov [SecsPerTrack], cx		; Sector numbers start at 1
	movzx dx, dh			; Maximum head number
	add dx, 1			; Head numbers start at 0 - add 1 for total
	mov [Sides], dx

no_change:
	mov ax, 1003h			; Set text output with certain attributes
	mov bx, 0			; to be bright, and not blinking
	int 10h

	
main1:
	call clear
	mov ah, 0x02 ;set cursor
	mov dh, 7
	mov dl, 23
	int 0x10
	
	mov si, ascii11
	special_print_loop:
		lodsb
		cmp al, 0
		je done_special
		cmp al, 10
		je weird_newline
		mov ah, 0x0e
		int 0x10
		jmp special_print_loop
	weird_newline:
		inc byte dh
		mov dl, 23
		mov ah, 2
		int 0x10
		inc SI
	jmp special_print_loop
	done_special:
	
	mov ax, boot_pcx
	call os_file_exists
	jnc found_custom_boot
	
	mov ah, 0x02
	mov dh, 10
	mov dl, 37 ;set cursor again
	int 0x10
	mov si, msg2
	call print
	
	mov dh, 0x02
	mov dh, 10
	mov dl, 41
	int 0x10
	
	mov bx, 100 ;delay on boot
	call delay
	
	call clear
main:
	
	after_load_auto:
	xor ax, ax
	mov si, kernel_ver
	call print
	second:
		mov ah, 5
		mov al, 0
		int 0x10
		mov si, prompt
		call print
		mov cx, 40
		mov si, input_buffer
		rst_loop:
			mov byte [si], 0x00
			inc si
			loop rst_loop
		mov cx, 40
		mov si, input_buffer_copy
		rst_loop2:
			mov byte [si], 0
			inc si
			loop rst_loop2
			
		mov cx, 60
		mov al, 0
		mov di, input_buffer_copy_copy
		rep stosb
		
		mov cx, 60
		mov al, 0
		mov di, entire_command
		rep stosb
		
		mov cx, 1024
		mov si, dirlist
		rst_loop3:
			mov byte [si], 0x00
			inc si
			loop rst_loop3
		
		
		lea di, [input_buffer]
		mov word [tmp_one], 0
		input_loop:
		inc cx
		xor ah, ah
		int 0x16
		mov [di], al
		cmp al, 0x08
		je backspace
		cmp al, 0x0D
		je parse
		inc di
		mov ah, 0x0e
		int 0x10
		inc word [tmp_one]
		cmp word [tmp_one], 60
		jne input_loop
		jmp parse
backspace:
	mov bh, 0
	mov ah, 0x03
	int 0x10
	cmp dl, 2
	jle input_loop
	mov si, backspace_msg
	call print
	dec di
	jmp input_loop


parse: ;how we are going to do this:
	cmp word [tmp_one], 60
	jne do_it_thing
	dec di
	do_it_thing:
	mov byte [di], 0x00
	mov si, input_buffer
	mov di, entire_command
	call os_string_copy
	cmp byte [si], 0
	je second
	
	mov ax, input_buffer
	call os_string_uppercase
	
	mov si, input_buffer
	mov di, input_buffer_copy
	get_first_param:
		lodsb
		cmp al, 32
		je done_thingying
		cmp al, 00
		je done_thingying
		stosb
		jmp get_first_param
	done_thingying:
	
	push ax
	mov si, input_buffer
	mov di, kernel_iden_two
	mov cx, 6
	
	repe cmpsb
	je no_kernel
	pop ax
	
	mov si, ax
	
	mov di, time_str
	call compare_string
	jc print_time
	
	mov di, date_str
	call compare_string
	jc print_date
	
	mov di, cls_str
	call compare_string
	jc clear_screen
	
	mov di, size_str
	call compare_string
	jc size_wise
	
	mov di, del_str
	call compare_string
	jc del_file
	
	mov di, shutdown_str
	call compare_string
	jc shutdown_do
	
	mov di, reboot_str
	call compare_string
	jc reboot_do
	
	mov di, ren_str
	call compare_string
	jc ren_do
	
	mov di, help_str
	call compare_string
	jc help_do
	
	mov di, copy_str
	call compare_string
	jc copy_do
	
	mov di, dir_str
	call compare_string
	jc list_directory_thing
	
	mov di, echo_str
	call compare_string
	jc echo_do
	
	;get the input, go to uppercase, figure out the length, 8-length is the number of spaces we need to pad, then add BIN to the end. 
	mov di, txt_extension
	call test_extension
	jc no_run_txt
	
	mov di, tom_extension
	call test_extension
	jc no_run_tom
	
	mov di, pcx_extension
	call test_extension
	jc yes_run_pcx
	
	run_bin:
	
	mov ax, input_buffer_copy
	call os_string_length
	
	mov si, input_buffer_copy
	add si, ax
	cmp byte [si-4], '.'
	je check_file_load
	mov dword [si], '.BIN'

	check_file_load:
	mov ax, input_buffer_copy
	call os_file_exists
	jnc load_program
	
	
	mov si, input_buffer_copy
	cmp byte [si+1], ':'
	je figure_out_drive
	
	unknown_command_place:
	mov si, unkown_command
	call print
	jmp second
	
boot_pcx db 'BOOT.PCX', 0
found_custom_boot:
	call os_print_pcx
	mov bx, 100
	call delay
	mov ax, 3			; Back to text mode
	mov bx, 0
	int 10h
	mov ax, 1003h			; No blinking text!
	int 10h

	mov ax, 2000h			; Reset ES back to original value
	mov es, ax
	jmp main
	
echo_do:
	mov ax, 0x0e0a
	int 0x10
	mov al, 0dh
	int 0x10
	mov si, entire_command
	add si, 5
	call print
	jmp second
	
test_extension:
	pusha
	mov si, input_buffer_copy
	test_loop:
		lodsb
		cmp al, '.'
		jne test_loop
		mov cx, 3
		repe cmpsb
		jne not_good_extension
		stc
		popa
		ret
	not_good_extension:
		popa
		clc
		ret
	
compare_string:
	pusha
	mov si, input_buffer_copy
	compare_loop:
		lodsb
		cmp al, ' '
		je equal
		cmp al, 0
		je equal
		scasb
		jne not_equal
		jmp compare_loop
		
	not_equal:
		popa
		clc
		ret
	equal:
		mov al, [di]
		cmp [si], al
		jne not_equal
		popa
		stc
		ret

figure_out_drive:
	lodsb
	cmp al, 65
	jl unknown_command_place
	cmp al, 90
	jg unknown_command_place
	cmp al, 42h
	jle set_a
	add al, 61 ;must a letter larger then B, so C or above, then we add 61 to get 0x80
	pusha
	mov dl, al
	mov ax, 0x0201
	mov bx, sector_buffer
	mov cx, 0x0001
	mov dh, 0
	int 13h
	jc no_drive
	popa
	clc
	push ax
	mov ax, [SecsPerTrack]
	mov [temp_secspertrack], ax
	mov ax, [Sides]
	mov [temp_sides], ax
	pop ax
	push ax
	mov dl, al
	mov ah, 0x08
	int 13h
	and cx, 3Fh			; Maximum sector number
	mov [SecsPerTrack], cx	; Sector numbers start at 1
	movzx dx, dh			; Maximum head number
	add dx, 1			; Head numbers start at 0 - add 1 for total
	mov [Sides], dx
	pop ax
	mov byte [bootdev], al
	call ready_the_drive
	
	jmp second

temp_secspertrack dw 0	
temp_sides dw 0
set_a:
	sub al, 41h
	pusha
	mov dl, al
	mov ax, 0x0201
	mov bx, sector_buffer
	mov cx, 0x0001
	mov dh, 0
	int 13h
	jc no_drive
	popa
	clc
	mov word [SecsPerTrack], 18
	mov word [Sides], 2
	mov [bootdev], al
	call ready_the_drive
	jmp second


ready_the_drive:
	mov cx, 0
	mov ax, dirlist
	call os_get_file_list
	ret
	
no_drive:
	popa
	mov si, no_drive_msg
	call print

	jmp second

	
yes_run_pcx:
	mov ax, input_buffer
	call os_print_pcx
	mov ax, 0
	int 16h
	
	mov ax, 3			; Back to text mode
	mov bx, 0
	int 10h
	mov ax, 1003h			; No blinking text!
	int 10h

	mov ax, 2000h			; Reset ES back to original value
	mov es, ax
	jmp second

	
no_run_txt:
	mov si, no_txt_msg
	call print
	jmp second
	
no_run_tom:
	mov si, no_tom_msg
	call print
	jmp second
	
copy_do:
	mov word [tmp_one], 0
	mov byte [tmp_dev_one], 0
	mov si, entire_command
	add si, 5
	lodsb
	cmp al, 65
	jl unknown_command_place
	cmp al, 90
	jg unknown_command_place
	cmp al, 'B'
	jle is_a_or_b
	add al, 61
	mov [bootdev], al

	
	mov dl, al
	mov ah, 0x08
	int 13h
	jc no_drive
	and cx, 3Fh			; Maximum sector number
	mov [SecsPerTrack], cx	; Sector numbers start at 1
	movzx dx, dh			; Maximum head number
	add dx, 1			; Head numbers start at 0 - add 1 for total
	mov [Sides], dx
	call ready_the_drive
	ready_for_param_seek:
	inc si
	mov di, input_buffer_copy
	get_the_first_file:
		inc byte [tmp_dev_one]
		lodsb
		cmp al, 32
		je done_get_first_file
		stosb
		jmp get_the_first_file
		
	done_get_first_file:

	mov ax, input_buffer_copy
	mov cx, 32768
	call os_load_file
	jc no_file
	mov [tmp_one], bx
	mov si, entire_command
	add si, 7
	mov al, [tmp_dev_one]
	xor ah, ah
	add si, ax
	lodsb
	cmp al, 65
	jl unknown_command_place
	cmp al, 90
	jg unknown_command_place
	cmp al, 'B'
	jle is_a_or_b_2
	add al, 61
	mov [bootdev], al
	;call ready_the_drive
	mov dl, al
	mov ah, 0x08
	int 13h
	jc failed
	and cx, 3Fh			; Maximum sector number
	mov [SecsPerTrack], cx	; Sector numbers start at 1
	movzx dx, dh			; Maximum head number
	add dx, 1			; Head numbers start at 0 - add 1 for total
	mov [Sides], dx
	call ready_the_drive
	ready_for_param_seek2:
	inc si
	mov di, input_buffer_copy_copy
	get_the_second_file:
		lodsb
		cmp al, 0
		je done_get_last_file
		stosb
		jmp get_the_second_file
	
	done_get_last_file:
	
	
	mov cx, [tmp_one]
	mov bx, 32768
	mov ax, input_buffer_copy_copy
	;mov byte  [bootdev], 0x80
	call os_write_file
	jc failed
	
	call ready_the_drive
	
	jmp second
	
is_a_or_b:
	mov word [SecsPerTrack], 18
	mov word [Sides], 2
	cmp al, 'A'
	je is_a_one
	cmp al, 'B'
	jne failed
	mov byte [bootdev], 1
	call ready_the_drive
	jmp ready_for_param_seek
	is_a_one:
	mov byte [bootdev], 0
	call ready_the_drive
	jmp ready_for_param_seek
is_a_or_b_2:
	mov word [SecsPerTrack], 18
	mov word [Sides], 2
	cmp al, 'A'
	je is_a_one_2
	cmp al, 'B'
	jne failed
	mov byte [bootdev], 1
	call ready_the_drive
	jmp ready_for_param_seek2
	is_a_one_2:
	mov byte [bootdev], 0
	call ready_the_drive
	jmp ready_for_param_seek2
	
	
	
tmp_dev_one db 0
tmp_dev_two db 0


del_file:
	mov si, entire_command
	mov ax, 4
	add si, ax
	mov di, input_buffer_copy
	find_file_loop:
		cmp byte [si], 0
		je .done
		mov bl, [si]
		mov byte [di], bl
		inc si
		inc di
		jmp find_file_loop
	.done:
	mov ax, input_buffer_copy
	
	call os_file_exists
	jc no_file
	call os_remove_file
	jmp second
shutdown_do:
	call clear
	mov si, shutdown_msg
	call print
	jmp $
	
reboot_do:
	db 0x0ea ;nop?
	dw 0x0000
	dw 0xffff
	jmp $
	
ren_do:
	mov si, input_buffer
	add si, 4
	mov al, 0x20
	call os_string_tokenize
	mov di, input_buffer_copy
	call os_string_copy
	mov ax, si
	call os_string_length
	mov [counter], ax
	mov di, kernel_iden_two
	call compare_string
	jc no_modify_kernel
	
	mov si, input_buffer
	add word [counter], 5
	add si, [counter]
	mov al, 0x20
	call os_string_tokenize
	mov di, input_buffer_copy_copy
	call os_string_copy
	
	mov ax, input_buffer_copy
	mov bx, input_buffer_copy_copy
	call os_rename_file
	jc no_file
	jmp second


	
help_do:
	mov si, help_msg
	call print
	jmp second

size_wise:
	pusha
	mov ah, 0x0e
	mov al, 0x0a
	int 0x10
	mov al, 0x0D
	int 0x10
	popa
	mov si, input_buffer
	add si, 5 ;cheeky little boy
	mov al, 0x20
	call os_string_tokenize
	mov word [param_list], di

	mov ax, si
	call os_file_exists
	jc no_file
	
	
	call os_get_file_size
	mov ax, bx
	call os_int_to_string
	mov si, ax
	call print
	mov si, ending_size
	call print
	
	jmp second

clear_screen:
	call clear
	
	jmp second
	
no_file:
	mov si, no_file_msg
	call print
	jmp second
	
no_kernel:
	mov si, no_execute_kernel
	call print
	jmp second
	
load_program:	
	mov cx, 32768
	mov ax, input_buffer_copy
	call os_load_file
	
	mov ax, 0x0e0a
	int 0x10
	mov al, 0x0D
	int 0x10
	mov si, entire_command
	find_param:
	lodsb
	cmp al, 0
	je no_param
	cmp byte [si], ' '
	jne find_param
	
	inc si ;send first param to the program
	mov dl, [bootdev]
	mov ax, [SecsPerTrack]
	mov bx, [Sides]
	call 32768
	
	
	jmp second
	
no_param:
	mov si, buffer
	mov byte [si], 0xFF
	call 32768
	jmp second
	

failed:
	mov si, skibidi
	call print
	jmp second
	
print:
	pusha

	mov ah, 0Eh			; int 10h teletype function

.repeat:
	lodsb				; Get char from string
	cmp al, 0
	je .done			; If char is zero, end of string

	int 10h				; Otherwise, print it
	jmp .repeat			; And move on to next char

.done:
	popa
	ret
	
list_directory_thing:
	
	call list_directory
	
	
	jmp second

delay:
    ; Input: BX = number of ticks to wait (1 tick ≈ 55ms)
    mov ah, 00h        ; Function 00h: Get current clock count
    int 1Ah            ; Call BIOS to get tick count
    add bx, dx         ; Calculate target tick count (DX = current count)
wait_loop:
    mov ah, 00h        ; Function 00h: Get current clock count
    int 1Ah            ; Call BIOS to get tick count
    cmp dx, bx         ; Compare current tick count with target
    jb wait_loop       ; If current tick count is less than target, wais

    ret                ; Return after the delay
	
no_modify_kernel:
	mov si, nice_try
	call print
	jmp second

no_txt_msg db 10, 13, 'You cannot run a text file', 0
no_tom_msg db 10, 13, 'You cannot run a tom file', 0
kernel_ver db 'TommyOS Kernel v1.1', 10, 13, 'TDOS Prompt', 0
backspace_msg db 0x08, ' ', 0x08, 0
unkown_command db 10, 13,'Unknown command', 0
no_execute_kernel db 10, 13,'You cannot execute KERNEL.BIN,', 10, 13, 'as it is a core file and will', 10, 13, 'make TommyOS unusable!', 0
nice_try db 10, 13, 'Nice try.', 0
no_file_msg db 10, 13,'File not found or none specified.', 0
help_msg db 10, 13, 'Availible commands are:', 10, 13, 'DIR, TIME, DATE, CLS, ECHO,', 10, 13, 'SIZE, SHUTDOWN, REBOOT', 10, 13, 'DEL, REN, COPY, HELP', 0
skibidi db 10, 13, 'Errored', 0 ;what was this for?
txt_extension db 'TXT', 0
tom_extension db 'TOM', 0
pcx_extension db 'PCX', 0
floppy_two db 'B:', 0
floppy_one db 'A:', 0
ending_size db ' bytes', 0
prompt db 10, 13, '> ', 0
;commands
dir_str db 'DIR', 0 ;doTe
time_str db 'TIME', 0 ;done
date_str db 'DATE', 0 ;done 
cls_str db 'CLS', 0 ;done
echo_str db 'ECHO', 0 ;done
size_str db 'SIZE', 0 ;done
shutdown_str db 'SHUTDOWN', 0 ;done
reboot_str db 'REBOOT', 0 ;done
del_str db 'DEL', 0 ;done
ren_str db 'REN', 0 ;done
help_str db 'HELP', 0 ;done
copy_str db 'COPY', 0
kernel_iden_two db 'KERNEL'
	
drive_set_to_a db 10, 13,'Drive set to A', 0
drive_set_to_b db 10, 13,'Drive set to B', 0
no_drive_msg db 10, 13, 'Drive not present', 0


entire_command times 60 db 0
tmp_one dw 0

previous_file_run times 13 db 0
input_buffer times 60 db 0
input_buffer_copy times 60 db 0
input_buffer_copy_copy times 60 db 0

dirlist			times 1024 db 0
	tmp_string		times 15 db 0

	file_size		dw 0
	param_list		dw 0
	

counter dw 0

ascii11 db '  --- __           \/  __  __ ', 10, 13, '  /  / / /\/\ /\/\ /  / / /_  ', 10, 13, '     ~~               ~~  __/ ', 10, 13,0
shutdown_msg db 'You can now turn off your machine.', 0

msg2 db "V1.1", 10, 13, 0

skiplines dw 0
sector_buffer times 512 db 0 ;this is so we can check if a drive is loaded in or not, sample read and save it here
%include "./extra/functions.asm"
%include "./extra/old_funcs.asm"
disk_buffer equ 24576
buffer: