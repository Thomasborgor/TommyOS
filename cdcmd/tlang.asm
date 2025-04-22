[bits 16]
org 32768 ;entry at 0xa400
;note: ax 0x0eb8 is the death character >:( I HATE YOU
;note: when adding or subbing or incing or decing si at ANY TIME, must do the same to offset_counter. MUST DO THAT.

;And with that, we have cut down the code from ~1600 lines to ~1000 lines.
;And all it took was a filesystem
;and with that filesystem we are at ~1700 lines again...
mov [SecsPerTrack], ax
mov [Sides], bx
mov [bootdev], dl
cmp byte [si], 0xff
je no_file
mov [skib_buffer], word si
mov ax, si
call os_file_exists
jc halt

call clear_but_ret   
mov ax, [skib_buffer]
mov cx, 43008
call os_load_file
mov word [offset_counter], 43008
mov word [end_of_file], bx
add word [end_of_file], 43008
mov byte [line_counter], 1

call os_seed_random

mov si, 43008
mov word [offset_counter], 43008
call go_to_first_line


jmp test_start ;why 'test_start'? because i didn't build this off of old basic.
skib_buffer dw 0
;this is completely new. I started over and called it 'test_start', as opposed to old basic's 'start'.
test_loop: ;nice little debug mode that I made to test stuff
		   ; gives [offset_counter], newline, first three chars, then the line count after a few spaces, then next line until EOF
	mov ax, [offset_counter]
	call os_int_to_string
	mov di, ax
	call print
	mov di, enter_msg
	call print
	
	
	call prep_si
	call get_cmd
	mov di, cmd_buf
	call print
	
	mov ax, 0x0e20
	int 0x10
	int 0x10
	mov al, [line_counter]
	xor ah, ah
	call os_int_to_string
	mov di, ax
	call print
	
	
	mov ah, 0
	int 0x16
	mov di, enter_msg
	call print
	
	call prep_si
	call find_next_line
	inc byte [line_counter]
	mov ax, [offset_counter]
	mov bx, [end_of_file]
	cmp ax, bx
	jl test_loop
mov di, cmd_buf
call print

ret

no_file:
	mov di, no_file_thing
	call print
	ret
	
no_file_thing db 'No input file specified.', 0

test_start:
	call prep_si
	mov byte [char5], 1
	call get_cmd
	
	mov ax, cmd_buf
	call os_string_length
	mov ax, [note_frequency]
	
	mov byte [char5], 1
	mov di, cmpsr_str
	call test_string
	je cmpsr_string_found
	
	mov byte [char5], 1
	mov di, getky_str
	call test_string
	je getky_string_found
	
	mov ax, [note_frequency]
	sub ax, 5 ;compensate for 5 chars + length of command until 0x20 (space)
	add word [offset_counter], ax
	
	call prep_si
	mov byte [char5], 0
	call get_cmd
	
	
	mov di, prt_str
	call test_string
	je prt_string_found

	mov di, mov_str
	call test_string
	je mov_string_found

	mov di, add_str
	call test_string
	je add_string_found
	
	mov di, sub_str
	call test_string
	je sub_string_found
	
	mov di, hlt_str
	call test_string
	je halt
	
	mov di, inc_str
	call test_string
	je inc_string_found
	
	mov di, dec_str
	call test_string
	je dec_string_found
	
	mov di, del_str
	call test_string
	je del_string_found
	
	mov di, bel_str
	call test_string
	je bel_string_found
	
	mov di, rem_str
	call test_string
	je inc_and_rerun_two ;record few lines of code for a command
	
	cmp byte [di], ';'
	je inc_and_rerun_two
	
	mov di, cmp_str
	call test_string
	je cmp_string_found
	
	mov di, jmp_str
	call test_string
	je jmp_string_found
	
	mov di, jgr_str
	call test_string
	je jgr_string_found
	
	mov di, jye_str
	call test_string
	je jye_string_found
	
	mov di, jne_str
	call test_string
	je jne_string_found
	
	mov di, jls_str
	call test_string
	je jls_string_found
	
	mov di, clr_str
	call test_string
	je clear
	
	mov di, ask_str
	call test_string
	je ask_string_found
	
	mov di, def_str
	call test_string
	je def_string_found
	
	mov di, rand_str
	call test_string
	je rand_string_found
	
	mov di, int_str
	call test_string
	je int_string_found
	
	jmp syntax_error_halt
	
halt:
	mov ah, 0x02
	mov bh, 00
	mov dl, 0
	mov dh, 20
	int 0x10
	
	ret
	
syntax_error_halt:
	cmp byte [cmd_buf], 0
	je halt;dumb fix but hey the problem was dumb too
	mov ah, 0x02
	mov bh, 00
	mov dl, 0
	mov dh, 23
	int 0x10
	
	mov di, syntax_error
	call print
	xor ah, ah
	mov al, [line_counter]
	call os_int_to_string
	mov di, ax
	call print
	mov ax, 0x0e0a
	int 0x10
	mov al, 0x0D
	int 0x10
	xor ax, ax
	mov di, cmd_buf
	mov al, [di]
	call os_int_to_string
	mov di, ax
	call print
	xor ax, ax
	mov di, cmd_buf
	mov al, [di]
	call os_int_to_string
	mov di, ax
	call print
	ret
	


	
int_string_found:
	mov byte [char4], 1
	call prep_si
	call get_cmd
	
	mov byte [char4], 1
	mov di, str1_str
	call test_string
	je convert_str1_int
	
	mov byte [char4], 1
	mov di, str2_str
	call test_string
	je convert_str2_int
	
	after_intified:
	
	call prep_si
	call get_cmd
	
	call find_user_var_return
	jc syntax_error_halt
	
	;value in ax but we don't care
	mov ax, dx
	mov bh, 00
	mov bl, [tmp_var_loc]
	jmp write_and_return
	
convert_str1_int:
	mov si, str1_str_string
	add si, [str1_offset]
	call os_string_to_int
	mov dx, ax
	jmp after_intified
	
convert_str2_int:
	mov si, str2_str_string
	add si, [str2_offset]
	call os_string_to_int
	mov dx, ax
	jmp after_intified
	
rand_string_found:
	call os_seed_random
	call prep_si
	call get_cmd
	mov si, cmd_buf
	call os_string_to_int
	mov [first_rand], ax
	call prep_si
	call get_cmd
	mov si, cmd_buf
	call os_string_to_int
	mov bx, ax
	mov ax, [first_rand]
	call os_get_random
	mov [first_rand], cx
	
	call prep_si
	call get_cmd
	
	call find_user_var_return
	jc syntax_error_halt
	
	xor bh, bh
	mov bl, [tmp_var_loc]
	
	mov ax, [first_rand]
	jmp write_and_return
	;cx has rand
first_rand dw 0
	
getky_string_found: ;how this works: Two modes, wait and non wait. Wait includes the first param being a quote/number and nothing else.
;Non wait has tecnically three params. first is a %, then where to jump if zero, and then a variable to save the keypress to.
	call prep_si
	
	cmp byte [si], '"'
	je use_quotes
	cmp byte [si], '%'
	je use_non_blocking
	
	call get_cmd
	call find_user_var_return
	jnc user_var_found_getky
	
	;must be a number
	mov si, cmd_buf
	call os_string_to_int
	xor ah, ah
	mov dl, al
	wait_for_key_loop:
		mov ah, 0 ;one thing, when specifying a number, you must wait. 
		int 16h
		cmp dl, al
		jne wait_for_key_loop
		
	jmp inc_and_rerun_two
	
	use_quotes:
		inc word [offset_counter]
		call prep_si
		mov dl, [si]
		jmp wait_for_key_loop
	
	user_var_found_getky:
		;idk
		;even though i made the coed i forgot how to do it ;)
		mov ah, 0 ;skib
		int 0x16
		xor ah, ah
		xor bh, bh
		mov bl, [placeholder2]
		call write_and_return
