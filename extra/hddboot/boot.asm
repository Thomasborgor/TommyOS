[org 0x7c00]
; ==================================================================
; Adapted Bootloader for FAT16
; ==================================================================

    BITS 16

    jmp short bootloader_start  ; Jump past disk description section
    nop                         ; Pad out before disk description

; ------------------------------------------------------------------
; Disk description table, adapted for FAT16 on a hard disk
OEMLabel                db "mkfs.fat"
BytesPerSector          dw 512
SectorsPerCluster       db 4
ReservedForBoot         dw 4
NumberOfFats            db 2
RootDirEntries          dw 512
LogicalSectors          dw 20000
MediumByte              db 0xF8
SectorsPerFat           dw 20
SectorsPerTrack         dw 32
Sides                   dw 2
HiddenSectors           dd 0
LargeSectors            dd 0
DriveNo                 dw 128
Signature               db 0x29
VolumeID                dd 0x0741AC10
VolumeLabel             db "NO NAME   "
FileSystem              db "FAT16     "

bootloader_start:
xor ax, ax
mov ss, ax       ; Set stack segment to 0x0000
mov sp, 0x7C00   ; Set stack pointer to 0x7C00
mov ax, ds
mov es, ax
mov si, buffer

;HOW THE GEOMETRY WORKS: The max you can set CL to is 63, or sectors per track * sides-1, then after that you increment dh, reset cl to 1, and yeah you can access a LOT of sectors,
;now we calculate the root directory
;root directory: reserved sectors + (fats * sector per fat)
;root directory: 4 + (2 * 20)
;root directory: 44
;that means at sector 44 is the root directory
;to test that we just load 512 bytes and put a file in via mcopy and see it
mov ax, 0x0204  ;how disk operations work: ch and dh do nothing i think, and all you need to really set is cl, al, dl, and bx
mov ch, 0 
mov cl, 45
mov dx, 0x0080
mov bx, si ;what mikeos does (i trust them kind of)
int 13h
jc fail ;we have the 



look_in_root_dir:
mov si, buffer
add si, [buffer_offset]
mov di, kern_filename
mov cx, 11
repe cmpsb

je load_the_file
add word [buffer_offset], 21
cmp word [buffer_offset], 16384
jl look_in_root_dir
;if the buffer offset equals 16384, or 512 entries*32 bytes, then we have reached the max. no kernel.
jmp fail
load_the_file:

mov si, buffer
add si, [buffer_offset]
add si, 26 ;add 26 to get the low word of the cluster where the file data starts
mov al, [si]
mov [temp], al
push ax
sub al, 2 ;do the math to calculate real sector
mov dl, 4
mul dl
add al, 76

mov dl, 63
div dl
mov cl, ah ;set sector location to remainder
mov dh, al ;set head to amount of 63's.
mov dl, 0x80
mov ch, 0x0
mov ax, 0x0204 ;four sectors to read because of cluster stuff
push ax
mov ax, 0x2000
mov es, ax
pop ax
mov bx, 0
int 13h
pop ax
;pop ax
mov al, [temp]
mov bl, [temp] ;multiply by two
add al, bl ;fat table entry = starting_sector * 2
mov [fat_pointer], al
;but first we have to load in the FAT table (20 sectors at sector 4)
;we do this so that we can check and load each new cluster into memory and check the FAT tables.
mov ax, 0x0
mov es, ax
mov ax, 0x0214
mov cx, 0x0005 ;0 is 1 here
mov dx, 0x0080
mov bx, buffer
int 13h

jc fail



loop_load:

mov si, buffer

xor ah, ah

mov al, [fat_pointer] ;this code checks to see if we are at the end of the file.
add si, ax
mov al, [si]
mov [fat_pointer], al
;mov al, [si]
;mov ah, 0x0e
;int 0x10
;mov al, [si+1]
;int 0x10
;mov ah, 0x0
;int 16h
cmp word [si], 0xffff ;in=fat table in buffer, out=next cluster in ax ;we add two for some 
je end_of_file_reached

;not the end of file, so we load in the next cluster, then repeat again and again. Smooth sailing from here!
;load in next cluster with ax to es=0x2000 bx=kern_load_offset
;then we get ax again, multiply it by two, then repeat the loop.
;shouldn't be that hard right

;ax has cluster number from the fat table
mov al, [fat_pointer]
sub al, 2 ;do the math to calculate real sector
mov dl, 4
mul dl
add al, 76
mov [kern_sector], al

;use said real sector and convert it to something int 13h can understand
;how to get the int 13h paramerters from real sector [kern_sector]
;we divide it by 63, the remainder is in cl, and al is set to dh.
;easy peasy
mov al, [kern_sector]
mov dl, 63
div dl
mov cl, ah ;set sector location to remainder
mov dh, al ;set head to amount of 63's.
mov ch, 0
mov dl, 0x80
mov ax, 0x0201;four sectors to read because of cluster stuff
push ax
mov ax, 0x2000
mov es, ax
pop ax
mov bx, [kern_load_offset]

int 13h
jc fail
add word [kern_load_offset], 0x200

mov ax, 0x0
mov es, ax

mov al, [fat_pointer]
mov bl, al
add al, bl
mov [fat_pointer], al

jmp loop_load


end_of_file_reached:

jmp 0x2000:0x0000


fail:
mov ah, 0x0e
int 0x10
mov al, cl
int 0x10
mov al, ch
int 0x10
mov al, dh
int 0x10
jmp $

l2hts:
	


kern_filename db 'KERNEL  BIN', 0
buffer_offset dw 0
kern_sector db 0
fat_pointer db 0
fat_sector db 0
temp db 0
kern_load_offset dw 0x2200
times 510-($-$$) db 0               ; Pad remainder of boot sector
dw 0xAA55                            ; Boot signature

buffer: