import sys
from capstone import *

def disassemble_binary(binary_file, asm_file, arch=CS_ARCH_X86, mode=CS_MODE_16):
    """
    Disassemble a binary file into an assembly file.

    :param binary_file: Path to the binary file
    :param asm_file: Path to save the assembly file
    :param arch: Architecture (default is x86)
    :param mode: Mode (default is 16-bit mode for x86)
    """
    try:
        # Open the binary file and read its content
        with open(binary_file, "rb") as f:
            code = f.read()

        # Initialize the disassembler
        md = Cs(arch, mode)
        md.detail = True  # Enable detailed mode for additional info

        # Disassemble and write to the output file
        with open(asm_file, "w") as asm:
            asm.write(f"; Disassembled from {binary_file}\n\n")
            for i in md.disasm(code, 0x0000):  # Start disassembly from address 0
                asm.write(f"{i.address:04x}: {i.mnemonic} {i.op_str}\n")

        print(f"Disassembly completed. Assembly saved to {asm_file}")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python disassemble.py <binary_file> <asm_file>")
    else:
        binary_file = sys.argv[1]
        asm_file = sys.argv[2]
        disassemble_binary(binary_file, asm_file)
