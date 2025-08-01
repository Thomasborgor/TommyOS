
[BITS 16]

cli
mov ax, 0
mov ss, ax
mov sp, 1000h
mov bp, 0
sti

cld

mov ax, 1000h
mov ds, ax
mov es, ax
mov fs, ax
mov gs, ax


start2:

mov byte [real_dirlist], dl
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
	call os_print_string
	
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
	call os_print_string
	
	second:

		mov si, prompt
		call os_print_string
		mov cx, 120
		mov si, input_buffer
		rst_loop:
			mov byte [si], 0x00
			inc si
			loop rst_loop
		mov cx, 60
		mov si, input_buffer_copy
		rst_loop2:
			mov byte [si], 0
			inc si
			loop rst_loop2
			
		mov cx, 60
		mov al, 0
		mov di, input_buffer_copy_copy
		rep stosb		
		mov di, input_buffer
		mov word [tmp_one], 0
		input_loop:
		xor ah, ah
		int 0x16
		mov [di], al
		cmp al, 0x08
		je backspace
		cmp al, 0x0D
		je parse
		cmp al, 0
		je input_loop
		inc di
		mov ah, 0x0e
		int 0x10
		inc word [tmp_one]
		cmp word [tmp_one], 120
		jge backspace
		jmp input_loop
backspace:
	cmp word [tmp_one], 1
	jl input_loop
	mov si, backspace_msg
	call os_print_string
	dec word [tmp_one]
	dec di
	jmp input_loop


parse: ;how we are going to do this:
	mov byte [tmp_one], 0
	cmp word [tmp_one], 120
	jne do_it_thing
	dec di
	do_it_thing:
	mov byte [di], 0x00
	
	
	mov si, input_buffer
	mov di, buffer
	call os_string_copy
	
	
	cmp byte [input_buffer], 0
	je second
	
	mov ax, input_buffer
	call os_string_uppercase
	
	
	
	mov si, input_buffer
	mov di, input_buffer_copy
	call os_string_copy
	
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
	
	mov di, hexsave
	call compare_string
	jc hexsave_do
	
	mov di, volumename
	call compare_string
	jc new_name
	
	;get the input, go to uppercase, figure out the length, 8-length is the number of spaces we need to pad, then add BIN to the end. 
	;https://www.microcenter.com/site/content/custom-pc-builder.aspx?load=818bfcf5-9703-4b47-ac7e-066d1dc75eaa
	
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
	call os_print_string
	jmp second
	
new_name:
	mov si, input_buffer
	add si, 5
	mov cx, 11
	mov di, sector_buffer
	get_nasdasdasdasd:
		lodsb
		cmp al, 0
		je done_thingasdasd
		stosb
		loop get_nasdasdasdasd
	done_thingasdasd:
		mov al, 32
		repe stosb ;EFFICIENCY
		mov byte [di], 8
	
	mov ax, 19
	call disk_convert_l2hts
	mov ax, 0x020d
	mov bx, buffer ;buffer holds the buffer, sector_buffer holds literally just the volume name
	int 13h
	jc failed
	
	mov byte [di], 8
	mov ax, 19
	call disk_convert_l2hts
	mov ax, 0x030d
	mov bx, sector_buffer
	int 13h
	jc failed
	
	jmp second
	
hexsave_do:
	mov si, input_buffer
	add si, 8
	mov di, input_buffer_copy

	get_filename:
		lodsb
		cmp al, 32
		je done_getting
		cmp al, 0
		je unknown_command_place
		stosb
		jmp get_filename
	
	done_getting:
	mov ax, input_buffer_copy
	call os_file_exists
	jnc the_file_exists
	mov si, input_buffer
	add si, 8
	mov di, buffer
	mov cx, 7
	mov al, 0
	rep stosb
	mov di, buffer
	
	call hex_to_bin
	mov ax, si
	call os_remove_file
	mov ax, si
	mov cx, dx
	mov bx, buffer

	call os_write_file ;ax filename, bx buffer to save, cx amount of bytes to write.
	jmp second
	
the_file_exists:
	push si
	mov ax, input_buffer_copy
	mov cx, 0x2600
	call os_load_file_in_segment
	mov si, 0x2600
	mov di, buffer
	call hex_to_bin
	pop si
	mov ax, si
	call os_remove_file
	mov cx, dx
	mov ax, si
	mov bx, buffer
	call os_write_file
	
	jmp second
	
	; Converts ASCII hex string in DS:SI to binary buffer in ES:DI
