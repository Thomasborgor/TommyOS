#!/usr/bin/env python3
import argparse
import os


def process_labels_and_jumps(input_file, output_file):
    """Process labels, validate syntax, and replace jump commands with correct line numbers."""
    lines = []
    label_map = {}

    # Step 1: Read and preprocess the file
    with open(input_file, 'r') as infile:
        for raw_line in infile:
            # Strip comments ('$' or ';') and whitespace
            line = raw_line.split(';')[0].split('$')[0].strip()
            if line:
                lines.append(line)

    # Step 2: First pass - Identify and remove labels before validation
    filtered_lines = []
    current_line_number = 0
    for line in lines:
        parts = line.split()
        if len(parts) == 1 and line.endswith(':'):  # Standalone label
            label = line[:-1].strip()  # Remove ':'
            label_map[label] = current_line_number+1  # Save current line number
        else:
            filtered_lines.append(line)
            current_line_number += 1

    # Step 3: Validate the syntax of the filtered lines
    validate_code(filtered_lines)  # Validation now runs after labels are removed

    # Step 4: Second pass - Replace labels in jump commands
    jump_commands = {"jmp", "jne", "jye", "jgr", "jls"}
    final_lines = []
    for line in filtered_lines:
        parts = line.split()
        if parts and parts[0] in jump_commands:
            command = parts[0]
            if len(parts) == 2:
                label = parts[1]
                if label in label_map:
                    line_number = label_map[label]
                    line = f"{command} {line_number:03d}"
                else:
                    raise ValueError(f"Undefined label: {label}")
        final_lines.append(line)

    # Step 5: Write processed lines to output file
    with open(output_file, 'w') as outfile:
        for line in final_lines:
            outfile.write(line + '\n')


def validate_line_syntax(line, line_number):
    """Validate the syntax of a single line of code."""
    commands = {
        "def": 1, "mov": 2, "add": 2, "sub": 2, "inc": 1, "dec": 1,
        "bel": 2, "del": 1, "getky": 2, "cmpsr": 0, "jne": 1, "jmp": 1,
        "jye": 1, "jgr": 1, "jls": 1, "prt": None, "hlt": 0, "cmp": 2,
        "clr": 0, "ask": 1, "rnd": 3, "int": 2,
    }

    parts = line.split()
    if not parts:
        raise ValueError(f"Line {line_number}: Empty line or invalid syntax.")
    
    command = parts[0]
    args = parts[1:]
    
    # Validate command
    if command not in commands:
        raise ValueError(f"Line {line_number}: Unknown command '{command}'.")

    # Validate numbers in arguments
    for arg in args:
        if arg.isdigit() and len(arg) != 3:
            raise ValueError(f"Line {line_number}: Invalid number '{arg}'. Numbers must be three digits.")


def validate_code(lines):
    """Validate the syntax of the entire code."""
    for line_number, line in enumerate(lines, start=1):
        validate_line_syntax(line, line_number)


def compile_file(input_file, output_file):
    """Compile BASIC code to .tom file with label handling and error checking."""
    print(f"Compiling {input_file} to {output_file}...")

    # Process labels, validate syntax, and replace jump commands
    process_labels_and_jumps(input_file, output_file)

    print(f"Compilation complete! Output written to {output_file}")


def main():
    parser = argparse.ArgumentParser(
        description="TommyOS BASIC Compiler (tomc)",
        epilog="Compiles TommyOS BASIC .tomsrc files to stripped .tom files."
    )
    
    # Define arguments
    parser.add_argument("input_file", help="The input BASIC file (.tomsrc)")
    parser.add_argument("-o", "--output", help="The output file (.tom)", required=True)
    parser.add_argument("--version", action="version", version="tomc 1.0.0")

    args = parser.parse_args()

    # Validate input file
    if not os.path.isfile(args.input_file):
        print(f"Error: {args.input_file} does not exist.")
        return

    # Compile the file
    compile_file(args.input_file, args.output)


if __name__ == "__main__":
    main()
