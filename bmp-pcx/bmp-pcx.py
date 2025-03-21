#!/usr/bin/env python3

import argparse
from PIL import Image
import subprocess

# Function to convert BMP to 8-bit
def convert_to_8bit(image_path):
    img = Image.open(image_path)

    # Convert to 8-bit (indexed color)
    img = img.convert("P", palette=Image.ADAPTIVE, colors=256)
    
    # Save the image as 8-bit BMP
    output_8bit_bmp = "output_8bit.bmp"
    img.save(output_8bit_bmp)
    return output_8bit_bmp

# Function to convert 8-bit BMP to PCX using ImageMagick
def bmp_to_pcx(input_bmp, output_pcx):
    # Use ImageMagick's convert command via subprocess to convert BMP to PCX
    try:
        subprocess.run(["convert", input_bmp, output_pcx], check=True)
        print(f"Image successfully saved as {output_pcx}")
    except subprocess.CalledProcessError as e:
        print(f"Error during conversion: {e}")

# Main function to convert BMP to 8-bit and then to PCX
def main(input_bmp, output_pcx):
    # Step 1: Convert BMP to 8-bit BMP
    output_8bit_bmp = convert_to_8bit(input_bmp)

    # Step 2: Convert the 8-bit BMP to PCX
    bmp_to_pcx(output_8bit_bmp, output_pcx)

if __name__ == "__main__":
    # Set up the argument parser
    parser = argparse.ArgumentParser(description="Convert BMP to PCX via 8-bit conversion.")
    parser.add_argument("input_bmp", help="Path to the input BMP file")
    parser.add_argument("output_pcx", help="Path to the output PCX file")

    # Parse the arguments
    args = parser.parse_args()
    # Run the main function with the provided arguments
    main(args.input_bmp, args.output_pcx)