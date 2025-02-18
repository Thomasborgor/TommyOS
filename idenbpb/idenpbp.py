import sys
import binascii
from capstone import Cs, CS_ARCH_X86, CS_MODE_16  # For bootloader disassembly

def read_bytes(file_path, offset, length):
    """ Reads raw bytes from a file at a specific offset """
    with open(file_path, "rb") as f:
        f.seek(offset)
        return f.read(length)

def print_hex_and_string(label, data):
    """ Prints data as both hex bytes and an ASCII string """
    hex_data = ' '.join(f"{b:02X}" for b in data)
    text_data = ''.join(chr(b) if 32 <= b < 127 else '.' for b in data)
    print(f"{label}: {text_data} ({hex_data})")

def parse_bpb(file_path):
    """ Parses the BIOS Parameter Block (BPB) manually without struct """
    data = read_bytes(file_path, 0, 64)  # Read enough bytes for BPB and boot sector

    if len(data) < 36:
        print(f"Error: BPB is too small ({len(data)} bytes).")
        return

    print_hex_and_string("OEM Label", data[3:11])
    print(f"Bytes Per Sector: {int.from_bytes(data[11:13], 'little')}")
    print(f"Sectors Per Cluster: {data[13]}")
    print(f"Reserved Sectors: {int.from_bytes(data[14:16], 'little')}")
    print(f"Number of FATs: {data[16]}")
    print(f"Root Directory Entries: {int.from_bytes(data[17:19], 'little')}")
    print(f"Total Logical Sectors: {int.from_bytes(data[19:21], 'little')}")
    print(f"Media Descriptor: {data[21]:#04X}")
    print(f"Sectors Per FAT: {int.from_bytes(data[22:24], 'little')}")
    print(f"Sectors Per Track: {int.from_bytes(data[24:26], 'little')}")
    print(f"Number of Heads: {int.from_bytes(data[26:28], 'little')}")
    print(f"Hidden Sectors: {int.from_bytes(data[28:32], 'little')}")
    print(f"Large Sector Count: {int.from_bytes(data[32:36], 'little')}")

    # FAT12/16 Extended BPB (if it exists)
    if len(data) >= 62:
        print(f"Drive Number: {data[36]}")
        print(f"Boot Signature: {data[38]:#02X}")
        print(f"Volume ID: {int.from_bytes(data[39:43], 'little'):#010X}")
        print_hex_and_string("Volume Label", data[43:54])
        print_hex_and_string("File System", data[54:62])

def dump_bootloader(file_path):
    """ Reads and disassembles the first 512 bytes (bootloader) """
    bootloader = read_bytes(file_path, 0, 512)

    print("\n--- Bootloader Hex Dump ---")
    for i in range(0, len(bootloader), 16):
        chunk = bootloader[i:i+16]
        hex_chunk = ' '.join(f"{b:02X}" for b in chunk)
        ascii_chunk = ''.join(chr(b) if 32 <= b < 127 else '.' for b in chunk)
        print(f"{i:04X}: {hex_chunk:<48} {ascii_chunk}")

    print("\n--- Bootloader Disassembly ---")
    md = Cs(CS_ARCH_X86, CS_MODE_16)  # 16-bit x86 mode for BIOS bootloaders
    for i in md.disasm(bootloader, 0x7C00):  # Bootloaders are loaded at 0x7C00
        print(f"0x{i.address:04X}: {i.mnemonic} {i.op_str}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python dump_bpb.py <disk.img>")
        sys.exit(1)

    disk_img = sys.argv[1]
    
    print("\n=== BIOS Parameter Block (BPB) Dump ===")
    parse_bpb(disk_img)

    dump_bootloader(disk_img)
