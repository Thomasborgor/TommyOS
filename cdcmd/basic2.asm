[bits 16]
; How basic will work:
; We will run through the program once at start.
; When doing this, on every line, we will identify the command and save it's opcode to a buffer.
; We will also save this lines offset from 0x3000:0x0000 in the next indicie.
; This will, in theory, make it very fast.
; Maybe.

mov cx, 0x2000
mov es, cx
mov [es:SecsPerTrack], ax ;why not prefixed with ES:? because then I would have to change pretty much all of functions.asm.
mov [es:Sides], bx
mov [es:bootdev], dl

mov di, filename_buffer
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
mov ax, filename_buffer
call os_file_exists
jc halt


mov cx, 0x3000
call os_load_file
jc halt

mov [es:end_of_file], bx

mov ax, 0x3000
mov es, ax ;swapping this, what way only SI has to have es on it.
mov ax, 0x2000
mov ds, ax

;mov [variables+(546*2)], word 1234

mov si, 0
mov byte [line_counter], 1
cmp byte [es:si], 13
jg start_parsing


start_loop:
call next_line
jc start_running_code

start_parsing:
;call get_cmd
;mov di, cmd_buf
;call printd
;mov ax, 0x0e01
;int 0x10
;call get_cmd
;mov di, cmd_buf
;call printd
;
;jmp $

call get_cmd
jc start_running_code

mov bx, prt_str
call cmp_str
jc add_prt

mov bx, mov_str
call cmp_str
jc add_mov

mov bx, add_str
call cmp_str
jc add_add

mov bx, sub_str
call cmp_str
jc add_sub

mov bx, jmp_str
call cmp_str
jc add_jmp

mov bx, inc_str
call cmp_str
jc add_inc

mov bx, dec_str
call cmp_str
jc add_dec

mov bx, cmd_str
call cmp_str
jc add_cmp

mov bx, jne_str
call cmp_str
jc add_jne

mov bx, jye_str
call cmp_str
jc add_jye

mov bx, jgr_str
call cmp_str
jc add_jge

mov bx, jls_str
call cmp_str
jc add_jls

mov di, error_msg
call printd

halt:
retf

error_msg db "Your code has a syntax error.", 0

add_prt:
push si
call get_cmd
pop si
mov [si_counter], si
mov di, cmd_buf

cmp byte [di], '"'
je .no_var
mov di, cmd_buf
cmp byte [di], 'a'
jl .two
sub byte [di], 32
.two:
inc di
cmp byte [di], 'a'
jl .three
sub byte [di], 32
.three:
xor ax, ax
dec di
mov al, [di]
sub al, 'A'
mov cl, 26
mul cl
mov bl, [di+1]
sub bl, 'A'
movzx bx, bl
add ax, bx
add ax, ax
mov bx, ax
mov ax, 1
mov cx, 0xabcd
jmp save_bytecode

.no_var:
mov ax, 1
mov bx, 0xffff
mov cx, 0xffff
;cx and bx can just be junk
jmp save_bytecode
add_mov:
;inc word [si_counter]
call get_cmd
cmp [cmd_buf], byte 'A'
jge .first_is_a_var
mov si, cmd_buf
call os_string_to_int
mov dx, ax

.next:
call get_cmd
mov di, cmd_buf
mov al, [di]
mov [var_buffer], al
mov al, [di+1]
mov [var_buffer+1], al
push dx
call var_to_int
add ax, ax
pop dx

mov cx, ax
mov bx, dx

mov ax, 2
jmp save_bytecode
.first_is_a_var:
mov di, cmd_buf
mov al, [di]
mov [var_buffer], al
mov al, [di+1]
mov [var_buffer+1], al
call var_to_int
add ax, ax

or ax, 0x8000

mov dx, ax
jmp .next
add_add:
call get_cmd
mov si, cmd_buf
call os_string_to_int
mov dx, ax

call get_cmd
mov di, cmd_buf
mov al, [di]
mov [var_buffer], al
mov al, [di+1]
mov [var_buffer+1], al
push dx
call var_to_int
add ax, ax
pop dx

mov cx, ax
mov bx, dx

mov ax, 3
jmp save_bytecode
add_clr:
mov ax, 4
jmp save_bytecode
add_sub:
call get_cmd
mov si, cmd_buf
call os_string_to_int
mov dx, ax

call get_cmd
mov di, cmd_buf
mov al, [di]
mov [var_buffer], al
mov al, [di+1]
mov [var_buffer+1], al
push dx
call var_to_int
add ax, ax
pop dx

mov cx, ax
mov bx, dx

mov ax, 5
jmp save_bytecode
add_jmp:

call get_cmd
mov si, cmd_buf
call os_string_to_int
dec ax
mov bx, ax
mov ax, 6

jmp save_bytecode
add_inc:
call get_cmd
mov di, cmd_buf
mov al, [di]
mov [var_buffer], al
mov al, [di+1]
mov [var_buffer+1], al

call var_to_int
add ax, ax
mov bx, ax