use_non_blocking:
	add word [offset_counter], 2
	
	mov ah, 0x01
	int 0x16
	jz jmp_string_found ;the param after is the jump param so we good
	xor ah, ah
	mov dx, ax
	add word [offset_counter], 4
	call prep_si
	call get_cmd
	call find_user_var_return
	jc syntax_error_halt
	mov ax, dx
	xor bh, bh
	mov bl, [tmp_var_loc]
	jmp write_and_return
	
def_string_found:
	call prep_si
	mov byte [char4], 1
	call get_cmd
	
	mov di, str1_str
	mov byte [char4], 1
	call test_string
	je reset_str1_offset
	mov di, str2_str
	mov byte [char4], 1
	call test_string
	je reset_str2_offset
	mov ax, [tmp_cx]
	sub ax, 3
	sub word [offset_counter], ax  ;this has to be dynamically changed based on the amount of chars that the get_cmd's found in the last runs.
	call prep_si
	call get_cmd

	
	cmp byte [varcount], 30 ;checks if we are at 30 user vars
	jge halt

	mov byte [placeholder2], 0 ;reset the counter
	mov ax, cmd_buf
	call os_string_length ;get the length of the user var
	xor ah, ah
	mov [placeholder2], al
	mov word [placeholder], 0
	mov si, varnames
	
	find_open_var_spot:
		lodsb                        ; Load a byte from si
		cmp byte al, '?'           ; Check for default value
		je found_open_spot       ; Continue if not a default
		inc word [placeholder]      ; Increment counter
		jmp find_open_var_spot
		
		found_open_spot:
		
		dec byte [placeholder2]
		
		mov di, varnames
		add di, [placeholder]
		mov si, cmd_buf
		mov cl, [placeholder2]
		inc cl
		xor ch, ch
		store_it_loop:
		lodsb
		stosb
		loop store_it_loop
		
		done_storing:
		cmp byte [placeholder2], 1
		je pad_one_zeros
		cmp byte [placeholder2], 2
		je end_pad
		
		pad_two_zeros:
		mov byte [di], ' '
		inc di
	
		pad_one_zeros:
		mov byte [di], ' '
		
		end_pad:
		mov al, 2
		mul byte [varcount]
		mov bl, al
		xor bh, bh
		mov ax, 0
		call write_word_user_var
	
		inc byte [varcount]
		sub word [offset_counter], 1
		jmp inc_and_rerun_two
	reset_str1_offset:
		mov word [str1_offset], 00
		sub word [offset_counter], 2
		
		jmp inc_and_rerun_two
	reset_str2_offset:
		mov word [str2_offset], 00
		sub word [offset_counter], 2
		jmp inc_and_rerun_two
	
