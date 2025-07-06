[bits 16]
;note: ax 0x0eb8 is the death character >:( I HATE YOU
;note: when adding or subbing or incing or decing si at ANY TIME, must do the same to offset_counter. MUST DO THAT.

;And with that, we have cut down the code from ~1600 lines to ~1000 lines.
;And all it took was a filesystem
;and with that filesystem we are at ~1700 lines again...

mov [SecsPerTrack], ax ;why not prefixed with ES:? because then I would have to change pretty much all of functions.asm.
mov [Sides], bx
mov [bootdev], dl

mov ax, 0x2000
mov es, ax

mov di, skibidi
save_____that______filename:
	lodsb
	cmp al, 0
	je donasd
	mov [es:di], al
	inc di
	jmp save_____that______filename
donasd:

mov ax, 0x2000
mov ds, ax
mov ax, skibidi
call os_file_exists
jc halt


mov cx, 0x3000
call os_load_file

mov [es:end_of_file], bx

mov ax, 0x3000
mov ds, ax
mov ax, 0x2000
mov es, ax

mov si, 0
call go_to_first_line
jc halt
mov byte [line_counter], 1
call clear_but_ret


jmp test_start ;why 'test_start'? because i didn't build this off of old basic.
skib_buffer dw 0
;this is completely new. I started over and called it 'test_start', as opposed to old basic's 'start'.
test_loop: ;nice little debug mode that I made to test stuff
		   ; gives [offset_counter], newline, first three chars, then the line count after a few spaces, then next line until EOF
	mov ax, [es:offset_counter]
	call os_int_to_string
	mov di, ax
	call print
	mov di, enter_msg
	call print
	
	mov cx, 3
	.printout_loop:
		lodsb
		mov ah, 0eh
		int 0x10
		loop .printout_loop
		
	call prep_si
	mov di, es:prt_str
	call test_test_string
	jc do_something
	
	mov di, es:dec_str
	call test_test_string
	jc do_something_else


	mov ax, 0x0e20
	int 0x10
	int 0x10
	mov al, [es:line_counter]
	xor ah, ah
	call os_int_to_string
	mov di, ax
	call print
	
	
	
	mov ah, 0
	int 0x16
	afterwards_thingy:
	mov di, enter_msg
	call print
	
	
	call prep_si
	inc byte [es:line_counter]
	call find_next_line_but_better
	jc halt
	
	jmp test_loop
	
do_something:
	mov ax, 0x0e41
	int 0x10
	jmp afterwards_thingy
do_something_else:
	mov ax, 0x0e42
	int 0x10
	jmp $
	jmp afterwards_thingy
	
find_next_line_but_better:
	inc word [es:offset_counter]
	call prep_si
	cmp byte [si], 0
	je halt_skib
	cmp byte [si], 10
	jne find_next_line_but_better
	
	newer_newline:
		add word [es:offset_counter], 1
		call prep_si
		cmp byte [si], 10
		je newer_newline
		cmp byte [si], 13
		je find_next_line_but_better
		
		
		ret
test_test_string:
	test_test_string_loop:
	mov al, [ds:si]
	cmp al, 13
	je equal_strings
	cmp al, 32
	je equal_strings
	cmp al, 0
	je equal_strings
	inc si
	mov bl, [es:di]
	inc di
	cmp al, bl
	jne not_equal_strings
	jmp test_test_string_loop
	equal_strings:
		stc
		ret
	
	not_equal_strings:	
		call prep_si ;effective reset, because we never change it in the code.
		clc
		ret

halt_skib:
	stc
	ret
		
halt:
	mov ah, 0x02
	mov bh, 00
	mov dl, 0
	mov dh, 20
	int 0x10
	
	retf
	
	
no_file:
	mov di, no_file_thing
	call print
	ret
	
no_file_thing db 'No input file specified.', 0

test_start:	;======================================================================================================================================================================
	call prep_si
	mov di, prt_str
	call test_test_string
	jc prt_string_found
	
	mov di, mov_str
	call test_test_string
	jc mov_string_found
	
	mov di, sub_str
	call test_test_string
	jc sub_string_found
	
	mov di, add_str
	call test_test_string
	jc add_string_found
	
	mov di, def_str
	call test_test_string
	jc def_string_found
	
	mov di, dec_str
	call test_test_string
	jc dec_string_found
	
	mov di, inc_str
	call test_test_string
	jc inc_string_found
	
	mov di, del_str
	call test_test_string
	jc del_string_found
	
	mov di, bel_str
	call test_test_string
	jc bel_string_found
	
	mov di, cmp_str
	call test_test_string
	jc cmp_string_found
	
	mov di, jye_str
	call test_test_string
	jc jye_string_found
	
	mov di, jmp_str
	call test_test_string
	jc jmp_string_found
	
	mov di, jne_str
	call test_test_string
	jc jne_string_found
	
	mov di, jls_str
	call test_test_string
	jc jls_string_found
	
	mov di, jgr_str
	call test_test_string
	jc jgr_string_found
	
	mov di, cmpsr_str
	call test_test_string
	jc cmpsr_string_found
	
	mov di, getky_str
	call test_test_string
	jc getky_string_found
	
	mov di, ask_str
	call test_test_string
	jc ask_string_found
	
	mov di, rand_str
	call test_test_string
	jc rand_string_found
	
	mov di, clr_str
	call test_test_string
	jc clr_string_found
	
	mov di, int_str
	call test_test_string
	jc int_string_found
	
	jmp halt
	
syntax_error_halt:
	cmp byte [es:cmd_buf], 0
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
	retf
	


	
int_string_found:
	add word [es:offset_counter], 4
	call prep_si
	
	mov di, str1_str
	call test_test_string
	jc interize_str1
	
	mov di, str2_str
	call test_test_string
	jnc halt
	
	mov si, str2_str_string
	add si, [es:str2_offset]
	
	
	thingyd:
	push ds
	mov ax, 0x2000
	mov ds, ax
	
	call os_string_to_int
	pop ds
	
	mov [es:tmp_cx], ax
	
	add word [es:offset_counter], 5
	call prep_si
	
	call find_user_var_return
	jc halt
	
	mov ax, [es:tmp_cx]
	mov bl, [es:tmp_var_loc]
	xor bh, bh
	jmp write_and_return
	
interize_str1:
	mov si, str1_str_string
	add si, [es:str1_offset]
	jmp thingyd
	
	
	
clr_string_found:
	call clear_but_ret
	add word [es:offset_counter], 3
	jmp inc_and_rerun_three
	
rand_string_found:
	call os_seed_random
	add word [es:offset_counter], 4
	call prep_si
	mov ax, si
	call os_string_to_int
	add word [es:offset_counter], dx
	add si, dx
	inc word [es:offset_counter]
	inc si
	
	mov [es:first_rand], ax
	call prep_si
	mov ax, si
	call os_string_to_int
	add word [es:offset_counter], dx
	add si, dx
	inc word [es:offset_counter]
	inc si
	
	mov bx, ax
	mov ax, [es:first_rand]
	call os_get_random
	
	mov [es:first_rand], cx
	
	call prep_si
	call find_user_var_return
	jc halt
	
	xor bh, bh
	mov bl, [es:tmp_var_loc]
	
	mov ax, [es:first_rand]
	jmp write_and_return
	;cx has rand
first_rand dw 0
	
getky_string_found:
	add word [es:offset_counter], 6
	call prep_si
	
	cmp byte [ds:si], '"'
	je getky_with_quotes
	
	cmp byte [ds:si], '%'
	je get_nonwait
	;we assume that there can only be a number right now,
	;in which that is an ascii code to wait the corrosponding key to get pressed!
	call prep_si
	mov ax, si
	call os_string_to_int
	mov dl, al ;temp reg
	wait_for_that_key_loop:
		mov ah, 0
		int 16h
		
		cmp dl, al
		jne wait_for_that_key_loop
	dec word [es:offset_counter]
	jmp inc_and_rerun_three
	
getky_with_quotes:
	inc si ; get past " and to the char we want.
	lodsb
	mov dl, al
	jmp wait_for_that_key_loop

get_nonwait:
	add word [es:offset_counter], 2
	call prep_si
	
		mov ah, 0x01
		int 16h
		jz there_was_no_keypress    ; wait for key press
    
		mov ah, 0x00
		int 16h
		;we save this character to the var defined.
		mov [es:placeholder2], al
		call find_user_var_return
		jc halt
		
		xor ah, ah
		mov al, [es:placeholder2]
		xor bh, bh
		mov bl, [es:tmp_var_loc]
		jmp write_and_return
		
	there_was_no_keypress:
		inc word [es:offset_counter]
		call prep_si
		cmp byte [ds:si], 32
		jne there_was_no_keypress
		inc word [es:offset_counter]
		call prep_si
		
		jmp only_numbers_allowed
	
	
def_string_found:
	add word [es:offset_counter], 4
	call prep_si


	mov di, cmd_buf
	mov cx, 3
	mov dx, 0
	get_the_varname:
		lodsb
		stosb
		cmp al, 0dh
		je stop_getting
		inc dx
		loop get_the_varname ;get the filename.
	stop_getting:
		mov di, cmd_buf
		add di, dx
		mov al, 32
		repe stosb
	
	
	cmp byte [es:varcount], 30 ;checks if we are at 30 user vars
	jge halt
	
	mov di, varnames
	mov bx, cmd_buf
	mov dx, -1
		;find a open spot in varnames to save it
		find_varnames_open_spot: 
			mov al, [es:di] ;we find out what is the newest open variable spot.
			inc di
			inc dx
			cmp al, '?'
			jne find_varnames_open_spot
			mov bx, cmd_buf
			mov di, varnames
			add di, dx
			mov cx, 3
			save_the_filename_to_the_buffer:
				mov al, [es:bx]
				inc bx
				stosb
				loop save_the_filename_to_the_buffer
				
			mov ax, dx
			xor dx, dx
			mov bx, 3
			div bx
			;quotient in ax 
			mov di, es:varlocs ;wow am i stupid. FOR SOME GOOFY REASON, every thing in this file when not using SI should be prefixed with ES:
			add di, ax 
			;inc di ;why i need to do this just to init a var as 0, IDK but it works!
			;as is with everything in this codebase, am i right?
			mov word [es:di], 0
			
		
		inc byte [es:varcount]
		sub word [es:offset_counter], 1
		
		jmp inc_and_rerun_three
		
		
	reset_str1_offset:
		mov word [es:str1_offset], 00
		sub word [offset_counter], 2

		jmp inc_and_rerun_three
	reset_str2_offset:
		mov word [str2_offset], 00
		sub word [offset_counter], 2
		jmp inc_and_rerun_three
	
ask_string_found:
	add word [es:offset_counter], 4
	call prep_si
	
	mov di, str1_str
	call test_test_string
	jc ask_str1
	
	mov di, str2_str
	call test_test_string
	jnc halt
	
	mov di, str2_str_string
	add di, [es:str2_offset]
	mov cx, 59
	sub cx, [es:str2_offset]
	
	get_all_chars_loop_before:
	
	mov ah, 2
	xor bh, bh
	mov dx, 0x1500
	int 0x10
	mov ax, 0x0e10
	int 0x10
	
	get_all_chars_loop:
		mov ah, 0
		int 16h
		
		cmp al, 13
		je done_storing_strings
		cmp al, 8
		je do_backspace
		mov ah, 0eh
		int 0x10
		stosb
		loop get_all_chars_loop
		
	done_storing_strings:
	
	mov ah, 2
	xor bh, bh
	mov dx, 0x1500
	int 0x10
	
	mov cx, 59
	mov ax, 0x0e20
	rep_int_0x10:
		int 0x10
		loop rep_int_0x10
	
	sub word [es:offset_counter], 2
	jmp inc_and_rerun_three
	
do_backspace:
	dec di
	mov di, backspace_msg
	call print
	inc cx
	jmp get_all_chars_loop
	
ask_str1:
	mov cx, 59
	sub cx, [es:str1_offset]
	mov di, str1_str_string
	add di, [es:str1_offset]
	jmp get_all_chars_loop_before
	
cmpsr_string_found:
	mov di, str1_str_string
	mov bx, str2_str_string
	dec bx
	compare_that_string:
		inc bx
		mov al, [es:di]
		cmp al, 0
		je end_of_a_string
		inc di
		cmp al, [es:bx]
		je compare_that_string
		after_compared_string_false:
		mov byte [es:jne_flag], 1
		jmp inc_and_rerun_three
	end_of_a_string:
		cmp byte [es:bx], 0
		jne after_compared_string_false
		mov byte [es:jye_flag], 1
		jmp inc_and_rerun_three
	
	
	
jgr_string_found:
	cmp byte [es:jgr_flag], 1
	jne inc_and_rerun_three
	
	jmp jmp_string_found

jne_string_found:
	cmp byte [es:strings_not_equal], 1
	je jmp_string_found
	cmp byte [es:jne_flag], 1
	je jmp_string_found
	
	jmp inc_and_rerun_three

jye_string_found:
	cmp byte [es:strings_equal], 1
	je jmp_string_found
	
	cmp byte [es:jye_flag], 1
	je jmp_string_found

	jmp inc_and_rerun_three
	
jls_string_found:
	cmp byte [es:jls_flag], 1
	jne inc_and_rerun_three
	jmp jmp_string_found
	
jmp_string_found:
	add word [es:offset_counter], 4
	call prep_si
	
	;only numbers allowed
	only_numbers_allowed:
	mov ax, si
	call os_string_to_int
	
	
	cmp ax, 0
	je special_case_jump
	
	call go_to_first_line
	dec ax
	mov cx, ax
	loop_newlines:
		push cx
		call prep_si
		call find_next_line_but_better
		pop cx
		loop loop_newlines
	
	jmp test_start ;no need for inc_and_rerun_three because we already got to the desired line.
	special_case_jump:
		mov word [es:offset_counter], 0
		call prep_si
		call go_to_first_line
		
		mov byte [es:jye_flag], 0
		mov byte [es:jne_flag], 0
		mov byte [es:jgr_flag], 0
		mov byte [es:jls_flag], 0
		
		jmp test_start
	
cmp_string_found:
	;i dont want to do this
	add word [es:offset_counter], 4
	call prep_si
	
	mov di, xxx_str
	call test_test_string
	jc cmp_xxx_before
	
	mov di, yyy_str
	call test_test_string
	jc cmp_yyy_before
	
	call prep_si
	call find_user_var_return
	jnc cmp_var_before
	;CANNOT BE A NUMBER. We MUST syntax error halt right here. 
	jmp halt
	cmp_secondary:
	;this can be a number.
	mov dx, [es:line_counter2]
	inc dx
	add [es:offset_counter], dx
	call prep_si
	mov di, xxx_str
	call test_test_string
	jc cmp_xxx_after
	
	mov di, yyy_str
	call test_test_string
	jc cmp_yyy_after
	
	call find_user_var_return
	jnc comparisons ;efficiency
	
	call prep_si
	mov ax, si 
	call os_string_to_int
	;these functions will pass their value in AX, then we will check with [es:placeholder].
	;yes, even xxx and yyy.
	comparisons:
	cmp ax, [es:placeholder]
	je equal_comparison
	mov byte [es:jne_flag], 1
	second_comparison:
	cmp ax, [es:placeholder]
	jl greater_comparison
	mov byte [es:jls_flag], 1
	jmp inc_and_rerun_three

	cmp_xxx_before:
		
		xor ah, ah
		mov al, [es:cursor_x]
		mov [es:placeholder], ax
		mov word [es:line_counter2], 3
		jmp cmp_secondary
	cmp_yyy_before:
		xor ah, ah
		mov al, [es:cursor_y]
		mov [es:placeholder], ax
		mov word [es:line_counter2], 3
		jmp cmp_secondary
	cmp_var_before:
		mov [es:placeholder], ax
		jmp cmp_secondary
	cmp_xxx_after:
		xor ah, ah
		mov al, [es:cursor_x]
		jmp comparisons
	cmp_yyy_after:
		xor ah, ah
		mov al, [es:cursor_y]
		jmp comparisons
	equal_comparison:
		mov byte [es:jye_flag], 1
		jmp inc_and_rerun_three
	greater_comparison:
		mov byte [es:jgr_flag], 1
		jmp inc_and_rerun_three

bel_string_found:
	;first param is frequency, then amount of time to do that. 
	add word [es:offset_counter], 4
	call prep_si
	call find_user_var_return
	jnc bel_play_sound
	
	call prep_si
	mov ax, si
	call os_string_to_int
	
	bel_play_sound:
	mov [es:placeholder], ax
	call play_sound
	
	bel_part_two:
	add word [es:offset_counter], 4
	call prep_si
	call find_user_var_return
	jnc delay_and_stop_note
	call prep_si
	mov ax, si
	call os_string_to_int
	
	delay_and_stop_note:
	mov bx, ax
	call delay
	call stop_note
	jmp inc_and_rerun_three
	
	

del_string_found:
	add word [es:offset_counter], 4
	call prep_si
	
	call find_user_var_return
	jnc effient_delay
	call prep_si ;effective reset of si.
	
	;must be a number. I am not allowing you fools to wait for [es:cursor_x or y] amount of time. That is just stupid.
	mov ax, si
	call os_string_to_int
	
	effient_delay:
	mov bx, ax 
	call delay
	
	jmp inc_and_rerun_three ;Im a genius for this one
	
inc_string_found:
	add word [es:offset_counter], 4
	call prep_si
	
	mov di, xxx_str
	call test_test_string
	jc inc_xxx
	
	mov di, yyy_str
	call test_test_string
	jc inc_yyy
	
	call find_user_var_return
	jnc inc_user_var
	
	jmp halt
	
inc_xxx:
	inc byte [es:cursor_x]
	jmp inc_and_rerun_three

inc_yyy:
	inc byte [es:cursor_y]
	jmp inc_and_rerun_three
inc_user_var:
	inc ax
	mov bl, [es:tmp_var_loc]
	xor bh, bh
	jmp write_and_return

dec_string_found:
	add word [es:offset_counter], 4
	call prep_si
	
	mov di, xxx_str
	call test_test_string
	jc dec_xxx
	
	mov di, yyy_str
	call test_test_string
	jc dec_yyy
	
	call find_user_var_return
	jnc dec_user_var
	
	jmp halt
	
dec_xxx:
	dec byte [es:cursor_x]
	jmp inc_and_rerun_three

dec_yyy:
	dec byte [es:cursor_y]
	jmp inc_and_rerun_three
dec_user_var:
	dec ax
	mov bl, [es:tmp_var_loc]
	xor bh, bh
	jmp write_and_return
	
		
add_string_found:
	add word [es:offset_counter], 4
	call prep_si
	
	mov di, xxx_str
	call test_test_string
	jc add_take_xxx
	
	mov di, yyy_str
	call test_test_string
	jc add_take_yyy
	
	call find_user_var_return ;is there a var in the first param?
	jnc add_var_to_placeholder
	call prep_si
	mov di, str1_str
	call test_test_string
	jc add_take_str1
	
	mov di, str2_str
	call test_test_string
	jc add_take_str2
	call prep_si
	mov ax, si
	call os_string_to_int
	
	mov [es:placeholder], ax ;used for other stuff in this subroutine
	
	mov [es:placeholder2], al
	mov word [es:line_counter2], 3
	
	add_afterwards:
	mov dx, [es:line_counter2]
	inc dx
	add [es:offset_counter], dx
	call prep_si
	
	mov di, xxx_str
	call test_test_string
	jc add_xxx_2
	
	mov di, yyy_str
	call test_test_string
	jc add_yyy_2
	
	call find_user_var_return
	jnc add_a_var_after
	
	call prep_si
	mov di, str1_str
	call test_test_string
	jc add_str1_2
	
	mov di, str2_str
	call test_test_string
	jc add_str2_2
	
	jmp halt
add_take_str1:
	mov di, str1_str_string
	add di, [es:str1_offset]
	mov al, [es:di]
	xor ah, ah
	mov [es:placeholder], ax
	mov [es:placeholder2], al
	mov word [es:line_counter2], 4
	jmp add_afterwards
add_take_str2:
	mov di, str2_str_string
	add di, [es:str2_offset]
	mov al, [es:di]
	xor ah, ah
	mov [es:placeholder], ax
	mov [es:placeholder2], al
	mov word [es:line_counter2], 4
	jmp add_afterwards
add_str1_2:
	mov ax, [es:placeholder]
	mov di, str1_str_string
	add di, [es:str1_offset]
	add [es:di], al
	jmp inc_and_rerun_three
add_str2_2:
	mov al, [es:placeholder2]
	mov di, str2_str_string
	add di, [es:str2_offset]
	add [es:di], al
	jmp inc_and_rerun_three	
	
add_take_xxx:
	mov al, [es:cursor_x]
	mov [es:placeholder2], al 
	xor ah, ah
	mov [es:placeholder], ax
	mov word [es:line_counter2], 3
	jmp add_afterwards
add_take_yyy:
	mov al, [es:cursor_x]
	mov [es:placeholder2], al 
	xor ah, ah
	mov [es:placeholder], ax
	mov word [es:line_counter2], 3
	jmp add_afterwards
	
add_xxx_2:
	mov al, [es:placeholder2]
	add [es:cursor_x], al 
	jmp inc_and_rerun_three
	
add_yyy_2:
	mov al, [es:placeholder2]
	add [es:cursor_y], al 
	jmp inc_and_rerun_three
	
add_var_to_placeholder:
	mov [es:placeholder], ax
	mov [es:placeholder2], al
	call prep_si
	jmp add_afterwards
	
add_a_var_after:
	add ax, [es:placeholder]
	mov bl, [es:tmp_var_loc]
	xor bh, bh
	jmp write_and_return

sub_string_found:
	add word [es:offset_counter], 4
	call prep_si
	
	mov di, xxx_str
	call test_test_string
	jc sub_take_xxx
	
	mov di, yyy_str
	call test_test_string
	jc sub_take_yyy
	
	call find_user_var_return ;is there a var in the first param?
	jnc sub_var_to_placeholder
	
	call prep_si
	mov di, str1_str
	call test_test_string
	jc sub_take_str1
	
	mov di, str2_str
	call test_test_string
	jc sub_take_str2
	
	call prep_si
	mov ax, si
	call os_string_to_int
	
	mov [es:placeholder], ax ;used for other stuff in this subroutine
	
	mov [es:placeholder2], al
	mov word [es:line_counter2], 3
	
	sub_afterwards:
	mov dx, [es:line_counter2]
	inc dx
	add [es:offset_counter], dx
	call prep_si
	
	mov di, xxx_str
	call test_test_string
	jc sub_xxx_2
	
	mov di, yyy_str
	call test_test_string
	jc sub_yyy_2
	
	call find_user_var_return
	jnc sub_a_var_after
	
	call prep_si
	mov di, str1_str
	call test_test_string
	jc sub_str1_2
	
	mov di, str2_str
	call test_test_string
	jc sub_str2_2
	
	jmp halt
	
sub_take_str1:
	mov di, str1_str_string
	add di, [es:str1_offset]
	mov al, [es:di]
	xor ah, ah
	mov [es:placeholder], ax
	mov [es:placeholder2], al
	mov word [es:line_counter2], 4
	jmp sub_afterwards
sub_take_str2:
	mov di, str2_str_string
	add di, [es:str2_offset]
	mov al, [es:di]
	xor ah, ah
	mov [es:placeholder], ax
	mov [es:placeholder2], al
	mov word [es:line_counter2], 4
	jmp sub_afterwards
sub_str1_2:
	mov ax, [es:placeholder]
	mov di, str1_str_string
	add di, [es:str1_offset]
	sub [es:di], al
	jmp inc_and_rerun_three
sub_str2_2:
	mov al, [es:placeholder2]
	mov di, str2_str_string
	add di, [es:str2_offset]
	sub [es:di], al
	jmp inc_and_rerun_three	
	
sub_take_xxx:
	mov al, [es:cursor_x]
	mov [es:placeholder2], al 
	xor ah, ah
	mov [es:placeholder], ax
	mov word [es:line_counter2], 3
	jmp sub_afterwards
sub_take_yyy:
	mov al, [es:cursor_x]
	mov [es:placeholder2], al 
	xor ah, ah
	mov [es:placeholder], ax
	mov word [es:line_counter2], 3
	jmp sub_afterwards
	
sub_xxx_2:
	mov al, [es:placeholder2]
	sub [es:cursor_x], al 
	jmp inc_and_rerun_three
	
sub_yyy_2:
	mov al, [es:placeholder2]
	sub [es:cursor_y], al 
	jmp inc_and_rerun_three
	
sub_var_to_placeholder:
	mov [es:placeholder], ax
	mov [es:placeholder2], al
	call prep_si
	jmp sub_afterwards
	
sub_a_var_after:
	xchg ax, [es:placeholder]
	sub ax, [es:placeholder]
	mov bl, [es:tmp_var_loc]
	xor bh, bh
	jmp write_and_return

mov_string_found: ;for strings: you can mov a string "hi" to a string storage area. Or, you can move a value to wherever the string offset it, or you can, using O as a prefix, set the offset.
	add word [es:offset_counter], 4
	call prep_si
	
	cmp byte [ds:si], '"' ;marks storing a string
	je store_a_string
	
	cmp byte [ds:si], 'O'
	je set_string_offset
	
	mov di, xxx_str
	call test_test_string
	jc mov_take_xxx
	
	mov di, yyy_str
	call test_test_string
	jc mov_take_yyy
	
	mov di, str1_str
	call test_test_string
	jc mov_take_str1
	
	mov di, str2_str
	call test_test_string
	jc mov_take_str2

	call find_user_var_return ;is there a var in the first param?
	jnc var_to_placeholder
	
	call prep_si
	
	mov ax, si
	call os_string_to_int
	
	mov [es:placeholder], ax ;used for other stuff in this subroutine
	
	mov [es:placeholder2], al
	mov word [es:line_counter2], dx ;dx is amount of chars that the number was
	
	afterwards:
	mov dx, [es:line_counter2]
	inc dx
	add [es:offset_counter], dx
	call prep_si
	
	mov di, xxx_str
	call test_test_string
	jc mov_xxx_2
	
	mov di, yyy_str
	call test_test_string
	jc mov_yyy_2
	
	mov di, str1_str
	call test_test_string
	jc mov_str1_2
	
	mov di, str2_str
	call test_test_string
	jc mov_str2_2
	
	call find_user_var_return
	jnc mov_a_var_after
	jmp halt
	
mov_take_str1:
	mov di, str1_str_string
	add di, [es:str1_offset]
	xor ah, ah
	mov al, [es:di]
	mov [es:placeholder], ax
	mov [es:placeholder2], al
	mov word [es:line_counter2], 4
	jmp afterwards
mov_take_str2:
	mov di, str2_str_string
	add di, [es:str2_offset]
	xor ah, ah
	mov al, [es:di]
	mov [es:placeholder], ax
	mov [es:placeholder2], al
	mov word [es:line_counter2], 4
	jmp afterwards
	
mov_str1_2:
	mov di, str1_str_string
	add di, [es:str1_offset]
	mov al, [es:placeholder2]
	mov [es:di], al
	jmp inc_and_rerun_three
mov_str2_2:
	mov di, str2_str_string
	add di, [es:str2_offset]
	mov al, [es:placeholder2]
	mov [es:di], al
	jmp inc_and_rerun_three
	
mov_take_xxx:
	mov al, [es:cursor_x]
	mov [es:placeholder2], al 
	xor ah, ah
	mov [es:placeholder], ax
	mov word [es:line_counter2], 3
	jmp afterwards
mov_take_yyy:
	mov al, [es:cursor_x]
	mov [es:placeholder2], al 
	xor ah, ah
	mov [es:placeholder], ax
	mov word [es:line_counter2], 3
	jmp afterwards
	
	
mov_xxx_2:
	mov al, [es:placeholder2]
	mov [es:cursor_x], al 
	jmp inc_and_rerun_three
	
mov_yyy_2:
	mov al, [es:placeholder2]
	mov [es:cursor_y], al 
	jmp inc_and_rerun_three
	
var_to_placeholder:
	mov [es:placeholder], ax
	mov [es:placeholder2], al
	call prep_si
	jmp afterwards
	
mov_a_var_after:
	mov ax, [es:placeholder]
	
	mov bl, [es:tmp_var_loc]
	xor bh, bh
	jmp write_and_return
	
store_a_string:
	mov dx, [es:offset_counter]
	call prep_si
	call find_next_line;genius move right here
	call prep_si
	sub word [es:offset_counter], 6
	sub si, 6
	
	mov di, str1_str
	call test_test_string
	jc after_found_string1_store
	
	mov di, str2_str
	call test_test_string
	jnc halt
	
	;must be string 2
	mov di, str2_str_string
	add di, [es:str2_offset]
	jmp save_the_string
	
	after_found_string1_store:
	mov di, str1_str_string
	add di, [es:str1_offset]
	
	save_the_string:
		mov [es:offset_counter], dx
		call prep_si
		inc si ;we were at the "
		mov [es:offset_counter], si
		save_loop:
			mov al, [ds:si]
			inc si
			cmp al, '"'
			je done_saving
			mov [es:di], al
			inc di
			jmp save_loop
		done_saving:
			mov byte [es:di], 0
			call prep_si
			jmp inc_and_rerun_three
	
set_string_offset:
	inc word [es:offset_counter]
	call prep_si
	
	mov di, str1_str
	call test_test_string
	jc take_offset_from_str1
	
	call prep_si
	
	mov di, str2_str
	call test_test_string
	jc take_offset_from_str2
	
	call prep_si
	call find_user_var_return
	jnc take_user_var
	
	;must be a number
	call prep_si
	
	mov ax, si
	call os_string_to_int
	mov [es:line_counter2], dx
	mov [es:placeholder2], al
	
	afterwards_offset:
	mov dx, [es:line_counter2]
	inc dx
	add [es:offset_counter], dx
	call prep_si
	
	mov di, str1_str
	call test_test_string
	jc store_offset_at_str1
	
	mov di, str2_str
	call test_test_string
	jnc halt
	
	mov al, [es:placeholder2]
	mov [es:str2_offset], al
	sub word [es:offset_counter], 2
	jmp inc_and_rerun_three
	
store_offset_at_str1:
	mov al, [es:placeholder2]
	mov [es:str1_offset], al
	sub word [es:offset_counter], 2
	call prep_si
	jmp inc_and_rerun_three
	
take_user_var:
	mov [es:placeholder2], al

	jmp afterwards_offset
	
take_offset_from_str1:
	mov al, [es:str1_offset]
	thingy_thingy_thingy:
	mov [es:placeholder2], al
	mov byte [es:line_counter2], 4
	jmp afterwards_offset
take_offset_from_str2:
	mov al, [es:str2_offset]
	jmp thingy_thingy_thingy
	
	
	
prt_string_found:
	cmp byte [es:cursor_y], 24
	jle dont_set_cursor
	mov byte [es:cursor_y], 24
	dont_set_cursor:
	mov ah, 0x02
	mov dl, [es:cursor_x]
	mov dh, [es:cursor_y]
	mov bh, 0
	int 0x10
	add word [es:offset_counter], 4
	call prep_si
	lodsb
	
	cmp al, '"'
	je print_a_string
	
	call prep_si
	
	call find_user_var_return
	jnc found_a_var_to_print
	
	call prep_si
	mov di, str1_str
	call test_test_string
	jc print_str1
	
	mov di, str2_str
	call test_test_string
	jc print_str2
	
	jmp halt
print_str1:
	mov di, str1_str_string
	add di, [es:str1_offset]
	call print
	jmp inc_and_rerun_three
print_str2:
	mov di, str2_str_string
	add di, [es:str2_offset]
	call print
	jmp inc_and_rerun_three

print_a_string:
		inc word [es:offset_counter]
		print_out_the_string:
			lodsb
			inc word [es:offset_counter]
			cmp al, '"'
			je done_printing
			mov ah, 0eh
			int 0x10
			jmp print_out_the_string
			done_printing:
				jmp inc_and_rerun_three
			
	
	
found_a_var_to_print:
	call os_int_to_string ;var data already in ax, so we convert to string and print it.
	mov di, ax
	call print
	
	sub word [es:offset_counter], 2
	call prep_si
	jmp inc_and_rerun_three
	
	
	
prep_si:
	xor si, si
	mov si, [es:offset_counter]
	ret
	
inc_and_rerun_three:
	sub word [offset_counter], 2
	
	call prep_si
	call find_next_line_but_better ;should be all we need
	jc halt
	call prep_si
	
	
	jmp test_start
	

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
	jmp find_next_line_but_better


	
go_to_first_line:
	mov word [es:offset_counter], 0
	call prep_si
	do_the_thing:
	cmp byte [ds:si], 13
	jne found_the_first_line
	add si, 2
	add word [es:offset_counter], 2
	jmp do_the_thing
	
found_the_first_line:
	clc
	ret
special_first_line:
	stc
	ret


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
		mov byte [di+1], 0
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
	mov al, [es:di]
	cmp al, 0
	je done_di
	mov ah, 0x0e
	int 0x10
	inc di
	jmp print
done_di:
	ret

test_string:
	push ds
	mov ax, 0x2000
	mov ds, ax
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
	pop ds
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
	mov ax, [es:placeholder]
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
	mov ax, 0x0700
	int 0x10
	mov bh, 0x07
	mov cx, 0
	mov dx, 0x1950
	int 0x10
	popa
	
	sub word [offset_counter], 2
	jmp inc_and_rerun_two

clear_but_ret:
	pusha
	mov ah, 07h        ; Scroll up function
	mov al, 0          ; Clear entire screen (scroll all lines)
	mov bh, 0x07
	mov cx, 0000h      ; Upper left corner (row 0, col 0)
	mov dx, 184FH      ; Lower right corner (row 24, col 79)
	int 10h
	popa

	ret

find_user_var_return:
	
	mov di, cmd_buf
	mov cx, 3
	mov dx, 0
	get_the_varnames:
		lodsb
		stosb
		cmp al, 0dh
		je stop_gettings
		cmp al, 0
		je stop_gettings
		cmp al, 32
		je stop_gettings
		inc dx
		loop get_the_varnames ;get the filename.
	stop_gettings:
		mov word [es:line_counter2], dx
		mov di, cmd_buf
		add di, dx
		mov al, 32
		repe stosb
	
		
		
		;now we have to go through varnames and see if it is a valid variable, three bytes at a time!
		mov bx, cmd_buf
		
		mov di, varnames
		
		mov dx, 0
		compare_varnames:
			mov al, [es:bx]
			cmp al, [es:di]
			jne not_equal_varchars
			
			mov al, [es:bx+1]
			cmp al, [es:di+1]
			jne not_equal_varchars
			
			mov al, [es:bx+2]
			cmp al, [es:di+2]
			jne not_equal_varchars
		
			
			
			mov ax, dx
			;pusha
			;call os_int_to_string
			;mov di, ax
			;call print
			;mov ah, 0
			;int 0x16
			;popa
			mov di, es:varlocs
			add di, dx
			add di, dx
			
			
			mov [es:tmp_var_loc], dl ;pretty sure this is how this works...
			
			mov ax, [es:di] ;and it is! tmp_var_loc is used for writing back user variables. Kind of genius.
			clc
			ret
			
		not_equal_varchars:
			inc dx
			add di, 3
			cmp dx, 30
			jle compare_varnames
			stc
			ret
			
			

write_word_user_var:
	mov di, es:varlocs
	add di, bx
	add di, bx
	mov word [es:di], ax

	ret
	
write_and_return:
	sub word [es:offset_counter], 4
	call write_word_user_var
	call prep_si
	jmp inc_and_rerun_three
	
	
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
cmp_str db 'cmp', 0;compare a number and a var, OR var and a var
jye_str db 'jye', 0 ;jump if equal
jne_str db 'jne', 0 ;jump if not equal
hlt_str db 'hlt', 0 ;stop program instantly
del_str db 'del', 0 ;delays for numbers ticks
jgr_str db 'jgr', 0 ;jump if greater
jls_str db 'jls', 0 ;jump if lesser
non_str db 'non', 0 ;used for jump commands to skip the page changing process, making it faster WOW THATS OLD
rem_str db 'rem', 0 ;used to make comments, code is about 5 lines! (they are for identifying the command!!!)
bel_str db 'bel', 0 ;two params, first is frequency which is either var or num, then set num for the second param X
getky_str db 'getky', 0 ;two params, key looking for in quotes, non if any, and then var to save to if first param is not non
ask_str db 'ask', 0 ;takes in one param, and that is the string name. Either st1 or st2
def_str db 'def', 0 ;one param, volatile up to 3 char variable defined and set to zero X
cmpsr_str db 'cmpsb', 0 ;no params as there is only two strings to compare WHY THE FREAK I NAMED IT 'CMPSR', I HAVE NO IDEA. CMPSB IS MUCH BETTER.
rand_str db 'rnd', 0 ;takes in THREE PARAMS (scary) first two are bounds and last is variable to save it too (sorry no strings)
int_str db 'int', 0 ;two params, first the string (with offset) that will be converted into an int at var param two.

;error messages and hlt message
syntax_error db 'Syntax error on line ', 0
;new variables test
varnames db 90 dup('?'), 0
varlocs times 30 dw 0
varcount db 0 ;should go up to 30
tmp_var_loc db 0
;how vars will work: user stores a varname (3 chars OR until a newline char, if that case then pad with space in varnames), then it copies to the next availiable place in varnames if space, incrementing varcount
;if you want to retrieve a value, then you will search through varnames 3 chars at a time for the varname until you find it, incrementing a temporary value as you go
;then when you do that, add the temporary value to si when it points to varlocs, and then save the value to another temporary register.
;yay!
;okay so varlocs is actually just the place to hold variable data

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
offset_counter dw 0
note_duration dw 0
note_frequency dw 0
tmp_cx dw 0


; placeholder for integer to string conversion
;placeholder_str_int db '000', 0
placeholder dw 0
placeholder2 db 0
prompt db '> ', 0

input_string_thing db 'String: ', 0
skibidi times 12 db 0
%include "./extra/functions.asm"
disk_buffer db 24576
end_of_file dw 0
;this line count should not be anything but 1365. 
;just kidding its 1614
;just kidding x2 its 1706
;just kidding x3 its 1767
;just kidding x4 its 1795
;just kidding x5 its 
dirlist: