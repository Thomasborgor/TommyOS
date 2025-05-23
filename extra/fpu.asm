org 16384

section .data
float1  dd 3.14
float2  dd 2.86
result  dd 0.0

buffer  db 10 dup(0)     ; for storing digits ASCII

section .text
start:
    ; Initialize segment registers if needed
    ; Usually, CS=DS=ES=SS in bootloader
	fninit
    ; Load floats
    fld dword [float1]
    fld dword [float2]
    fadd st0, st1
    fstp dword [result]

    ; Convert float result to int (word)
    fld dword [result]
    fistp word [result]       ; pop after storing

    mov ax, [result]

    call PrintDecimalBIOS
	ret

; PrintDecimalBIOS: prints AX as decimal via BIOS INT 10h teletype
PrintDecimalBIOS:
    push ax
    push bx
    push cx
    push dx

    mov cx, 0           ; digit count

    cmp ax, 0
    jne .convert
    mov dl, '0'
    call PrintCharBIOS
    jmp .done

.convert:
    mov bx, 10

.nextdigit:
    xor dx, dx
    div bx              ; AX / 10, quotient in AX, remainder in DX
    push dx             ; remainder digit
    inc cx
    test ax, ax
    jnz .nextdigit

.printloop:
    pop dx
    add dl, '0'
    call PrintCharBIOS
    loop .printloop

.done:
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; PrintCharBIOS: prints char in DL using INT 10h
PrintCharBIOS:
    mov ah, 0x0E        ; teletype output function
    mov bh, 0           ; page number
    mov bl, 7           ; text attribute (grey)
    int 0x10
    ret