ask_string_found:
	mov al, 0
	mov cx, 59
	mov di, str1_str_string
	repe stosb
	mov al, 0
	mov cx, 59
	mov di, str2_str_string
	repe stosb
	
	call prep_si
	mov byte [char4], 1
	call get_cmd
	
	mov byte [char4], 1
	mov di, str1_str
	call test_string
	je ask_str1
	
	mov byte [char4], 1
	mov di, str2_str
	call test_string
	je ask_str2
	
	jmp syntax_error_halt
	
	ask_str1:
		mov si, str1_str_string
		
		get_ask_string_before:
		mov dx, 0x1600
		mov bh, 0
		mov ah, 2
		int 0x10
		mov di, input_string_thing
		call print
		
		get_ask_string:
			xor ah, ah
			int 0x16
			cmp al, 0x0D
			je ask_done
			cmp al, 0x08
			je do_backspace
			mov byte [si], al
			inc si
			mov ah, 0x0e
			int 0x10
			cmp si, 59
			je ask_done
			jmp get_ask_string
			
		do_backspace:
			mov ah, 0x03
			mov bh, 00
			int 0x10
			cmp dl, 0x08
			jle get_ask_string
			dec si
			mov ah, 0x0e
			mov al, 0x08
			int 0x10
			mov al, 0x20
			int 0x10
			mov al, 0x08
			int 0x10
		jmp get_ask_string
		
		
		ask_done:
			mov byte [si], 0
			mov si, str1_str_string
			mov di, ext_str
			mov cx, 3
			repe cmpsb
			je halt
			mov dx, 0x1600
			mov bh, 0
			mov ah, 2
			int 0x10
			mov cx, 60
			small_loop:
				mov ah, 0x0e
				mov al, ' '
				int 0x10
				loop small_loop
			
			mov ah, 2
			mov dh, [cursor_y]
			mov dl, [cursor_y]
			mov bh, 0
			int 0x10
			sub word [offset_counter], 2
			call prep_si
			jmp inc_and_rerun_two
	
	ask_str2:
		mov si, str2_str_string
		jmp get_ask_string_before
 
 
ext_str db 'ext', 0
	
cmpsr_string_found:

    mov word [tmp_cx], 1          ; Initialize tmp_cx to count string length
    mov byte [strings_equal], 0
    mov byte [strings_not_equal], 0

    mov si, str1_str_string       ; Point SI to the first string
    call find_zero                 ; Find the length of str1_str_string
	mov dx, [tmp_cx]
	mov si, str2_str_string
	call find_zero
	mov cx, [tmp_cx]

find_zero_after:

    mov si, str1_str_string       ; Reset SI to the start of str1
    mov di, str2_str_string       ; Set DI to the start of str2

    repe cmpsb                    ; Compare strings byte-by-byte
    jne strings_are_not_equal         ; If CX is not zero, strings don't match
	
	mov cx, dx
	repe cmpsb
	jne strings_are_not_equal
    ; If we get here, all bytes matched
    mov byte [strings_equal], 1   ; Set strings_equal flag
    jmp done_did_it

strings_are_not_equal:
    mov byte [strings_not_equal], 1 ; Set strings_not_equal flag
	jmp inc_and_rerun_two

	
done_did_it:
	mov byte [strings_equal], 1
	jmp inc_and_rerun_two

find_zero:
    lodsb                         ; Load byte at DS:SI into AL, increment SI
    cmp al, 0                     ; Check if AL is null (end of string)
    je find_zero_after2            ; If null, go to find_zero_after
    inc word [tmp_cx]             ; Increment string length
    jmp find_zero                 ; Repeat until null byte is found
	find_zero_after2:
	ret

	
jgr_string_found:
	cmp byte [jgr_flag], 1
	jne inc_and_rerun_two
	jmp jmp_string_found

jne_string_found:
	
	cmp byte [strings_not_equal], 1
	je jmp_string_found

	cmp byte [jne_flag], 1
	je jmp_string_found
	
	jmp inc_and_rerun_two

jye_string_found:
	cmp byte [strings_equal], 1
	je jmp_string_found
	
	cmp byte [jye_flag], 1
	je jmp_string_found
	
	jmp inc_and_rerun_two
	
jls_string_found:
	cmp byte [jls_flag], 1
	jne inc_and_rerun_two
	jmp jmp_string_found
	
jmp_string_found:
	mov byte [jmp_counter], 1
	call prep_si
	call get_cmd
	
	mov si, cmd_buf
	call os_string_to_int
	cmp al, 1
	je first_line_thingy
	mov [line_counter2], al
	
	
	mov word [offset_counter], 43008
	call prep_si
	
	call go_to_first_line
	repeat_jmp:
	
	add word [offset_counter], 2
	call prep_si
	call find_next_line

	inc byte [jmp_counter]
	mov al, [jmp_counter]
	cmp al, [line_counter2]
	
	jl repeat_jmp
	
	mov byte [jye_flag], 0
	mov byte [jne_flag], 00
	mov byte [jls_flag], 00
	mov byte [jgr_flag], 0
	
	jmp test_start
	
first_line_thingy:
	mov word [offset_counter], 43008
	call prep_si
	call go_to_first_line
	jmp test_start
	
	
cmp_string_found:
	call prep_si
	mov byte [char4], 1
	call get_cmd
	
	mov di, str1_str
	mov byte [char4], 1
	call test_string
	je str1_cmp_first
	
	mov di, str2_str
	mov byte [char4], 1
	call test_string
	je str2_cmp_first
	
	sub word [offset_counter], 5
	call prep_si
	call get_cmd
	
	call find_user_var_return
	jnc user_var_cmp_first
	
	mov di, xxx_str
	call test_string
	je xxx_cmp_first
	
	mov di, yyy_str
	call test_string
	je yyy_cmp_first
	
	jmp syntax_error_halt
	
	after_cmp:
	
	call prep_si
	mov byte [char4], 1
	call get_cmd
	
	mov di, str1_str
	mov byte [char4], 1
	call test_string
	je str1_cmp_second
	
	mov di, str2_str
	mov byte [char4], 1
	call test_string
	je str2_cmp_second
	
	sub word [offset_counter], 5
	call prep_si
	call get_cmd
	
	mov di, xxx_str
	call test_string
	je xxx_cmp_second
	
	mov di, yyy_str
	call test_string
	je yyy_cmp_second
	
	call find_user_var_return
	jnc comparing
	;must be a number. following along?
	
	mov si, cmd_buf
	call os_string_to_int
	
	comparing:
	mov bx, ax
	mov ax, [placeholder]
	cmp ax, bx
	je equal_cmp
	cmp ax, bx
	jg greater_than_cmp
	cmp ax, bx
	jl less_than_cmp

	
	sub word [offset_counter], 2
	jmp inc_and_rerun_two
	
user_var_cmp_first:
	call prep_si
	call check_var_len_offset
	mov [placeholder], ax
	add word [offset_counter], 3
	jmp after_cmp
	
str1_cmp_first:
	mov di, str1_str_string
	add di, [str1_offset]
	mov bl, [di]
	xor bh, bh
	mov [placeholder], bx
	jmp after_cmp
str2_cmp_first:
	mov di, str2_str_string
	add di, [str2_offset]
	mov bl, [di]
	xor bh, bh
	mov [placeholder], bx
	jmp after_cmp

str1_cmp_second:
	mov di, str1_str_string
	add di, [str1_offset]
	mov al, [di]
	xor ah, ah
	jmp comparing
str2_cmp_second:
	mov di, str2_str_string
	add di, [str2_offset]
	mov al, [di]
	xor ah, ah
	jmp comparing
	
xxx_cmp_first:
	mov bl, [cursor_x]
	xor bh, bh
	mov [placeholder], bx
	jmp after_cmp
yyy_cmp_first:
	mov bl, [cursor_y]
	xor bh, bh
	mov [placeholder], bx
	jmp after_cmp

xxx_cmp_second:
	mov al, [cursor_x]
	xor ah, ah
	jmp comparing
yyy_cmp_second:
	mov al, [cursor_y]
	xor al, al
	jmp comparing

equal_cmp:
	mov byte [jye_flag], 1
	mov byte [jne_flag], 0
	sub word [offset_counter], 2
	jmp inc_and_rerun_two

less_than_cmp:
	mov byte [jls_flag], 1
	sub word [offset_counter], 2
	mov byte [jne_flag], 1
	jmp inc_and_rerun_two
greater_than_cmp:
	mov byte [jne_flag], 1
	mov byte [jgr_flag], 1
	mov byte [jls_flag], 0
	sub word [offset_counter], 2
	jmp inc_and_rerun_two

bel_string_found:
	call prep_si
	call get_cmd
	
	call find_user_var_return
	jnc bel_user_var
	
	mov si, cmd_buf
	call os_string_to_int
	
	mov word [note_frequency], ax
	
	bel_after:
	
	call prep_si
	call get_cmd
	
	mov si, cmd_buf
	call os_string_to_int
	
	mov word [note_duration], ax
	
	call play_sound
	mov word bx, [note_duration]
	call delay
	call stop_note
	
	jmp inc_and_rerun_two
	
bel_user_var:
	call check_var_len_offset
	
	mov [placeholder], ax
	mov [placeholder2], al
	
	jmp bel_after
				

del_string_found:
	call prep_si
	call get_cmd
	
	call find_user_var_return
	jnc del_user_var
	
	mov si, cmd_buf
	call os_string_to_int
	mov bx, ax
	call delay
	sub word [offset_counter], 2
	jmp inc_and_rerun_two

del_user_var:
	call check_var_len_offset
	mov bx, ax
	call delay
	jmp inc_and_rerun_two