mov ax, 7
jmp save_bytecode
add_dec:
call get_cmd
mov di, cmd_buf
mov al, [di]
mov [var_buffer], al
mov al, [di+1]
mov [var_buffer+1], al

call var_to_int
add ax, ax

mov bx, ax

mov ax, 8
jmp save_bytecode
add_cmp:

call get_cmd
cmp [cmd_buf], byte 'A'
jge .isvar
mov si, cmd_buf
call os_string_to_int
mov dx, ax
push dx
jmp .three
.isvar:
mov di, cmd_buf
mov al, [di]
mov [var_buffer], al
mov al, [di+1]
mov [var_buffer+1], al

call var_to_int
add ax, ax
mov dx, ax

.three:
call get_cmd
mov di, cmd_buf
mov al, [di]
mov [var_buffer], al
mov al, [di+1]
mov [var_buffer+1], al
call var_to_int
add ax, ax
pop dx
mov cx, ax
mov bx, dx


mov ax, 9
jmp save_bytecode
add_jye:
call get_cmd
mov si, cmd_buf
call os_string_to_int
dec ax
mov bx, ax

mov ax, 10
jmp save_bytecode
add_jne:
call get_cmd
mov si, cmd_buf
call os_string_to_int
dec ax
mov bx, ax
mov ax, 11
jmp save_bytecode
add_hlt:
mov ax, 12
jmp save_bytecode
add_jge:
call get_cmd
mov si, cmd_buf
call os_string_to_int
dec ax
mov bx, ax
mov ax, 13
jmp save_bytecode
add_jls:
call get_cmd
mov si, cmd_buf
call os_string_to_int
dec ax
mov bx, ax
mov ax, 14
jmp save_bytecode


save_bytecode:
mov di, bytecode_buffer
add di, [bytecode_idx]
mov word [di], ax
inc di
mov word [di], si
call prep_si
jc halt
add di, 2
mov [di], bx
add di, 2
mov [di], cx
add word [bytecode_idx], 7 ; move over adr word, then save space for two more words if needed.
jmp start_loop


start_running_code:

mov ax, [bytecode_idx]
mov [max_bytecode_idx], ax
mov word [bytecode_idx], 0


parse:
mov ax, [bytecode_idx]
mov cx, 7
mul cx
mov bx, ax
cmp ax, [max_bytecode_idx]
jg halt
cmp [bytecode_buffer+bx], byte 1
je parse_prt
cmp [bytecode_buffer+bx], byte 2
je parse_mov
cmp [bytecode_buffer+bx], byte 3
je parse_add
cmp [bytecode_buffer+bx], byte 5
je parse_sub
cmp [bytecode_buffer+bx], byte 6
je parse_jmp
cmp [bytecode_buffer+bx], byte 7
je parse_inc
cmp [bytecode_buffer+bx], byte 8
je parse_dec
cmp [bytecode_buffer+bx], byte 9
je parse_cmp
cmp [bytecode_buffer+bx], byte 10
je parse_jye
cmp [bytecode_buffer+bx], byte 11
je parse_jne
cmp [bytecode_buffer+bx], byte 13
je parse_jge
cmp [bytecode_buffer+bx], byte 14
je parse_jle
; else
end:
inc word [bytecode_idx]
jmp parse


parse_jle:
cmp [jge_flag], byte 1
jne parse_jmp
jmp end

parse_jge:
cmp [jge_flag], byte 1
je parse_jmp
jmp end

parse_jne:
cmp [je_flag], byte 1
jne parse_jmp
jmp end

parse_jye:
cmp [je_flag], byte 1
je parse_jmp
jmp end

parse_cmp:
add bx, 3
mov ax, [bytecode_buffer+bx]

add bx, 2
mov cx, [bytecode_buffer+bx]

mov bx, cx
mov cx, [variables+bx]

cmp ax, cx
jg .greater
mov [jge_flag], byte 0
.next:
cmp ax, cx
je .equal
mov [je_flag], byte 0
jmp end
.greater:
mov [jge_flag], byte 1
jmp .next
.equal:
mov [je_flag], byte 1
jmp end

parse_dec:
add bx, 3
mov bx, [bytecode_buffer+bx]
dec word [variables+bx]
jmp end
parse_inc:
add bx, 3
mov bx, [bytecode_buffer+bx]
inc word [variables+bx]
jmp end

parse_jmp:
add bx, 3
mov ax, [bytecode_buffer+bx]

mov [bytecode_idx], ax

jmp parse

parse_mov:
add bx, 5
mov ax, [bytecode_buffer+bx] ; get second variable

sub bx, 2
mov cx, [bytecode_buffer+bx]

test cx, 0x8000
jnz .get_a_var
; a number
;cx is already a number
.next:
mov bx, ax ; move second var offset into bx

mov [variables+bx], cx
jmp end
.get_a_var: ;we must get CX and load it with the number from the variable

push ax
and cx, 0x7fff

mov bx, cx
mov cx, [variables+bx]
pop ax
jmp .next

