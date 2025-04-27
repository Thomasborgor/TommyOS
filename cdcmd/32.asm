org 32768
mov ax, 0xb800
mov ds, ax
mov si, 0

mov dword [ds:si], 0x0f490f48
mov ax, 0x2000
mov ds, ax
ret