inc_string_found:	
	call prep_si
	call get_cmd
	
	
	mov di, xxx_str
	call test_string
	je xxx_inc
	
	mov di, yyy_str
	call test_string
	je yyy_inc
	
	call find_user_var_return
	jnc inc_user_var
	
	sub word [offset_counter], 4
	call prep_si
	mov byte [char4], 1
	call get_cmd
	
	mov byte [char4], 1
	mov di, str1_str
	call test_string
	je inc_str1
	
	mov byte [char4], 1
	mov di, str2_str
	call test_string
	je inc_str2
	
	jmp syntax_error_halt
	
	inc_str1:
		inc word [str1_offset]
		sub word [offset_counter], 2
		jmp inc_and_rerun_two
	
	inc_str2:
		inc word [str2_offset]
		sub word [offset_counter], 2
		jmp inc_and_rerun_two
		
	inc_user_var:
		call check_var_len_offset
		inc ax
		xor bh, bh
		mov bl, [tmp_var_loc]
		jmp write_and_return
		
	xxx_inc:
		inc byte [cursor_x]
		dec word [offset_counter]
		jmp inc_and_rerun_two
	
	yyy_inc:
		inc byte [cursor_y]
		dec word [offset_counter]
		jmp inc_and_rerun_two
	
dec_string_found:	
	call prep_si
	call get_cmd
	
	
	mov di, xxx_str
	call test_string
	je xxx_dec
	
	mov di, yyy_str
	call test_string
	je yyy_dec
	
	call find_user_var_return
	jnc dec_user_var
	
	sub word [offset_counter], 4
	call prep_si
	mov byte [char4], 1
	call get_cmd
	
	mov byte [char4], 1
	mov di, str1_str
	call test_string
	je dec_str1
	
	mov byte [char4], 1
	mov di, str2_str
	call test_string
	je dec_str2
	
	jmp syntax_error_halt
	
	dec_str1:
		dec word [str1_offset]
		sub word [offset_counter], 2
		jmp inc_and_rerun_two
	
	dec_str2:
		dec word [str2_offset]
		sub word [offset_counter], 2
		jmp inc_and_rerun_two
		
	dec_user_var:
		call check_var_len_offset
		dec ax
		xor bh, bh
		mov bl, [tmp_var_loc]
		jmp write_and_return
		
	xxx_dec:
		dec byte [cursor_x]
		dec word [offset_counter]
		jmp inc_and_rerun_two
	
	yyy_dec:
		dec byte [cursor_y]
		dec word [offset_counter]
		jmp inc_and_rerun_two
		
add_string_found:
	call prep_si
	call get_cmd
	
	
	mov di, cmd_buf
	call find_user_var_return
	jnc add_user_var_before
	
	mov si, cmd_buf
	call os_string_to_int
	
	mov word [placeholder], ax
	mov byte [placeholder2], al
	
	add_after:
	call prep_si
	call get_cmd
	
	mov di, xxx_str
	call test_string
	je xxx_add
	
	mov di, yyy_str
	call test_string
	je yyy_add
	
	call find_user_var_return
	jnc add_user_var
	
	jmp syntax_error_halt
	
	add_user_var:
		add ax, [placeholder]
		xor bh, bh
		mov bl, [tmp_var_loc]
		jmp write_and_return
		
	xxx_add:
		mov al, [placeholder2]
		add [cursor_x], al
		sub word [offset_counter], 2
		jmp inc_and_rerun_two
	
	yyy_add:
		mov al, [placeholder2]
		add [cursor_y], al
		jmp inc_and_rerun_two
		
	add_user_var_before:
		call check_var_len_offset
		
		mov [placeholder], ax
		mov [placeholder2], al
		add word [offset_counter], 3
		jmp add_after
		
		
sub_string_found:
	call prep_si
	call get_cmd
	
	call find_user_var_return
	jnc sub_user_var_before
	
	mov si, cmd_buf
	call os_string_to_int
	
	mov word [placeholder], ax
	mov byte [placeholder2], al
	
	sub_after:
	call prep_si
	call get_cmd
	
	mov di, xxx_str
	call test_string
	je xxx_sub
	
	mov di, yyy_str
	call test_string
	je yyy_sub
	
	call find_user_var_return
	jnc sub_user_var
	
	jmp syntax_error_halt
	
	sub_user_var:
		sub ax, [placeholder]
		mov bl, [tmp_var_loc]
		xor bh, bh
		jmp write_and_return
		
	xxx_sub:
		mov al, [placeholder2]
		sub [cursor_x], al
		jmp inc_and_rerun_two
	
	yyy_sub:
		mov al, [placeholder2]
		sub [cursor_y], al
		jmp inc_and_rerun_two
		
	sub_user_var_before:
		call check_var_len_offset
		
		mov [placeholder], ax
		mov [placeholder2], al
		add word [offset_counter], 3
		jmp sub_after

