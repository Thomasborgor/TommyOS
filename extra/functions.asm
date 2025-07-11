; ==================================================================
; MikeOS -- The Mike Operating System kernel
; Copyright (C) 2006 - 2014 MikeOS Developers -- see doc/LICENSE.TXT
;
; FAT12 FLOPPY DISK ROUTINES
; ==================================================================

; ------------------------------------------------------------------
; os_get_file_list -- Generate comma-separated string of files on floppy
; IN/OUT: AX = location to store zero-terminated filename string

os_get_file_list:
	pusha
	mov word [dirlist], 0
	mov word [.file_list_tmp], ax

	mov eax, 0			; Needed for some older BIOSes

	call disk_reset_floppy		; Just in case disk was changed

	mov ax, 19			; Root dir starts at logical sector 19
	call disk_convert_l2hts

	mov si, disk_buffer		; ES:BX should point to our buffer
	mov bx, si

	mov ah, 2			; Params for int 13h: read floppy sectors
	mov al, 14			; And read 14 of them

	pusha				; Prepare to enter loop


.read_root_dir:
	popa
	pusha

	stc
	mov dl, [bootdev]
	int 13h				; Read sectors
	jc donedid
	call disk_reset_floppy		; Check we've read them OK
	jnc .show_dir_init		; No errors, continue

	call disk_reset_floppy		; Error = reset controller and try again
	jnc .read_root_dir
	jmp .done			; Double error, exit 'dir' routine

.show_dir_init:
	popa

	mov ax, 0
	mov si, disk_buffer		; Data reader from start of filenames
	
	cmp byte [si+11], 08h
	je .do_the_volume_label

	mov word di, [.file_list_tmp]	; Name destination buffer

.start_entry:
	mov al, [si+11]			; File attributes for entry
	cmp al, 0Fh			; Windows marker, skip it
	je .skip

	test al, 18h			; Is this a directory entry or volume label?
	jnz .skip		; Yes, ignore it

	mov al, [si]
	cmp al, 229			; If we read 229 = deleted filename
	je .skip

	cmp al, 0			; 1st byte = entry never used
	je .done


	mov cx, 1			; Set char counter
	mov dx, si			; Beginning of possible entry

.testdirentry:
	inc si
	mov al, [si]			; Test for most unusable characters
	cmp al, ' '			; Windows sometimes puts 0 (UTF-8) or 0FFh
	jl .nxtdirentry
	cmp al, '~'
	ja .nxtdirentry

	inc cx
	cmp cx, 11			; Done 11 char filename?
	je .gotfilename
	jmp .testdirentry


.gotfilename:				; Got a filename that passes testing
	mov si, dx			; DX = where getting string

	mov cx, 0
.loopy:
	mov byte al, [si]
	cmp al, ' '
	je .ignore_space
	mov byte [di], al
	inc si
	inc di
	inc cx
	cmp cx, 8
	je .add_dot
	cmp cx, 11
	je .done_copy
	jmp .loopy

.ignore_space:
	inc si
	inc cx
	cmp cx, 8
	je .add_dot
	jmp .loopy

.add_dot:
	mov byte [di], '.'
	inc di
	jmp .loopy

.done_copy:
	mov byte [di], ','		; Use comma to separate filenames
	inc di

.nxtdirentry:
	mov si, dx			; Start of entry, pretend to skip to next

.skip:
	add si, 32			; Shift to next 32 bytes (next filename)
	jmp .start_entry

.do_the_volume_label:
	mov cx, 11
	mov di, .volumenamebuffer
	.loppy:
		lodsb
		stosb
		loop .loppy
	mov word di, [.file_list_tmp]
	mov byte [di], ','
	add si, 21
	jmp .start_entry
	

.done:
	dec di
	mov byte [di], 0		; Zero-terminate string (gets rid of final comma)

	popa
	ret


	.file_list_tmp		dw 0
.volumenamebuffer times 12 db 0
donedid:
	popa
	popa
	stc
	ret

; ------------------------------------------------------------------
; os_load_file -- Load file into RAM
; IN: AX = location of filename, CX = location in RAM to load file
; OUT: BX = file size (in bytes), carry set if file not found
os_load_file:
	push es
	call os_string_uppercase
	call int_filename_convert
	push ax

	mov al, [bootdev]
	mov [bootd], al
	pop ax

	mov [.filename_loc], ax
	mov [.load_position], cx

	mov eax, 0
	call disk_reset_floppy
	jnc .floppy_ok

	mov ax, .err_msg_floppy_reset
	jmp os_fatal_error

.floppy_ok:
	mov ax, 19
	call disk_convert_l2hts

	mov si, disk_buffer
	mov bx, si

	mov ah, 2
	mov al, 14

.pusha_root:
	pusha

.read_root_dir:
	stc
	mov dl, [bootdev]
	int 13h
	jnc .search_root_dir

	call disk_reset_floppy
	jnc .read_root_dir

	popa
	jmp .root_problem

.search_root_dir:
	popa

	mov cx, 224
	mov bx, -32

.next_root_entry:
	add bx, 32
	mov di, disk_buffer
	add di, bx

	mov al, [di]
	cmp al, 0
	je .root_problem

	cmp al, 229
	je .next_root_entry

	mov al, [di+11]
	cmp al, 0Fh
	je .next_root_entry

	test al, 18h
	jnz .next_root_entry

	mov byte [di+11], 0
	mov ax, di
	call os_string_uppercase

	mov si, [.filename_loc]
	call os_string_compare
	jc .found_file_to_load

	loop .next_root_entry

.root_problem:
	mov bx, 0
	stc
	pop es
	ret

.found_file_to_load:
	mov eax, [di+28]
	mov [.file_size], eax
	cmp eax, 0
	je .end

	mov ax, [di+26]
	mov [.cluster], ax

	mov ax, 1
	call disk_convert_l2hts

	mov di, disk_buffer
	mov bx, di

	mov ah, 2
	mov al, 9

.pusha_fat:
	pusha

.read_fat:
	stc
	mov dl, [bootdev]
	int 13h
	jnc .read_fat_ok

	call disk_reset_floppy
	jnc .read_fat

	popa
	jmp .root_problem

.read_fat_ok:
	popa

.load_file_sector:
	mov ax, [.cluster]
	add ax, 31
	call disk_convert_l2hts

	mov bx, [.load_position]
	mov es, bx
	mov bx, 0

	mov ah, 02
	mov al, 01

	stc
	mov dl, [bootdev]
	int 13h
	jnc .calculate_next_cluster

	call disk_reset_floppy
	jnc .load_file_sector

	mov ax, .err_msg_floppy_reset
	jmp os_fatal_error

.calculate_next_cluster:
	mov ax, [.cluster]
	mov bx, 3
	mul bx
	mov bx, 2
	div bx
	mov si, disk_buffer
	add si, ax
	mov ax, word [ds:si]

	or dx, dx
	jz .even
.odd:
	shr ax, 4
	jmp .calculate_cluster_cont
.even:
	and ax, 0FFFh

.calculate_cluster_cont:
	mov [.cluster], ax
	cmp ax, 0FF8h
	jae .end

	add word [.load_position], 0x20  ; Move to next 512 bytes in memory
	jmp .load_file_sector

.end:
	mov eax, [.file_size]
	mov bx, ax         ; Return low 16 bits in BX (as that's all the caller sees)
	clc
	pop es
	ret


.cluster        dw 0
.filename_loc   dw 0
.load_position  dw 0
.file_size      dd 0

.string_buff    times 12 db 0
.err_msg_floppy_reset db 'os_load_file: Floppy failed to reset', 0
bootd           db 0


; ------------------------------------------------------------------
; os_load_file -- Load file into RAM
; IN: AX = location of filename, CX = location in RAM to load file
; OUT: BX = file size (in bytes), carry set if file not found

os_load_file_in_segment:
	call os_string_uppercase
	call int_filename_convert
	push ax
	mov al, [bootdev]
	mov [bootd], al
	pop ax

	mov [.filename_loc], ax		; Store filename location
	mov [.load_position], cx	; And where to load the file!

	mov eax, 0			; Needed for some older BIOSes

	call disk_reset_floppy		; In case floppy has been changed
	jnc .floppy_ok			; Did the floppy reset OK?

	mov ax, .err_msg_floppy_reset	; If not, bail out
	jmp os_fatal_error


.floppy_ok:				; Ready to read first block of data
	mov ax, 19			; Root dir starts at logical sector 19
	call disk_convert_l2hts

	mov si, disk_buffer		; ES:BX should point to our buffer
	mov bx, si

	mov ah, 2			; Params for int 13h: read floppy sectors
	mov al, 14			; 14 root directory sectors

	pusha				; Prepare to enter loop


.read_root_dir:
	popa
	pusha

	stc				; A few BIOSes clear, but don't set properly
	mov dl, [bootdev]
	int 13h				; Read sectors
	jnc .search_root_dir		; No errors = continue

	call disk_reset_floppy		; Problem = reset controller and try again
	jnc .read_root_dir

	popa
	jmp .root_problem		; Double error = exit

.search_root_dir:
	popa

	mov cx, word 224		; Search all entries in root dir
	mov bx, -32			; Begin searching at offset 0 in root dir

.next_root_entry:
	add bx, 32			; Bump searched entries by 1 (offset + 32 bytes)
	mov di, disk_buffer		; Point root dir at next entry
	add di, bx

	mov al, [di]			; First character of name

	cmp al, 0			; Last file name already checked?
	je .root_problem

	cmp al, 229			; Was this file deleted?
	je .next_root_entry		; If yes, skip it

	mov al, [di+11]			; Get the attribute byte

	cmp al, 0Fh			; Is this a special Windows entry?
	je .next_root_entry

	test al, 18h			; Is this a directory entry or volume label?
	jnz .next_root_entry

	mov byte [di+11], 0		; Add a terminator to directory name entry

	mov ax, di			; Convert root buffer name to upper case
	call os_string_uppercase

	mov si, [.filename_loc]		; DS:SI = location of filename to load

	call os_string_compare		; Current entry same as requested?
	jc .found_file_to_load

	loop .next_root_entry

.root_problem:
	mov bx, 0			; If file not found or major disk error,
	stc				; return with size = 0 and carry set
	ret


.found_file_to_load:			; Now fetch cluster and load FAT into RAM
	mov ax, [di+28]			; Store file size to return to calling routine
	mov word [.file_size], ax

	cmp ax, 0			; If the file size is zero, don't bother trying
	je .end				; to read more clusters

	mov ax, [di+26]			; Now fetch cluster and load FAT into RAM
	mov word [.cluster], ax

	mov ax, 1			; Sector 1 = first sector of first FAT
	call disk_convert_l2hts

	mov di, disk_buffer		; ES:BX points to our buffer
	mov bx, di

	mov ah, 2			; int 13h params: read sectors
	mov al, 9			; And read 9 of them

	pusha

.read_fat:
	popa				; In case registers altered by int 13h
	pusha

	stc
	mov dl, [bootdev]
	int 13h
	jnc .read_fat_ok

	call disk_reset_floppy
	jnc .read_fat

	popa
	jmp .root_problem


.read_fat_ok:
	popa


.load_file_sector:
	mov ax, word [.cluster]		; Convert sector to logical
	add ax, 31

	call disk_convert_l2hts		; Make appropriate params for int 13h

	mov bx, [.load_position]


	mov ah, 02			; AH = read sectors, AL = just read 1
	mov al, 01

	stc
	mov dl, [bootdev]
	int 13h
	jnc .calculate_next_cluster	; If there's no error...

	call disk_reset_floppy		; Otherwise, reset floppy and retry
	jnc .load_file_sector

	mov ax, .err_msg_floppy_reset	; Reset failed, bail out
	jmp os_fatal_error


.calculate_next_cluster:
	mov ax, [.cluster]
	mov bx, 3
	mul bx
	mov bx, 2
	div bx				; DX = [CLUSTER] mod 2
	mov si, disk_buffer		; AX = word in FAT for the 12 bits
	add si, ax
	mov ax, word [ds:si]

	or dx, dx			; If DX = 0 [CLUSTER] = even, if DX = 1 then odd

	jz .even			; If [CLUSTER] = even, drop last 4 bits of word
					; with next cluster; if odd, drop first 4 bits

.odd:
	shr ax, 4			; Shift out first 4 bits (belong to another entry)
	jmp .calculate_cluster_cont	; Onto next sector!

.even:
	and ax, 0FFFh			; Mask out top (last) 4 bits

.calculate_cluster_cont:
	mov word [.cluster], ax		; Store cluster

	cmp ax, 0FF8h
	jae .end

	add word [.load_position], 512
	jmp .load_file_sector		; Onto next sector!


.end:
	mov bx, [.file_size]		; Get file size to pass back in BX
	clc				; Carry clear = good load
	ret


	
	.cluster	dw 0 		; Cluster of the file we want to load
	.pointer	dw 0 		; Pointer into disk_buffer, for loading 'file2load'

	.filename_loc	dw 0		; Temporary store of filename location
	.load_position	dw 0		; Where we'll load the file
	.file_size	dw 0		; Size of the file

	.string_buff	times 12 db 0	; For size (integer) printing
	

	.err_msg_floppy_reset	db 'os_load_file: Floppy failed to reset', 0

; --------------------------------------------------------------------------
; os_write_file -- Save (max 64K) file to disk
; IN: AX = filename, BX = data location, CX = bytes to write
; OUT: Carry clear if OK, set if failure

os_write_file:
	pusha

	mov si, ax
	call os_string_length
	cmp ax, 0
	je near .failure
	mov ax, si

	call os_string_uppercase
	call int_filename_convert	; Make filename FAT12-style
	jc near .failure

	mov word [.filesize], cx
	mov word [.location], bx
	mov word [.filename], ax

	call os_file_exists		; Don't overwrite a file if it exists!
	jnc near .failure


	; First, zero out the .free_clusters list from any previous execution
	pusha

	mov di, .free_clusters
	mov cx, 128
.clean_free_loop:
	mov word [di], 0
	inc di
	inc di
	loop .clean_free_loop

	popa


	; Next, we need to calculate now many 512 byte clusters are required

	mov ax, cx
	mov dx, 0
	mov bx, 512			; Divide file size by 512 to get clusters needed
	div bx
	cmp dx, 0
	jg .add_a_bit			; If there's a remainder, we need another cluster
	jmp .carry_on

.add_a_bit:
	add ax, 1
.carry_on:

	mov word [.clusters_needed], ax

	mov word ax, [.filename]	; Get filename back

	call os_create_file		; Create empty root dir entry for this file
	jc near .failure		; If we can't write to the media, jump out

	mov word bx, [.filesize]
	cmp bx, 0
	je near .finished

	call disk_read_fat		; Get FAT copy into RAM
	mov si, disk_buffer + 3		; And point SI at it (skipping first two clusters)

	mov bx, 2			; Current cluster counter
	mov word cx, [.clusters_needed]
	mov dx, 0			; Offset in .free_clusters list

.find_free_cluster:
	lodsw				; Get a word
	and ax, 0FFFh			; Mask out for even
	jz .found_free_even		; Free entry?

.more_odd:
	inc bx				; If not, bump our counter
	dec si				; 'lodsw' moved on two chars; we only want to move on one

	lodsw				; Get word
	shr ax, 4			; Shift for odd
	or ax, ax			; Free entry?
	jz .found_free_odd

.more_even:
	inc bx				; If not, keep going
	jmp .find_free_cluster


.found_free_even:
	push si
	mov si, .free_clusters		; Store cluster
	add si, dx
	mov word [si], bx
	pop si

	dec cx				; Got all the clusters we need?
	cmp cx, 0
	je .finished_list

	inc dx				; Next word in our list
	inc dx
	jmp .more_odd

.found_free_odd:
	push si
	mov si, .free_clusters		; Store cluster
	add si, dx
	mov word [si], bx
	pop si

	dec cx
	cmp cx, 0
	je .finished_list

	inc dx				; Next word in our list
	inc dx
	jmp .more_even



.finished_list:

	; Now the .free_clusters table contains a series of numbers (words)
	; that correspond to free clusters on the disk; the next job is to
	; create a cluster chain in the FAT for our file

	mov cx, 0			; .free_clusters offset counter
	mov word [.count], 1		; General cluster counter

.chain_loop:
	mov word ax, [.count]		; Is this the last cluster?
	cmp word ax, [.clusters_needed]
	je .last_cluster

	mov di, .free_clusters

	add di, cx
	mov word bx, [di]		; Get cluster

	mov ax, bx			; Find out if it's an odd or even cluster
	mov dx, 0
	mov bx, 3
	mul bx
	mov bx, 2
	div bx				; DX = [.cluster] mod 2
	mov si, disk_buffer
	add si, ax			; AX = word in FAT for the 12 bit entry
	mov ax, word [ds:si]

	or dx, dx			; If DX = 0, [.cluster] = even; if DX = 1 then odd
	jz .even

.odd:
	and ax, 000Fh			; Zero out bits we want to use
	mov di, .free_clusters
	add di, cx			; Get offset in .free_clusters
	mov word bx, [di+2]		; Get number of NEXT cluster
	shl bx, 4			; And convert it into right format for FAT
	add ax, bx

	mov word [ds:si], ax		; Store cluster data back in FAT copy in RAM

	inc word [.count]
	inc cx				; Move on a word in .free_clusters
	inc cx

	jmp .chain_loop

.even:
	and ax, 0F000h			; Zero out bits we want to use
	mov di, .free_clusters
	add di, cx			; Get offset in .free_clusters
	mov word bx, [di+2]		; Get number of NEXT free cluster

	add ax, bx

	mov word [ds:si], ax		; Store cluster data back in FAT copy in RAM

	inc word [.count]
	inc cx				; Move on a word in .free_clusters
	inc cx

	jmp .chain_loop



.last_cluster:
	mov di, .free_clusters
	add di, cx
	mov word bx, [di]		; Get cluster

	mov ax, bx

	mov dx, 0
	mov bx, 3
	mul bx
	mov bx, 2
	div bx				; DX = [.cluster] mod 2
	mov si, disk_buffer
	add si, ax			; AX = word in FAT for the 12 bit entry
	mov ax, word [ds:si]

	or dx, dx			; If DX = 0, [.cluster] = even; if DX = 1 then odd
	jz .even_last

.odd_last:
	and ax, 000Fh			; Set relevant parts to FF8h (last cluster in file)
	add ax, 0FF80h
	jmp .finito

.even_last:
	and ax, 0F000h			; Same as above, but for an even cluster
	add ax, 0FF8h


.finito:
	mov word [ds:si], ax

	call disk_write_fat		; Save our FAT back to disk


	; Now it's time to save the sectors to disk!

	mov cx, 0

.save_loop:
	mov di, .free_clusters
	add di, cx
	mov word ax, [di]

	cmp ax, 0
	je near .write_root_entry

	pusha

	add ax, 31

	call disk_convert_l2hts

	mov word bx, [.location]

	mov ah, 3
	mov al, 1
	mov dl, [bootdev]
	stc
	int 13h

	popa

	add word [.location], 512
	inc cx
	inc cx
	jmp .save_loop


.write_root_entry:

	; Now it's time to head back to the root directory, find our
	; entry and update it with the cluster in use and file size

	call disk_read_root_dir

	mov word ax, [.filename]
	call disk_get_root_entry

	mov word ax, [.free_clusters]	; Get first free cluster

	mov word [di+26], ax		; Save cluster location into root dir entry

	mov word cx, [.filesize]
	mov word [di+28], cx

	mov byte [di+30], 0		; File size
	mov byte [di+31], 0

	call disk_write_root_dir

.finished:
	popa
	clc
	ret

.failure:
	popa
	stc				; Couldn't write!
	ret


	.filesize	dw 0
	.cluster	dw 0
	.count		dw 0
	.location	dw 0

	.clusters_needed	dw 0

	.filename	dw 0

	.free_clusters	times 128 dw 0


; --------------------------------------------------------------------------
; os_file_exists -- Check for presence of file on the floppy
; IN: AX = filename location; OUT: carry clear if found, set if not

os_file_exists:
	call os_string_uppercase
	call int_filename_convert	; Make FAT12-style filename

	push ax
	call os_string_length
	cmp ax, 13
	jge .failure
	cmp ax, 0
	je .failure
	pop ax

	push ax
	call disk_read_root_dir

	pop ax				; Restore filename

	mov di, disk_buffer

	call disk_get_root_entry	; Set or clear carry flag
	
	ret

.failure:
	pop ax
	stc
	ret


; --------------------------------------------------------------------------
; os_create_file -- Creates a new 0-byte file on the floppy disk
; IN: AX = location of filename; OUT: Nothing

os_create_file:

	clc

	call os_string_uppercase
	call int_filename_convert	; Make FAT12-style filename
	pusha

	push ax				; Save filename for now

	call os_file_exists		; Does the file already exist?
	jnc .exists_error

	;call disk_read_root_dir
	; Root dir already read into disk_buffer by os_file_exists

	mov di, disk_buffer		; So point DI at it!


	mov cx, 224			; Cycle through root dir entries

.next_entry:
	
	mov byte al, [di]
	cmp al, 0			; Is this a free entry?
	je .found_free_entry
	cmp al, 0E5h			; Is this a free entry?
	je .found_free_entry
	add di, 32			; If not, go onto next entry
	loop .next_entry

.exists_error:				; We also get here if above loop finds nothing
	pop ax				; Get filename back

	popa
	stc				; Set carry for failure
	ret


.found_free_entry:
	pop si				; Get filename back
	mov cx, 11
	rep movsb			; And copy it into RAM copy of root dir (in DI)
	sub di, 11			; Back to start of root dir entry, for clarity


	mov byte [di+11], 0		; Attributes
	mov byte [di+12], 0		; Reserved
	mov byte [di+13], 0		; Reserved
	mov byte [di+14], 000h		; Creation time
	mov byte [di+15], 000h		; Creation time
	mov byte [di+16], 0		; Creation date
	mov byte [di+17], 0		; Creation date
	mov byte [di+18], 0		; Last access date
	mov byte [di+19], 0		; Last access date
	mov byte [di+20], 0		; Ignore in FAT12
	mov byte [di+21], 0		; Ignore in FAT12
	mov byte [di+22], 000h		; Last write time
	mov byte [di+23], 000h		; Last write time
	mov byte [di+24], 0		; Last write date
	mov byte [di+25], 0		; Last write date
	mov byte [di+26], 0		; First logical cluster
	mov byte [di+27], 0		; First logical cluster
	mov byte [di+28], 0		; File size
	mov byte [di+29], 0		; File size
	mov byte [di+30], 0		; File size
	mov byte [di+31], 0		; File size

	call disk_write_root_dir
	popa
	clc				; Clear carry for success
	ret

.failure:
	popa
	stc
	ret


	
custom_create_file:
call os_string_uppercase
call os_int_to_string
mov word [filename_buf], ax

mov ax, 19
call convert_to_13h
mov ax, 0x020d
mov bx, disk_buffer
int 0x13


mov si, disk_buffer
xor dx, dx
mov cx, 224
get_open_entry_loop:
cmp byte [si], 0
je found_entry
cmp byte [si], 0e5h
je found_entry
add si, 32
add dx, 32
loop get_open_entry_loop
jmp errored

found_entry:
mov di, disk_buffer
add di, dx
mov ax, [filename_buf]
call os_string_uppercase
call int_filename_convert
mov si, ax

mov cx, 11
store_filename:
push cx
lodsb
stosb
pop cx
loop store_filename

mov ax, 19
call convert_to_13h
mov ax, 0x030d
mov bx, disk_buffer
int 13h
jc errored

ret

errored:
	mov ax, 0x0e01
	int 0x10
	jmp $

convert_to_13h:
push bx
	push ax

	mov bx, ax			; Save logical sector

	mov dx, 0			; First the sector
	div word [SecsPerTrack]		; Sectors per track
	add dl, 01h			; Physical sectors start at 1
	mov cl, dl			; Sectors belong in CL for int 13h
	mov ax, bx

	mov dx, 0			; Now calculate the head
	div word [SecsPerTrack]		; Sectors per track
	mov dx, 0
	div word [Sides]		; Floppy sides
	mov dh, dl			; Head/side
	mov ch, al			; Track
	
	pop ax
	pop bx

; ******************************************************************
	mov dl, [bootdev]		; Set correct device
; ******************************************************************
ret


filename_buf dw 0
	
; --------------------------------------------------------------------------
; os_remove_file -- Deletes the specified file from the filesystem
; IN: AX = location of filename to remove

os_remove_file:
	pusha
	call os_string_uppercase
	call int_filename_convert	; Make filename FAT12-style
	push ax				; Save filename

	clc

	call disk_read_root_dir		; Get root dir into disk_buffer

	mov di, disk_buffer		; Point DI to root dir

	pop ax				; Get chosen filename back

	call disk_get_root_entry	; Entry will be returned in DI
	jc .failure			; If entry can't be found


	mov ax, word [es:di+26]		; Get first cluster number from the dir entry
	mov word [.cluster], ax		; And save it

	mov byte [di], 0E5h		; Mark directory entry (first byte of filename) as empty

	inc di

	mov cx, 0			; Set rest of data in root dir entry to zeros
.clean_loop:
	mov byte [di], 0
	inc di
	inc cx
	cmp cx, 31			; 32-byte entries, minus E5h byte we marked before
	jl .clean_loop

	call disk_write_root_dir	; Save back the root directory from RAM


	call disk_read_fat		; Now FAT is in disk_buffer
	mov di, disk_buffer		; And DI points to it


.more_clusters:
	mov word ax, [.cluster]		; Get cluster contents

	cmp ax, 0			; If it's zero, this was an empty file
	je .nothing_to_do

	mov bx, 3			; Determine if cluster is odd or even number
	mul bx
	mov bx, 2
	div bx				; DX = [first_cluster] mod 2
	mov si, disk_buffer		; AX = word in FAT for the 12 bits
	add si, ax
	mov ax, word [ds:si]

	or dx, dx			; If DX = 0 [.cluster] = even, if DX = 1 then odd

	jz .even			; If [.cluster] = even, drop last 4 bits of word
					; with next cluster; if odd, drop first 4 bits
.odd:
	push ax
	and ax, 000Fh			; Set cluster data to zero in FAT in RAM
	mov word [ds:si], ax
	pop ax

	shr ax, 4			; Shift out first 4 bits (they belong to another entry)
	jmp .calculate_cluster_cont	; Onto next sector!

.even:
	push ax
	and ax, 0F000h			; Set cluster data to zero in FAT in RAM
	mov word [ds:si], ax
	pop ax

	and ax, 0FFFh			; Mask out top (last) 4 bits (they belong to another entry)

.calculate_cluster_cont:
	mov word [.cluster], ax		; Store cluster

	cmp ax, 0FF8h			; Final cluster marker?
	jae .end

	jmp .more_clusters		; If not, grab more

.end:
	call disk_write_fat
	jc .failure

.nothing_to_do:
	popa
	clc
	ret

.failure:
	popa
	stc
	ret


	.cluster dw 0


; --------------------------------------------------------------------------
; os_rename_file -- Change the name of a file on the disk
; IN: AX = filename to change, BX = new filename (zero-terminated strings)
; OUT: carry set on error

os_rename_file:
	push bx
	push ax

	clc

	call disk_read_root_dir		; Get root dir into disk_buffer

	mov di, disk_buffer		; Point DI to root dir

	pop ax				; Get chosen filename back

	call os_string_uppercase
	call int_filename_convert

	call disk_get_root_entry	; Entry will be returned in DI
	jc .fail_read			; Quit out if file not found

	pop bx				; Get new filename string (originally passed in BX)

	mov ax, bx

	call os_string_uppercase
	call int_filename_convert

	mov si, ax

	mov cx, 11			; Copy new filename string into root dir entry in disk_buffer
	rep movsb

	call disk_write_root_dir	; Save root dir to disk
	jc .fail_write

	clc
	ret

.fail_read:
	pop ax
	stc
	ret

.fail_write:
	stc
	ret


; --------------------------------------------------------------------------
; os_get_file_size -- Get file size information for specified file
; IN: AX = filename; OUT: BX = file size in bytes (up to 64K)
; or carry set if file not found

os_get_file_size:
	pusha

	call os_string_uppercase
	call int_filename_convert

	clc

	push ax

	call disk_read_root_dir
	jc .failure

	pop ax

	mov di, disk_buffer

	call disk_get_root_entry
	jc .failure

	mov word bx, [di+28]

	mov word [.tmp], bx

	popa

	mov word bx, [.tmp]

	ret

.failure:
	popa
	stc
	ret


	.tmp	dw 0


; ==================================================================
; INTERNAL OS ROUTINES -- Not accessible to user programs

; ------------------------------------------------------------------
; int_filename_convert -- Change 'TEST.BIN' into 'TEST    BIN' as per FAT12
; IN: AX = filename string
; OUT: AX = location of converted string (carry set if invalid)

int_filename_convert:
	pusha

	mov si, ax

	call os_string_length
	cmp ax, 14			; Filename too long?
	jg .failure			; Fail if so

	cmp ax, 0
	je .failure			; Similarly, fail if zero-char string

	mov dx, ax			; Store string length for now

	mov di, .dest_string

	mov cx, 0
.copy_loop:
	lodsb
	cmp al, '.'
	je .extension_found
	stosb
	inc cx
	cmp cx, dx
	jg .failure			; No extension found = wrong
	jmp .copy_loop

.extension_found:
	cmp cx, 0
	je .failure			; Fail if extension dot is first char

	cmp cx, 8
	je .do_extension		; Skip spaces if first bit is 8 chars

	; Now it's time to pad out the rest of the first part of the filename
	; with spaces, if necessary

.add_spaces:
	mov byte [di], ' '
	inc di
	inc cx
	cmp cx, 8
	jl .add_spaces

	; Finally, copy over the extension
.do_extension:
	lodsb				; 3 characters
	cmp al, 0
	je .failure
	stosb
	lodsb
	cmp al, 0
	je .failure
	stosb
	lodsb
	cmp al, 0
	je .failure
	stosb

	mov byte [di], 0		; Zero-terminate filename

	popa
	mov ax, .dest_string
	clc				; Clear carry for success
	ret


.failure:
	popa
	stc				; Set carry for failure
	ret


	.dest_string	times 13 db 0


; --------------------------------------------------------------------------
; disk_get_root_entry -- Search RAM copy of root dir for file entry
; IN: AX = filename; OUT: DI = location in disk_buffer of root dir entry,
; or carry set if file not found

disk_get_root_entry:
	pusha

	mov word [.filename], ax

	mov cx, 224			; Search all (224) entries
	mov ax, 0			; Searching at offset 0 ;skip first file
	
.to_next_root_entry:
	xchg cx, dx			; We use CX in the inner loop...

	mov word si, [.filename]	; Start searching for filename
	mov cx, 11
	rep cmpsb
	je .found_file			; Pointer DI will be at offset 11, if file found

	add ax, 32			; Bump searched entries by 1 (32 bytes/entry)

	mov di, disk_buffer		; Point to next root dir entry
	add di, ax

	xchg dx, cx			; Get the original CX back
	loop .to_next_root_entry

	popa

	stc				; Set carry if entry not found
	ret


.found_file:
	sub di, 11			; Move back to start of this root dir entry

	mov word [.tmp], di		; Restore all registers except for DI

	popa

	mov word di, [.tmp]
	clc
	ret


	.filename	dw 0
	.tmp		dw 0


; --------------------------------------------------------------------------
; disk_read_fat -- Read FAT entry from floppy into disk_buffer
; IN: Nothing; OUT: carry set if failure

disk_read_fat:
	pusha

	mov ax, 1			; FAT starts at logical sector 1 (after boot sector)
	call disk_convert_l2hts

	mov si, disk_buffer		; Set ES:BX to point to 8K OS buffer
	mov bx, 1000h
	mov es, bx
	mov bx, si

	mov ah, 2			; Params for int 13h: read floppy sectors
	mov al, 9			; And read 9 of them for first FAT
	mov dl, [bootdev]
	pusha				; Prepare to enter loop


.read_fat_loop:
	popa
	pusha

	stc				; A few BIOSes do not set properly on error
	mov dl, [bootdev]
	int 13h				; Read sectors

	jnc .fat_done
	call disk_reset_floppy		; Reset controller and try again
	jnc .read_fat_loop		; Floppy reset OK?

	popa
	jmp .read_failure		; Fatal double error

.fat_done:
	popa				; Restore registers from main loop

	popa				; And restore registers from start of system call
	clc
	ret

.read_failure:
	popa
	stc				; Set carry flag (for failure)
	ret


; --------------------------------------------------------------------------
; disk_write_fat -- Save FAT contents from disk_buffer in RAM to disk
; IN: FAT in disk_buffer; OUT: carry set if failure

disk_write_fat:
	pusha

	mov ax, 1			; FAT starts at logical sector 1 (after boot sector)
	call disk_convert_l2hts

	mov si, disk_buffer		; Set ES:BX to point to 8K OS buffer
	mov bx, ds
	mov es, bx
	mov bx, si

	mov ah, 3			; Params for int 13h: write floppy sectors
	mov al, 9			; And write 9 of them for first FAT
	mov dl, [bootdev]

	stc				; A few BIOSes do not set properly on error
	int 13h				; Write sectors

	jc .write_failure		; Fatal double error

	popa				; And restore from start of system call
	clc
	ret

.write_failure:
	popa
	stc				; Set carry flag (for failure)
	ret


; --------------------------------------------------------------------------
; disk_read_root_dir -- Get the root directory contents
; IN: Nothing; OUT: root directory contents in disk_buffer, carry set if error

disk_read_root_dir:
	pusha

	mov ax, 19			; Root dir starts at logical sector 19
	call disk_convert_l2hts

	mov si, disk_buffer		; Set ES:BX to point to OS buffer
	mov bx, ds
	mov es, bx
	mov bx, si


	mov ah, 2			; Params for int 13h: read floppy sectors
	mov al, 14			; And read 14 of them (from 19 onwards)

	pusha				; Prepare to enter loop


.read_root_dir_loop:
	popa
	pusha

	stc				; A few BIOSes do not set properly on errors
	mov dl, [bootdev]
	int 13h				; Read sectors

	jnc .root_dir_finished
	call disk_reset_floppy		; Reset controller and try again
	jnc .read_root_dir_loop		; Floppy reset OK?

	popa
	jmp .read_failure		; Fatal double error


.root_dir_finished:
	popa				; Restore registers from main loop

	popa				; And restore from start of this system call
	clc				; Clear carry (for success)
	ret

.read_failure:
	popa
	stc				; Set carry flag (for failure)
	ret


; --------------------------------------------------------------------------
; disk_write_root_dir -- Write root directory contents from disk_buffer to disk
; IN: root dir copy in disk_buffer; OUT: carry set if error

disk_write_root_dir:
	pusha

	mov ax, 19			; Root dir starts at logical sector 19
	call disk_convert_l2hts

	mov si, disk_buffer		; Set ES:BX to point to OS buffer
	mov bx, ds
	mov es, bx
	mov bx, si

	mov ah, 3			; Params for int 13h: write floppy sectors
	mov al, 14			; And write 14 of them (from 19 onwards)
	mov dl, [bootdev]

	stc				; A few BIOSes do not set properly on error
	int 13h				; Write sectors
	jc .write_failure

	popa				; And restore from start of this system call
	clc
	ret

.write_failure:
	popa
	stc				; Set carry flag (for failure)
	ret


; --------------------------------------------------------------------------
; Reset floppy disk

disk_reset_floppy:
	push ax
	push dx
	mov ax, 0
; ******************************************************************
	mov dl, [bootdev]
; ******************************************************************
	stc
	int 13h
	pop dx
	pop ax
	ret


; --------------------------------------------------------------------------
; disk_convert_l2hts -- Calculate head, track and sector for int 13h
; IN: logical sector in AX; OUT: correct registers for int 13h

disk_convert_l2hts:
	push bx
	push ax

	mov bx, ax			; Save logical sector

	mov dx, 0			; First the sector
	div word [SecsPerTrack]		; Sectors per track
	add dl, 01h			; Physical sectors start at 1
	mov cl, dl			; Sectors belong in CL for int 13h
	mov ax, bx

	mov dx, 0			; Now calculate the head
	div word [SecsPerTrack]		; Sectors per track
	mov dx, 0
	div word [Sides]		; Floppy sides
	mov dh, dl			; Head/side
	mov ch, al			; Track

	pop ax
	pop bx

; ******************************************************************
	mov dl, [bootdev]		; Set correct device
; ******************************************************************

	ret


	Sides dw 2
	SecsPerTrack dw 18
; ******************************************************************
	bootdev db 0			; Boot device number
; ******************************************************************
os_seed_random:
	push bx
	push ax

	mov bx, 0
	mov al, 0x02			; Minute
	out 0x70, al
	in al, 0x71

	mov bl, al
	shl bx, 8
	mov al, 0			; Second
	out 0x70, al
	in al, 0x71
	mov bl, al

	mov word [os_random_seed], bx	; Seed will be something like 0x4435 (if it
					; were 44 minutes and 35 seconds after the hour)
	pop ax
	pop bx
	ret


	os_random_seed	dw 0


; ------------------------------------------------------------------
; os_get_random -- Return a random integer between low and high (inclusive)
; IN: AX = low integer, BX = high integer
; OUT: CX = random integer

os_get_random:
	push dx
	push bx
	push ax

	sub bx, ax			; We want a number between 0 and (high-low)
	call .generate_random
	mov dx, bx
	add dx, 1
	mul dx
	mov cx, dx

	pop ax
	pop bx
	pop dx
	add cx, ax			; Add the low offset back
	ret


.generate_random:
	push dx
	push bx

	mov ax, [os_random_seed]
	mov dx, 0x7383			; The magic number (random.org)
	mul dx				; DX:AX = AX * DX
	mov [os_random_seed], ax

	pop bx
 	pop dx
	ret

; ==================================================================

; ==================================================================
; MikeOS -- The Mike Operating System kernel
; Copyright (C) 2006 - 2014 MikeOS Developers -- see doc/LICENSE.TXT
;
; SCREEN HANDLING SYSTEM CALLS
; ==================================================================

; ------------------------------------------------------------------
; os_print_string -- Displays text
; IN: SI = message location (zero-terminated string)
; OUT: Nothing (registers preserved)

os_print_string:
	pusha

	mov ah, 0Eh			; int 10h teletype function

.repeat:
	lodsb				; Get char from string
	cmp byte [si], 255
	je t255_thingy
	cmp al, 0
	je .done			; If char is zero, end of string
	
	cmp al, 254
	je t254_thingy

	int 10h				; Otherwise, print it
	jmp .repeat			; And move on to next char

.done:
	popa
	ret
	
t255_thingy:
	mov al, ','
	int 0x10
	mov al, ' '
	int 0x10
	add si, 1
	jmp os_print_string.repeat

t254_thingy:
	inc si
	jmp os_print_string.repeat


; ------------------------------------------------------------------
; os_print_newline -- Reset cursor to start of next line
; IN/OUT: Nothing (registers preserved)

os_print_newline:
	pusha

	mov ah, 0Eh			; BIOS output char code

	mov al, 13
	int 10h
	mov al, 10
	int 10h

	popa
	ret

os_string_length:
	pusha

	mov bx, ax			; Move location of string to BX

	mov cx, 0			; Counter

.more:
	cmp byte [bx], 0		; Zero (end of string) yet?
	je .done
	cmp byte [bx], 32
	je .done
	cmp byte [bx], 13
	jle .done
	inc bx				; If not, keep adding
	inc cx
	jmp .more


.done:
	mov word [.tmp_counter], cx	; Store count before restoring other registers
	popa

	mov ax, [.tmp_counter]		; Put count back into AX before returning
	ret


	.tmp_counter	dw 0




; ------------------------------------------------------------------
; os_string_uppercase -- Convert zero-terminated string to upper case
; IN/OUT: AX = string location

os_string_uppercase:
	pusha

	mov si, ax			; Use SI to access string

.more:
	cmp byte [si], 0		; Zero-termination of string?
	je .done			; If so, quit

	cmp byte [si], 'a'		; In the lower case A to Z range?
	jb .noatoz
	cmp byte [si], 'z'
	ja .noatoz

	sub byte [si], 20h		; If so, convert input char to upper case

	inc si
	jmp .more

.noatoz:
	inc si
	jmp .more

.done:
	popa
	ret



; ------------------------------------------------------------------
; os_string_copy -- Copy one string into another
; IN: SI = source, DI = destination (programmer ensure sufficient room),
; OUT: CX count until space or 0

os_string_copy:
	mov cx, 0
	push si

.more:
	lodsb
	stosb
	inc cx
	cmp al, 32
	je .done
	cmp byte al, 0			; If source string is empty, quit out
	jne .more

.done:
	pop si
	ret

; ------------------------------------------------------------------
; os_string_compare -- See if two strings match
; IN: SI = string one, DI = string two
; OUT: carry set if same, clear if different

os_string_compare:
	pusha

.more:
	mov al, [si]			; Retrieve string contents
	mov bl, [di]

	cmp al, bl			; Compare characters at current location
	jne .not_same

	cmp al, 0			; End of first string? Must also be end of second
	je .terminated

	inc si
	inc di
	jmp .more


.not_same:				; If unequal lengths with same beginning, the byte
	popa				; comparison fails at shortest string terminator
	clc				; Clear carry flag
	ret


.terminated:				; Both strings terminated at the same position
	popa
	stc				; Set carry flag
	ret



; ------------------------------------------------------------------
; os_string_to_int -- Convert decimal string to integer value
; IN: SI = string location (max 5 chars, up to '65536')
; OUT: AX = number, DX = amount of chars the number was

os_string_to_int:
	pusha

	mov ax, si			; First, get length of string
	call os_string_length
	mov [.tmp2], ax

	add si, ax			; Work from rightmost char in string
	dec si

	mov cx, ax			; Use string length as counter

	mov bx, 0			; BX will be the final number
	mov ax, 0


	; As we move left in the string, each char is a bigger multiple. The
	; right-most character is a multiple of 1, then next (a char to the
	; left) a multiple of 10, then 100, then 1,000, and the final (and
	; leftmost char) in a five-char number would be a multiple of 10,000

	mov word [.multiplier], 1	; Start with multiples of 1

.loop:
	mov ax, 0
	mov byte al, [si]		; Get character

	sub al, 48			; Convert from ASCII to real number

	mul word [.multiplier]		; Multiply by our multiplier

	add bx, ax			; Add it to BX

	push ax				; Multiply our multiplier by 10 for next char
	mov word ax, [.multiplier]
	mov dx, 10
	mul dx
	mov word [.multiplier], ax
	pop ax

	dec cx				; Any more chars?
	cmp cx, 0
	je .finish
	dec si				; Move back a char in the string
	jmp .loop

.finish:
	mov word [.tmp], bx
	popa
	mov word ax, [.tmp]
	mov word dx, [.tmp2]

	ret


	.multiplier	dw 0
	.tmp		dw 0
	.tmp2 dw 0


; ------------------------------------------------------------------
; os_int_to_string -- Convert unsigned integer to string
; IN: AX = signed int
; OUT: AX = string location

os_int_to_string:
	pusha

	mov cx, 0
	mov bx, 10			; Set BX 10, for division and mod
	mov di, .t			; Get our pointer ready

.push:
	mov dx, 0
	div bx				; Remainder in DX, quotient in AX
	inc cx				; Increase pop loop counter
	push dx				; Push remainder, so as to reverse order when popping
	test ax, ax			; Is quotient zero?
	jnz .push			; If not, loop again
.pop:
	pop dx				; Pop off values in reverse order, and add 48 to make them digits
	add dl, '0'			; And save them in the string, increasing the pointer each time
	mov es:[di], dl
	inc di
	dec cx
	jnz .pop

	mov byte es:[di], 0		; Zero-terminate string

	popa
	mov ax, .t			; Return location of string
	ret


	.t times 7 db 0

; ------------------------------------------------------------------
; os_string_tokenize -- Reads tokens separated by specified char from
; a string. Returns pointer to next token, or 0 if none left
; IN: AL = separator char, SI = beginning; OUT: DI = next token or 0 if none


os_string_tokenize:
	push si

.next_char:
	cmp byte [si], al
	je .return_token
	cmp byte [si], 0
	jz .no_more
	inc si
	jmp .next_char

.return_token:
	mov byte [si], 0
	inc si
	mov di, si
	pop si
	ret

.no_more:
	mov di, 0
	pop si
	ret


os_fatal_error:
	mov ah, 0x0e
	mov al, 65
	int 0x10
	jmp $


list_directory:
	
	call os_print_newline
	mov cx,	0			; Counter

	mov ax, dirlist			; Get list of files on disk
	call os_get_file_list
	
	mov si, volumeof
	call os_print_string
	mov si, os_get_file_list.volumenamebuffer
	call os_print_string
	call os_print_newline
	
	mov si, dirlist
	mov ah, 0Eh			; BIOS teletype function

.repeat:
	lodsb				; Start printing filenames
	cmp al, 0			; Quit if end of string
	je done2

	cmp al, ','			; If comma in list string, don't print it
	jne .nonewline
	pusha
	call os_print_newline		; But print a newline instead
	popa
	jmp .repeat

.nonewline:
	pusha
	mov bx, 0
	call delay
	popa
	int 10h
	jmp list_directory.repeat

done2:
	ret
	
volumeof db 'Dir of ', 0
	
os_bcd_to_int:
	pusha

	mov bl, al			; Store entire number for now

	and ax, 0Fh			; Zero-out high bits
	mov cx, ax			; CH/CL = lower BCD number, zero extended

	shr bl, 4			; Move higher BCD number into lower bits, zero fill msb
	mov al, 10
	mul bl				; AX = 10 * BL

	add ax, cx			; Add lower BCD to 10*higher
	mov [.tmp], ax

	popa
	mov ax, [.tmp]			; And return it in AX!
	ret


	.tmp	dw 0

os_print_pcx:
	mov cx, 36864			; Load PCX at 36864 (4K after program start)
	call os_load_file ;loads file at cx:0x0000
	


	mov ah, 0			; Switch to graphics mode
	mov al, 13h
	int 10h


	mov ax, 0A000h			; ES = video memory
	mov es, ax


	mov si, 80h
	mov ax, 36864		; Move source to start of image data
	mov ds, ax
					; (First 80h bytes is header)

	mov di, 0			; Start our loop at top of video RAM

decode:
	mov cx, 1
	lodsb
	cmp al, 192			; Single pixel or string?
	jb single
	and al, 63			; String, so 'mod 64' it
	mov cl, al			; Result in CL for following 'rep'
	lodsb				; Get byte to put on screen
single:
	rep stosb			; And show it (or all of them)
	cmp di, 64001
	jb decode
	
	mov [tmp_location], si

	mov dx, 3c8h			; Palette index register
	mov al, 0			; Start at colour 0
	out dx, al			; Tell VGA controller that...
	inc dx				; ...3c9h = palette data register

	mov cx, 768			; 256 colours, 3 bytes each
setpal:
	lodsb				; Grab the next byte.
	shr al, 2			; Palettes divided by 4, so undo
	out dx, al			; Send to VGA controller
	loop setpal
	mov bx, [tmp_location]
	ret
	
tmp_location dw 0 ;here we will store where the start of the palette is, then pass it back to the main program, if needed.