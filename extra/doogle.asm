mov cx, 0x2000
mov es, cx
mov ds, cx
push bx
mov [es:SecsPerTrack], ax
mov [es:Sides], bx
mov [es:bootdev], dl


mov di, test_txt
mov al, [ds:si]
mov [es:di], al

mov ax, 0x2000
mov ds, ax

mov cx, 0x3000
mov ax, test_txt
call os_create_file
retf

mov ax, 0x3000
mov ds, ax
xor si, si

mov al, [ds:si]
mov ah, 0eh
int 0x10

retf


%include "./extra/functions.asm"
disk_buffer equ 24576
test_txt db 'TEST.TXT', 0
test_txt2 db 'TEST2.TXT', 0

dirlist times 1024 dw 0
delay:
ret