org 0x8000
mov ax, 50 ;x1
mov bx, 50 ;y1
mov cx, 100 ;x2
mov dx, 150 ;y2

line_algorithm:
	pusha
	sub cx, ax
	mov [dx_val], cx
	sub dx, bx
	mov [dy_val], dx
	popa
	
	
	
	
	
	
	
	
	
	
	
	
	
	
dx_val dw 0
dy_val dw 0 
sx_val dw 0
sy_val dw 0 
er_val dw 0 