mov_string_found:
	call prep_si
	mov byte [char4], 1
	call get_cmd
	
	mov di, str1_str
	mov byte [char4], 1
	call test_string
	je str1_mov_first
	
	mov di, str2_str
	mov byte [char4], 1
	call test_string
	je str2_mov_first
	mov ax, [tmp_cx]
	sub ax, 3
	sub word [offset_counter], ax
	call prep_si
	call get_cmd
	
	call find_user_var_return
	jnc mov_user_var_before
	
	;must be a number
	mov si, cmd_buf
	call os_string_to_int
	mov [placeholder], ax
	mov [placeholder2], al
	
	mov_after:
	
	call prep_si
	mov byte [char4], 1
	call get_cmd
	

	
	
	mov di, str1_str
	mov byte [char4], 1
	call test_string
	je str1_mov_second
	
	mov di, str2_str
	mov byte [char4], 1
	call test_string
	je str2_mov_second
	
	mov ax, [tmp_cx]
	sub ax, 3
	sub word [offset_counter], ax
	call prep_si
	call get_cmd
	
	
	
	mov di, xxx_str
	call test_string
	je mov_xxx
	
	mov di, yyy_str
	call test_string
	je mov_yyy
	
	call find_user_var_return
	jnc mov_user_var_second
	jmp syntax_error_halt
	
	str1_mov_first:
		mov di, str1_str_string
		add di, [str1_offset]
		mov al, [di]
		mov [placeholder2], al
		xor ah, ah
		mov [placeholder], ax
		jmp mov_after
	str2_mov_first:
		mov di, str2_str_string
		add di, [str2_offset]
		mov al, [di]
		mov [placeholder2], al
		xor ah, ah
		mov [placeholder], ax
		jmp mov_after
		
	str1_mov_second:
		mov al, [placeholder2]
		mov di, str1_str_string
		add di, [str1_offset]
		mov [di], al
		sub word [offset_counter], 2
		jmp inc_and_rerun_two
	str2_mov_second:
		mov al, [placeholder2]
		mov di, str2_str_string
		add di, [str2_offset]
		mov [di], al
		sub word [offset_counter], 2
		jmp inc_and_rerun_two
	
	mov_user_var_before:
		mov [placeholder], ax
		mov [placeholder2], al
		jmp mov_after
	mov_user_var_second:
		mov ax, [placeholder]
		xor bh, bh
		mov bl, [tmp_var_loc]
		jmp write_and_return
		
	mov_xxx:
		mov al, [placeholder2]
		mov [cursor_x], al
		sub word [offset_counter], 2
		jmp inc_and_rerun_two
	mov_yyy:
		mov al, [placeholder2]
		mov [cursor_y], al
		sub word [offset_counter], 2
		jmp inc_and_rerun_two
	

prt_string_found:
	cmp byte [cursor_y], 24
	jle dont_set_cursor
	mov byte [cursor_y], 24
	dont_set_cursor:
	mov ah, 0x02
	mov dl, [cursor_x]
	mov dh, [cursor_y]
	mov bh, 0
	int 0x10
	mov al, 0
	mov cx, 59
	mov di, prt_string
	rep stosb
	call prep_si
	lodsb

	inc word [offset_counter]
	cmp al, '"'
	je print_a_string
	
	dec word [offset_counter]
	call prep_si
	call get_cmd
	
	call find_user_var_return
	jnc print_a_user_var
	
	sub word [offset_counter], 4
	
	call prep_si
	mov byte [char4], 1
	call get_cmd
	
	mov byte [char4], 1
	mov di, str1_str
	call test_string
	je str1_print
	
	mov byte [char4], 1
	mov di, str2_str
	call test_string
	je str2_print
	
	jmp syntax_error_halt
		
	print_a_user_var:
		call os_int_to_string
		sub word [offset_counter], 2
		
	end_print_num:
		mov di, ax
		call print
		jmp inc_and_rerun_two
	
	print_a_string:
		call prep_si
		mov di, prt_string
	get_print_string:
		lodsb
		cmp al, '"'
		je done_get_print_string
		stosb
		inc word [offset_counter]
		jmp get_print_string
	
	done_get_print_string:
	mov di, prt_string
	call print
	
	jmp inc_and_rerun_two
	
	str1_print:
		mov di, str1_str_string
		add di, [str1_offset]
		call print
		sub word [offset_counter], 2
		jmp inc_and_rerun_two
		
	str2_print:
		mov di, str2_str_string
		add di, [str2_offset]
		call print
		sub word [offset_counter], 2
		jmp inc_and_rerun_two

prep_si:
	xor si, si
	mov si, [offset_counter]
	ret

inc_and_rerun_two:
	call os_seed_random
	call prep_si
	cmp si, [end_of_file]
	jge halt
	inc si
	cmp si, [end_of_file]
	jge halt
	inc si
	cmp si, [end_of_file]
	jge halt
	sub si, 2
	
	
	call prep_si
	call find_next_line
	inc byte [line_counter]
	jmp test_start



;so simple

find_next_line: ;with check

	cmp byte [si-2], 32
	je special_check
	cmp byte [si], 10 ;checks for 0x0a (COMES FIRST)
	je found_next_line_and_add
	cmp byte [si], 13
	je found_next_line_and_add
	inc si ;checks again
	inc word [offset_counter]
	cmp si, [end_of_file]
	jge halt
	call os_seed_random
	jmp find_next_line

found_next_line_and_add:
	add word [offset_counter], 1
	call prep_si

	cmp byte [si], 13
	je find_next_line
	cmp byte [si], 10
	je find_next_line
	cmp byte [si], 0
	je find_next_line
	cmp si, [end_of_file]
	jge halt
	ret

