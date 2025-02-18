import sys

def binary_to_hex(file_path):
    with open(file_path, 'rb') as f:
        data = f.read()
    
    result = []
    zero_count = 0
    
    for byte in data:
        if byte == 0:
            zero_count += 1
        else:
            if zero_count > 0:
                result.append(f"{zero_count} dup(0)")
                zero_count = 0
            result.append(f"0x{byte:02X}")
    
    # If file ends with zeros, handle it
    if zero_count > 0:
        result.append(f"{zero_count} dup(0)")
    
    print(", ".join(result))

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python script.py <binary file>")
    else:
        binary_to_hex(sys.argv[1])
