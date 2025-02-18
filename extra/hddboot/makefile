not:
	
	nasm -fbin boot.asm -o boot.bin
	nasm -fbin kernel.asm -o kernel.bin
	rm disk.img
	mkdosfs -C disk.img -F16 10000 -M0xF8
	dd if=boot.bin of=disk.img bs=512 conv=notrunc count=1
	#dd if=kernel.bin of=disk.img bs=512 conv=notrunc seek=2078 count=1
	mcopy -i disk.img kernel.bin ::KERNEL.BIN
	
	
hdd:
	qemu-system-i386 -hda disk.img




