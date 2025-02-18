[bits 16]
org 32768          ; 
mov ah, 0x01       ; Function to change cursor shape
mov CX, 2607h
int 0x10  

start:
	;thank you to @ahmedkhamis9488 on youtube for this code that finally worked
	mov ah, 0x02
	mov bh, 0x0
	mov dx, 0
	int 0x10
    MOV AH,09    ;DISPLAY OPTION
    MOV BH,00    ;PAGE 0
    MOV AL,20H   ; ASCII FOR SPACE
    MOV CX, 800h   ;REPEAT IT 800H
    ;MOV BL,2FH    ; COLOR
    INT 10H
	mov bh, 0x0
	mov ah, 0x02
	mov dx, 0x184f
	int 0x10
	
	add bh, 0x11
	call delay
	mov ah, 1
	int 0x16
	jz start
	cmp al, 'c'
	jne start
	
	mov ah, 5
	mov al, 1
	int 0x10
	mov ah, 2 
	mov bh, 1
	mov dx, 0
	int 0x10
	
	
	
	
	
	
	
reset:
	mov bh, 0x10
	jmp start
	
go_away:
	ret

delay:
    ; Input: BX = number of ticks to wait (1 tick ˜ 55ms)
	mov bx, 10
    mov ah, 00h        ; Function 00h: Get current clock count
    int 1Ah            ; Call BIOS to get tick count
    add bx, dx         ; Calculate target tick count (DX = current count)
wait_loop:
    mov ah, 00h        ; Function 00h: Get current clock count
    int 1Ah            ; Call BIOS to get tick count
    cmp dx, bx         ; Compare current tick count with target
    jb wait_loop       ; If current tick count is less than target, wait
    ret                ; Return after the delay
	
print:
	lodsb
	cmp al, 0
	je done_print
	mov ah, 0eh
	int 0x10
	jmp print
done_print:
	ret


msg1 db 'Screensaver setup', 0

msg2 db 'Type of change (1=full, 2=vertical, 3=horizontal, 4=diagonal):', 0
msg3 db "Time until stop (__ o'clock):", 0
msg4 db 'Delay between change:', 0