; Each pair of ASCII chars becomes one byte (e.g. "4F2A" -> 0x4F, 0x2A)

hex_to_bin:
	xor dx, dx
    xor     ax, ax         ; Clear AX
.next_pair:
	
    lodsb                  ; Load first hex char into AL from DS:SI
	cmp al, 32
	je .done
    cmp     al, 0
    je      .done          ; If null terminator, we're done
	inc dx
    call    ascii_to_nibble
    shl     al, 4          ; Move high nibble to upper half of byte
    mov     ah, al         ; Store high nibble in AH
	
    lodsb                  ; Load second hex char
	cmp al, 32
	je .done
    cmp     al, 0
    je      .done          ; Unexpected null? (odd-length input)
    call    ascii_to_nibble
    or      al, ah         ; Combine high and low nibble into AH

    stosb                  ; Store AH into ES:DI
    jmp     .next_pair

.done:
	mov byte [di], 0

	ret

; ------------------------------
; Converts ASCII hex char in AL to nibble (0-15)
; Output: AL = binary nibble
; Clobbers: nothing else
ascii_to_nibble:
    cmp     al, '0'
    jb      .invalid
    cmp     al, '9'
    jbe     .num
    cmp     al, 'A'
    jb      .lowercase
    cmp     al, 'F'
    jbe     .upper
.lowercase:
    cmp     al, 'a'
    jb      .invalid
    cmp     al, 'f'
    ja      .invalid
    sub     al, 'a' - 10
    ret
.upper:
    sub     al, 'A' - 10
    ret
.num:
    sub     al, '0'
    ret

.invalid:
    xor     al, al         ; Return 0 on invalid (could also signal error)
    ret

	
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

	mov ax, 1000h			; Reset ES back to original value
	mov es, ax
	mov ds, ax
	jmp main
	
echo_do:
	mov ax, 0x0e0a
	int 0x10
	mov al, 0dh
	int 0x10
	mov si, buffer
	add si, 5
	call os_print_string
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
	mov dl, al
	mov byte [real_dirlist], dl
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

	
	call ready_the_drive
	
	jmp second

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
	
	mov cx, 0
	mov ax, dirlist
	mov dl, [real_dirlist]
	mov [bootdev], dl
	call os_get_file_list

	mov si, no_drive_msg
	call os_print_string

	jmp second

	
yes_run_pcx:
	mov ax, input_buffer
	call os_print_pcx
	jc no_file
	mov ax, 0
	int 16h
	
	mov ax, 3			; Back to text mode
	mov bx, 0
	int 10h
	mov ax, 1003h			; No blinking text!
	int 10h

	mov ax, 1000h			; Reset ES back to original value
	mov es, ax
	mov ds, ax
	jmp second

	

copy_do:
	mov word [tmp_one], 0
	mov byte [tmp_dev_one], 0
	mov si, input_buffer
	add si, 7

	mov di, input_buffer_copy
	call os_string_copy
	mov [tmp_one], cx
	
	sub si, 2
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


	cmp byte [si], ':'
	jne unknown_command_place
	mov si, input_buffer
	add si, [tmp_one]
	add si, 9
	mov [tmp_one], si
	
	mov di, input_buffer_copy_copy
	call os_string_copy

	
	mov ax, input_buffer_copy
	mov cx, 0x2000
	call os_load_file
	mov si, [tmp_one]
	sub si, 2
	
	mov [tmp_one], bx
	jc no_file
	lodsb
	cmp al, 65
	jl unknown_command_place
	cmp al, 90
	jg unknown_command_place
	cmp al, 'B'
	jle is_a_or_b_2
	add al, 61
	mov [bootdev], al
	push ax
	call ready_the_drive
	pop ax
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
	cmp byte [si], ':'
	jne unknown_command_place
	
	mov cx, [tmp_one]
	mov bx, 0x2000
	mov ax, input_buffer_copy_copy
	;mov byte  [bootdev], 0x80
	call os_write_file_out_segment
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
	
	mov ax, input_buffer
	add ax, 4
	call os_file_exists
	jc no_file
	
	call os_remove_file
	jmp second
shutdown_do:
	mov ax, 5301h       ; Connect APM interface
	xor bx, bx
	int 15h
	
	mov ax, 530Eh       ; Set APM version
	mov bx, 0001h
	mov cx, 0102h       ; Version 1.2
	int 15h

	mov ax, 5307h       ; Set power state
	mov bx, 0001h       ; All devices
	mov cx, 0003h       ; Power off
	int 15h
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
	call os_print_string
	
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
	call os_print_string
	mov si, ending_size
	call os_print_string
	
	jmp second

clear_screen:
	call clear
	
	jmp second
	
no_file:
	mov si, no_file_msg
	call os_print_string
	jmp second
	
no_kernel:
	mov si, no_execute_kernel
	call os_print_string
	jmp second
	
load_program:	
	mov cx, 0x2000
	mov ax, input_buffer_copy
	call os_load_file
	
	mov cx, 0
	mov ax, 0x0e0a
	int 0x10
	mov al, 0x0D
	int 0x10
	mov si, input_buffer
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
	
	call 0x2000:0x0000
	
	mov ax, 0x2000
	mov es, ax
	mov ds, ax
	
	mov cx, 0x3fff
	mov eax, 0
	mov di, 0
	rep stosd
	
	
	mov ax, 0x1000
	mov es, ax
	mov ds, ax

	jmp second
	
no_param:
	mov si, buffer
	mov byte [si], 0xFF
	mov dl, [bootdev]
	mov ax, [SecsPerTrack]
	mov bx, [Sides]
	call 0x2000:0x0000
	
	
	mov ax, 0x1000
	mov es, ax
	mov ds, ax
	
	jmp second ;returns to main kernel
	

failed:
	mov si, skibidi
	call os_print_string
	jmp second

	
list_directory_thing:
	mov byte [dirlist], 0
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
	call os_print_string
	jmp second

no_txt_msg db 10, 13, 'You cannot run a text file', 0
no_tom_msg db 10, 13, 'You cannot run a tom file', 0
kernel_ver db 'TommyOS Kernel v1.1', 10, 13, 'TDOS Prompt', 0
backspace_msg db 0x08, ' ', 0x08, 0
unkown_command db 10, 13,'Unknown command', 0
no_execute_kernel db 10, 13,'You cannot execute KERNEL.BIN,', 10, 13, 'as it is a core file and will', 10, 13, 'make TommyOS unusable!', 0
nice_try db 10, 13, 'Nice try.', 0
no_file_msg db 10, 13,'File not found or none specified.', 0
skibidi db 10, 13, 'Errored', 0 ;what was this for?
txt_extension db 'TXT', 0
tom_extension db 'TOM', 0
pcx_extension db 'PCX', 0
floppy_two db 'B:', 0
floppy_one db 'A:', 0
ending_size db ' bytes', 0
prompt db 10, 13, '> ', 0
;commands
help_msg db 10, 13, 'Availible commands are:', 254, 0
dir_str db 'DIR', 0, 255 ;doTe
time_str db 'TIME', 0, 255 ;done
date_str db 'DATE', 0, 255 ;done 
cls_str db 'CLS', 0, 255 ;done
echo_str db 'ECHO', 0, 255 ;done
size_str db 'SIZE', 0, 255 ;done
shutdown_str db 'SHUTDOWN', 0, 255 ;done
reboot_str db 'REBOOT', 0, 255 ;done
del_str db 'DEL', 0, 255 ;done
ren_str db 'REN', 0, 255 ;done
help_str db 'HELP', 0, 255 ;done
copy_str db 'COPY', 0, 255
hexsave db 'HEXSAVE', 0, 255 ;allows users to create binary files from a VERY LONG STRING of hexor a ascii file, so theoretically you could just use this as a copy function.
volumename db 'NAME', 0 ;saves new volume name to FAT12 root directory.
kernel_iden_two db 'KERNEL'
	
drive_set_to_a db 10, 13,'Drive set to A', 0
drive_set_to_b db 10, 13,'Drive set to B', 0
no_drive_msg db 10, 13, 'Drive not present', 0


real_dirlist db 0
tmp_one dw 0

previous_file_run times 13 db 0
input_buffer times 120 db 0
input_buffer_copy times 60 db 0
input_buffer_copy_copy times 60 db 0


	tmp_string		times 15 db 0

	file_size		dw 0
	param_list		dw 0
	

counter dw 0

ascii11 db '  --- __           \/  __  __ ', 10, 13, '  /  / / /\/\ /\/\ /  / / /_  ', 10, 13, '     ~~               ~~  __/ ', 10, 13,0
shutdown_msg db 'You can now turn off your machine.', 0

msg2 db "V1.1", 10, 13, 0

skiplines dw 0
;sector_buffer times 512 db 0 ;this is so we can check if a drive is loaded in or not, sample read and save it here
%include "./extra/functions.asm"
%include "./extra/old_funcs.asm"
disk_buffer equ 24576
dirlist:
sector_buffer times 32 db 0
buffer:


;4b8b