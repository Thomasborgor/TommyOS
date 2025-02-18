# TommyOS

Welcome!
To try TommyOS for yourself, download "floppy.img" in main.
You can then use my personal favorite disk imager, Roadkil's Disk Image, to burn it to a floppy disk.
If you want to build TommyOS yourself, download main and run "make not". 
You will need NASM and mtools for the build. To emulate TommyOS, you will need to install Qemu, and run "make small".
Running "make large" will launch Qemu in fullscreen. 

If you are planning on creating your own executable binary files, they must be centered at orgin 0x8000, or 32768.
If you want to interact with the FAT12 filesystem, then include ./extra/functions.asm. Be sure, if you want to create files in the binary,
call custom_create_file with the filename location in AX. Single paramters will be passed by the command line in TommyOS in si, but si will equal 0xFF if there are no parameters.
When writing to files or removing file or anything that doesn't require creating a file, use the build in MikeOS functions os_write_file, os_remove_file, os_copy_file etc.

If you want to run TommyOS on a HDD instead of a floppy disk, first burn to a floppy disk and then use FORMAT.BIN to format the primary master IDE hard drive with just the bootloader of TommyOS.
You will then have to copy over KERNEL.BIN and other programs yourself.

Please report any bugs you find!


Thanks for the support,

TommyOS team