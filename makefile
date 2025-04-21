# Variables

# Default target
not:
	nasm -fbin ./boot/bootloader.asm -o ./boot/bootloader.bin
	nasm -fbin kernel.asm -o kernel.bin
	nasm -fbin ./cdcmd/write.asm -o ./cdcmd/write.bin
	nasm -fbin ./cdcmd/screensaver.asm -o ./cdcmd/screensaver.bin
	nasm -fbin ./cdcmd/tlang.asm -o ./cdcmd/tlang.bin
	nasm -fbin ./cdcmd/haha.asm -o ./cdcmd/haha.bin
	nasm -fbin ./cdcmd/line.asm -o ./cdcmd/line.bin
	nasm -fbin ./cdcmd/paint.asm -o ./cdcmd/paint.bin

	@echo "Creating Preloaded Images..."
	#bmp-pcx ./extra/sample.bmp ./extra/logo.pcx
	rm -f mydisk.img -f floppy.img -f image2.img
	
	@echo "Creating floppy image..."
	mkdosfs -C floppy.img 1440 -F12
	mkdosfs -C image2.img 1440
	mkdosfs -C mydisk.img 2880 -F12 -M0xF8
	mcopy -i mydisk.img ./extra/test.txt ::TEST.TXT
	dd if=./boot/bootloader.bin of=floppy.img bs=512 conv=notrunc status=noxfer
	mcopy -i floppy.img kernel.bin ::KERNEL.BIN
	mcopy -i floppy.img ./cdcmd/write.bin ::WRITE.BIN
	mcopy -i floppy.img ./cdcmd/screensaver.bin ::SCRNSAVR.BIN
	mcopy -i floppy.img ./cdcmd/tlang.bin ::BASIC.BIN
	mcopy -i floppy.img ./extra/test.txt ::SAMPLE.TXT
	mcopy -i floppy.img ./extra/logo.pcx ::BOOT.PCX
	mcopy -i image2.img ./extra/logo.pcx ::LOGO.PCX
	mcopy -i floppy.img ./guessnum.tom ::number.TOM
	mcopy -i floppy.img ./cdcmd/haha.bin ::format.bin
	mcopy -i floppy.img ./cdcmd/paint.bin ::PAINT.BIN
	clear
	
commit:
	@read -p "Enter commit message: " msg; \
	git add . && \
	git commit -m "$$msg" && \
	git push --force origin main 

small:
	qemu-system-x86_64 -boot order=a -fda floppy.img -fdb image2.img -hda mydisk.img

	clear
	
big:
	qemu-system-x86_64 -boot order=a -fda floppy.img -fdb image2.img -hda mydisk.img -full-screen
	clear
	
iso_image:
	mkisofs -quiet -V 'TOMMYOS' -input-charset iso-8859-1 -o ./floppy.iso -b floppy.img ./
	
tomc:
	@rm -rf dist build tommyos_compile.spec
	pyinstaller --onefile ./tomc/tommyos_compile.py
	sudo cp dist/tommyos_compile /usr/bin/tomc

bmp-pcx:
	@rm -rf dist build bmp-pcx.spec
	pyinstaller --onefile ./bmp-pcx/bmp-pcx.py
	sudo cp dist/bmp-pcx /usr/bin/bmp-pcx
	
treassemble:
	@rm -rf dist build treassemble.spec
	pyinstaller --onefile ./treassemble/treassemble.py
	sudo cp dist/treassemble /usr/bin/treassemble
	
idenbpb:
	@rm -rf dist build idenbpb.spec
	pyinstaller --onefile ./idenbpb/idenpbp.py
	sudo cp dist/idenpbp /usr/bin/idenbpb
	
makehex:
	@rm -rf dist build makehex.spec
	pyinstaller --onefile ./makehex/makehex.py
	sudo cp dist/makehex /usr/bin/makehex
	
	
	
		