special_check:
	add word [offset_counter], 1
	call prep_si
	cmp byte [si], 10
	jne find_next_line
	jmp found_next_line_and_add
	
go_to_first_line:
	mov word [offset_counter], 43008
	first_line_loop:
	call prep_si
	cmp byte [si], 32
	je special_first
	cmp byte [si], 10
	jl found_first_line
	cmp byte [si], 13
	jg found_first_line
	cmp byte [si], 11
	je found_first_line
	cmp byte [si], 12
	je found_first_line
	
	inc si
	inc word [offset_counter]
	jmp first_line_loop
	
found_first_line:
	ret

special_first:
	add word [offset_counter], 3
	call prep_si
	cmp byte [si], 32
	je special_first
	jmp found_first_line

get_cmd:
	clc
	mov word [tmp_cx], 0
	mov di, cmd_buf
	mov al, 0
	mov cx, 6
	rep stosb
	xor di, di
	mov di, cmd_buf
	call prep_si
	push cx
	mov cx, 3
	mov word [tmp_cx], cx
	cmp byte [char4], 1
	je set_4_cmd
	
	cmp byte [char5], 1
	je set_5_cmd

	lodsb_loop:
		lodsb
		inc word [tmp_cx] ;new counter
		inc word [offset_counter]
		cmp al, ' '
		je done_get_cmd
		cmp al, 10
		je done_get_cmd
		cmp al, 13
		je done_get_cmd
		stosb
		loop lodsb_loop
		done_get_cmd:
		mov byte [di], 0
		pop cx
		inc word [offset_counter]
		inc si
		mov byte [char5], 0
		mov byte [char4], 0
		ret
		

set_4_cmd:
	mov cx, 4
	mov word [tmp_cx], cx
	jmp lodsb_loop
	
set_5_cmd:
	mov cx, 5
	mov word [tmp_cx], cx
	jmp lodsb_loop


print:
	mov al, [di]
	cmp al, 0
	je done_di
	mov ah, 0x0e
	int 0x10
	inc di
	jmp print
done_di:
	ret

test_string:
	mov si, cmd_buf

	cmp byte [char4], 1
	je do_four

	cmp byte [char5], 1
	je do_five
	
	mov cx, 3
	rep_thing:
	repe cmpsb
	mov byte [char5], 0
	mov byte [char4], 0
	ret
	
do_five:
	mov cx, 5
	jmp rep_thing
do_four:
	mov cx, 4
	jmp rep_thing

delay:
	
    ; Input: BX = number of ticks to wait (1 tick ≈ 55ms)
    mov ah, 00h        ; Function 00h: Get current clock count
    int 1Ah            ; Call BIOS to get tick count
    add bx, dx         ; Calculate target tick count (DX = current count)
wait_loop:
    mov ah, 00h        ; Function 00h: Get current clock count
    int 1Ah            ; Call BIOS to get tick count
    cmp dx, bx         ; Compare current tick count with target
    jb wait_loop       ; If current tick count is less than target, wait
    ret                ; Return after the delay

play_sound:
	mov word ax, [note_frequency]
	; Multiply AX by 6.1 using fixed-point arithmetic with scaling factor of 10
	; Result is in AX (16-bit, rounded)
	
	mov bx, 61           ; Fixed-point representation of 6.1 (scaled by 10)
	mul bx               ; AX * BX -> DX:AX (result is 32-bit)
	mov cx, 10
	div cx
	pusha
	mov cx, ax			; Store note value for now

	mov al, 182
	out 43h, al
	mov ax, cx			; Set up frequency
	out 42h, al
	mov al, ah
	out 42h, al

	in al, 61h			; Switch PC speaker on
	or al, 03h
	out 61h, al

	popa
	ret
	
stop_note:
	pusha

	in al, 61h
	and al, 0FCh
	out 61h, al

	popa
	ret
	
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
	
	sub word [offset_counter], 2
	call prep_si
	call find_next_line
	call prep_si
	jmp test_start

clear_but_ret:
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
	
special_bum_thingy:
	dec word [offset_counter]
	jmp this_thingy_2

find_user_var_return:
	clc
	cld
	mov si, varnames
	mov di, cmd_buf
	
	mov ax, cmd_buf
	call os_string_length
	
	mov di, cmd_buf
	cmp ax, 2
	je special_bum_thingy
	cmp ax, 3
	je this_thingy
	this_thingy_2:
	add di, ax
	mov cx, 3
	sub cx, ax
	sub word [offset_counter], cx
	inc word [offset_counter]
	mov al, ' '
	rep stosb
	mov [tmp_cx], ax ;temporary saves the length
	this_thingy:

	mov si, varnames
	mov byte [find_var], 0

	;loop for three, then if not equal, then increment placeholder2, then times it by three, reset si, and add that to si.
	search_again:
	mov si, varnames ;for some reason it doesn't like to re-init, so you got to multiply by three for every placeholder2.
	;makes sense actually.
	mov di, cmd_buf
	
	mov al, 3
	mul byte [find_var]
	xor ah, ah
	add si, ax
	
	
	mov cx, 3
	repe cmpsb
	je found_the_var
	inc byte [find_var]
	cmp byte [find_var], 29
	jge no_user_var
	jmp search_again
		
	found_the_var:
		mov al, [find_var]
		add [find_var], al
		mov al, [find_var]
		xor ah, ah
		
		xor si, si
		mov si, varlocs
		add si, ax
		
		mov [tmp_var_loc], al
		
		mov word ax, [si]
		
		clc
		ret
		
	no_user_var:
		stc
		ret
		
