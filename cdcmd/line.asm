[ORG 0x8000]  ; Origin at 0x8000
BITS 16       ; Real Mode (16-bit)

start:
    ; Set video mode to 320x200 (256 colors)
    mov ah, 0x00
    mov al, 0x13
    int 0x10

    ; Set up font printing
    mov word [posx], 100
    mov word [posy], 50
    mov si, font_A  ; Pointer to font bitmap
    call draw_char

    ; Wait for keypress before exiting
    mov ah, 0x00
    int 0x16

    ret

draw_char:
    push si
    mov cx, [posy]  ; CX = Start Y position
    mov dx, [posx]  ; DX = Start X position
    mov bp, 8       ; 8 rows (height)

row_loop:
    push cx         ; Save row (Y position)
    push dx         ; Save starting column (X position)
    mov al, [si]    ; Load font row (bit pattern)
    mov bl, 8       ; 8 columns (width)

col_loop:
    shr al, 1       ; Shift right, bit goes into CF
    jnc skip_pixel  ; If CF = 0, skip pixel plotting

    ; Draw pixel at (DX, CX)
    mov ah, 0x0C    ; BIOS: Put Pixel
    mov al, 0x0F    ; White color
    mov bh, 0x00    ; Video page 0
    int 0x10        ; Call BIOS

skip_pixel:
    inc dx          ; Move to next column (X)
    dec bl          ; Decrease column count
    jnz col_loop    ; Loop for 8 columns

    pop dx          ; Restore starting column (X)
    pop cx          ; Restore Y position
    inc cx          ; Move to next row (Y)
    inc si          ; Move to next font byte
    dec bp          ; Decrease row count
    jnz row_loop    ; Loop for 8 rows

    pop si
    ret

; 8x8 font for 'A' (bit pattern)
font_A:
    db 0x18  ; 00011000
    db 0x3C  ; 00111100
    db 0x66  ; 01100110
    db 0x66  ; 01100110
    db 0x7E  ; 01111110
    db 0x66  ; 01100110
    db 0x66  ; 01100110
    db 0x00  ; 00000000

posx dw 0
posy dw 0