parse_add:
add bx, 5
mov ax, [bytecode_buffer+bx]
sub bx, 2
mov cx, [bytecode_buffer+bx]

mov bx, ax
add [variables+bx], cx
jmp end

parse_sub:
add bx, 5
mov ax, [bytecode_buffer+bx]
sub bx, 2
mov cx, [bytecode_buffer+bx]

mov bx, ax
sub [variables+bx], cx
jmp end

parse_prt:
inc bx
mov ax, [bytecode_buffer+bx]
mov si, ax
cmp [es:si+1], byte '"'
jne .a_var
add si, 2
.print_loop:
mov al, [es:si]
cmp al, '"'
je .done
mov ah, 0eh
int 0x10
inc si
jmp .print_loop
.done:
mov ax, 0x0e0d
int 0x10
mov al, 0x0a
int 0x10
jmp end
.a_var:
add bx, 2
mov ax, [bytecode_buffer+bx]
mov bx, ax
mov ax, [variables+bx]
call os_int_to_string
mov di, ax
call printd
mov ax, 0x0e0d
int 0x10
mov al, 0x0a
int 0x10
jmp end

var_to_int:
;two variable chars in var_buffer
mov di, var_buffer
mov ax, 0 ;accumulator
mov bx, 0
cmp [di], byte 'a'
jl .two
mov al, [di]
sub al, 32
.two:
sub al, 'A'
mov cx, 26
mul cx

cmp [di+1], byte 'a'
jl .three
mov bl, [di+1]
sub bl, 32
.three:
sub bl, 'A'
movzx bx, bl
add ax, bx
ret

next_line:
    call prep_si
    .next_line_loop:
        cmp byte [es:si], 10
        je .done
        inc word [si_counter]
        inc si
        call check_si
        jmp .next_line_loop
    .done:
        inc si
        inc word [si_counter]
        call check_si
        jc .donedone
        cmp byte [es:si], 13
        jle .next_line_loop
        clc
        ret
        .donedone:
        stc
        ret

prep_si:
    xor si, si
    mov si, [si_counter]
    ret

printd:

    mov al, [di]
    mov ah, 0eh
    int 0x10
    inc di
    cmp [di], byte 0
    jne printd
    ret

get_cmd:
    call prep_si
    jc .done
    clc
    mov bx, 0
    .start:
    mov al, [es:si]
    cmp al, 32
    jle .done
    mov [cmd_buf+bx], al
    inc bx
    inc word [si_counter]
    inc si
    call check_si
    jc .done
    jmp .start
    .done:
        mov [cmd_buf+bx], byte 0
        inc word [si_counter]
        ret
check_si:
    mov si, [si_counter]
    cmp si, [end_of_file]
    jge .stc
    clc
    ret
.stc:
stc
ret

cmp_str:
mov di, cmd_buf
.start:
mov al, [bx]
cmp al, 0
je .test_done
cmp al, [di]
jne .different
inc bx
inc di
jmp .start
.test_done:
cmp [di], byte 0
jne .different
stc
ret
.different:
clc
ret



si_counter dw 0
end_of_file dw 0
line_counter db 0
cmd_buf2:
cmd_buf times 13 db 0
filename_buffer times 12 db 0 ; filename buffer
bytecode_idx dw 0
max_bytecode_idx dw 0
var_buffer dw 0
jge_flag db 0
je_flag db 0

variables times 26*26 dw 0


; Command strings
mov_str db 'mov', 0 ;move a value to a var ; DONE
add_str db 'add', 0 ;add a value to a var ; DONE
prt_str db 'prt', 0 ;print a var or a string ; DONE
sub_str db 'sub', 0 ;sub a value from a var ; DONE
clr_str db 'clr', 0 ;
jmp_str db 'jmp', 0 ;jump to a line ; DONE
inc_str db 'inc', 0 ;add 1 to a value DONE
dec_str db 'dec', 0 ;sub 1 from a value DONE
cmd_str db 'cmp', 0;compare a number and a var, OR var and a var DONE
jye_str db 'jye', 0 ;jump if equal DONE
jne_str db 'jne', 0 ;jump if not equal DONE
hlt_str db 'hlt', 0 ;stop program instantly 
del_str db 'del', 0 ;delays for numbers ticks
jgr_str db 'jgr', 0 ;jump if greater DONE
jls_str db 'jls', 0 ;jump if lesser DONE
rem_str db 'rem', 0 ;used to make comments, code is about 5 lines! (they are for identifying the command!!!)
bel_str db 'bel', 0 ;two params, first is frequency which is either var or num, then set num for the second param 
getky_str db 'getky', 0 ;two params, keycode, and if 0 is keycode then var to save the result keypress to
ask_str db 'ask', 0 ;takes in one param, and that is the string name. Either st1 or st2
cmpsr_str db 'cmpsr', 0 ;no params
%include "./extra/functions.asm"

disk_buffer equ 24576
bytecode_buffer:
dirlist:
delay:

