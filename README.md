# TommyOS

Welcome!
To try TommyOS for yourself, download "floppy.img" in main.
You can then use my personal favorite disk imager, Roadkil's Disk Image, to burn it to a floppy disk.
If you want to build TommyOS yourself, download main and run "make not". 
You will need NASM mtools, and make for the build. To emulate TommyOS, you will need to install Qemu-system-x86_64, and run "make small".
Running "make large" will launch Qemu in fullscreen. 

If you want to run TommyOS on a HDD instead of a floppy disk, first burn to a floppy disk and then use FORMAT.BIN to format the primary master IDE hard drive with just the bootloader of TommyOS.
You will then have to copy over KERNEL.BIN and other programs yourself.

Please report any bugs you find!


Thanks for the support,

TommyOS team


A very big thanks to MikeOS, as a lot of their code is in here!