find_var db 0
		
write_word_user_var:
	mov si, varlocs
	add si, bx
	mov word [si], ax
	ret
	
write_and_return:
	call write_word_user_var
	sub word [offset_counter], 3
	call prep_si
	jmp inc_and_rerun_two
	
	
check_var_len_offset:
	
	cmp word [tmp_cx], 2
	je dec_one_offset
	cmp word [tmp_cx], 1
	je dec_two_offset
	
	dec word [offset_counter]
	
	dec_two_offset:
	dec word [offset_counter]
	
	dec_one_offset:
	dec word [offset_counter]
	
	ret
; Buffers and messages
cmd_buf times 6 db 0
backspace_msg db 0x08, 0x20, 0x08, 0
enter_msg db 10, 13, 0

prt_string times 60 db 0
prt_counter db 0

; Command strings
mov_str db 'mov', 0 ;move a value to a var
add_str db 'add', 0 ;add a value to a var
prt_str db 'prt', 0 ;print a var or a string
sub_str db 'sub', 0 ;sub a value from a var
clr_str db 'clr', 0 ;
jmp_str db 'jmp', 0 ;jump to a line 
inc_str db 'inc', 0 ;add 1 to a value
dec_str db 'dec', 0 ;sub 1 from a value
cmp_str db 'cmp ', 0;compare a number and a var, OR var and a var
jye_str db 'jye', 0 ;jump if equal
jne_str db 'jne', 0 ;jump if not equal
hlt_str db 'hlt', 0 ;stop program instantly
del_str db 'del', 0 ;delays for numbers ticks
jgr_str db 'jgr', 0 ;jump if greater
jls_str db 'jls', 0 ;jump if lesser
non_str db 'non', 0 ;used for jump commands to skip the page changing process, making it faster
rem_str db 'rem', 0 ;used to make comments, code is about 5 lines! (they are for identifying the command!!!)
bel_str db 'bel', 0 ;two params, first is frequency which is either var or num, then set num for the second param
getky_str db 'getky', 0 ;two params, key looking for in quotes, non if any, and then var to save to if first param is not non
ask_str db 'ask', 0 ;takes in one param, and that is the string name. Either st1 or st2
def_str db 'def', 0 ;one param, volatile up to 3 char variable defined and set to zero
cmpsr_str db 'cmpsr', 0 ;no params as there is only two strings to compare
rand_str db 'rnd', 0 ;takes in THREE PARAMS (scary) first two are bounds and last is variable to save it too (sorry no strings)
int_str db 'int', 0 ;two params, first the string (with offset) that will be converted into an int at var param two.
mul_str db 'mul', 0 ;two params
div_str db 'div', 0 ;two params
;error messages and hlt message
syntax_error db 'Syntax error on line ', 0
;new variables test
varnames db 60 dup('?'), 0
varlocs times 30 db 0, 0x01 ;0x01 for testing idk
varcount db 0 ;should go up to 30
tmp_var_loc db 0
;how vars will work: user stores a varname (3 chars OR until a newline char, if that case then pad with space in varnames), then it copies to the next availiable place in varnames if space, incrementing varcount
;if you want to retrieve a value, then you will search through varnames 3 chars at a time for the varname until you find it, incrementing a temporary value as you go
;then when you do that, add the temporary value to si when it points to varlocs, and then save the value to another temporary register.
;yay!

; Messages for successful commands

; Variables and counters
jmp_counter db 1
getkey_var db 0
char5 db 0
char4 db 0
;good_to_go db 0
line_counter db 1
line_counter2 dw 0
xxx_str db 'xxx', 0
yyy_str db 'yyy', 0
str1_str db 'str1', 0
str2_str db 'str2', 0
str1_offset dw 0
str2_offset dw 0
cursor_x db 0 ;starts at 40 ;there will be a 20 by 20 screen
;remade, it is like 36 by 20
cursor_y db 0 ;starts at 2 ;old
;C8 C9 BB BC hex codes ;not needed
;^ for drawing the tubes for the screen ;not needed...
str1_str_string times 60 db 0
str2_str_string times 60 db 0
strings_equal db 0
strings_not_equal db 0
;flags for jumps
jye_flag db 0
jne_flag db 0
jgr_flag db 0
jls_flag db 0
offset_counter dw 43008
note_duration dw 0
note_frequency dw 0
tmp_cx dw 0


; placeholder for integer to string conversion
;placeholder_str_int db '000', 0
placeholder dw 0
placeholder2 db 0
prompt db '> ', 0

input_string_thing db 'String: ', 0
filename_buf times 12 db 0
%include "./cdcmd/basicfunctions.asm"
disk_buffer db 24576
end_of_file dw 0
;this line count should not be anything but 1365. 
;just kidding its 1614
;just kidding x2 its 1706
;just kidding x3 its 1767
;just kidding x4 its 1795
dirlist: