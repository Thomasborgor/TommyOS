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
    push cx         ; Save Y position
    push dx         ; Save X position
    mov al, [si]    ; Load font row (bit pattern)
    mov bx, 0       ; Reset column counter

col_loop:
    xor bh, bh
    mov bl, [mask_values+bx]  ; Load bitmask for this column
    test al, bl               ; Check if the corresponding bit is 1
    jz skip_pixel             ; If bit is 0, skip pixel plotting

    ; Draw pixel at (DX, CX)
    mov ah, 0x0C    ; BIOS: Put Pixel
    mov al, 0x0F    ; White color
    mov bh, 0x00    ; Video page 0
    int 0x10        ; Call BIOS

skip_pixel:
    inc dx          ; Move to next column (X)
    inc bx          ; Move to next bit position
    cmp bx, 8       ; If all 8 columns are drawn
    jl col_loop     ; Keep looping

    pop dx          ; Restore X position
    pop cx          ; Restore Y position
    inc cx          ; Move down to next row (Y)
    inc si          ; Move to next font byte (next row)
    dec bp          ; Decrease row count
    jnz row_loop    ; Loop for 8 rows

    pop si
    ret

; 8-bit masks for testing each bit
mask_values:
    db 0x80, 0x40, 0x20, 0x10, 0x08, 0x04, 0x02, 0x01

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
