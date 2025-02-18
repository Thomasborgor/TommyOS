import os

def file_to_binary(filename):
    # Check if the file exists
    if not os.path.isfile(filename):
        raise FileNotFoundError(f"The file '{filename}' does not exist.")
    
    try:
        # Open the file in binary mode
        with open(filename, 'rb') as file:
            # Read the entire file content
            file_content = file.read()
            
            # Convert each byte to its binary representation with '0b' prefix
            binary_representation = [f'0b{format(byte, "08b")}' for byte in file_content]
            
            # Join the binary values with commas
            return ', '.join(binary_representation)
    except Exception as e:
        raise Exception(f"An error occurred while processing the file: {str(e)}")

def save_binary_output(filename, output_filename):
    try:
        # Convert file to binary
        binary_data = file_to_binary(filename)
        
        # Write the binary data to a new file
        with open(output_filename, 'w') as output_file:
            output_file.write(binary_data)

        print(f"Binary data has been written to {output_filename}")
    except Exception as e:
        print(f"Error: {str(e)}")

if __name__ == '__main__':
    # Input and output filenames
    input_filename = input("Enter the file path to convert to binary: ")
    output_filename = input("Enter the output file name (e.g., output.txt): ")

    # Save the binary output
    save_binary_output(input_filename, output_filename)
