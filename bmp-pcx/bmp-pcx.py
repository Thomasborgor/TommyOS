#!/usr/bin/env python3

import argparse
from PIL import Image, ImageOps
import subprocess
import os

# Resize image to 320x200 with black bars on the sides, maintaining aspect ratio
def resize_with_black_bars(image):
    target_size = (320, 200)
    # Resize based on height, maintain aspect ratio
    w, h = image.size
    scale = target_size[1] / h
    new_w = int(w * scale)
    new_h = target_size[1]

    resized = image.resize((new_w, new_h), Image.LANCZOS)

    # Create black background image
    final = Image.new("RGB", target_size, (0, 0, 0))
    paste_x = (target_size[0] - new_w) // 2
    final.paste(resized, (paste_x, 0))

    return final

# Convert image to 8-bit palette
def convert_to_8bit(image):
    return image.convert("P", palette=Image.ADAPTIVE, colors=256)

# Save 8-bit BMP for further conversion
def save_temp_bmp(image):
    temp_bmp = "temp_8bit.bmp"
    image.save(temp_bmp)
    return temp_bmp

# Use ImageMagick to convert BMP to PCX
def bmp_to_pcx(input_bmp, output_pcx):
    try:
        subprocess.run(["convert", input_bmp, output_pcx], check=True)
        print(f"Image successfully saved as {output_pcx}")
    except subprocess.CalledProcessError as e:
        print(f"Error during conversion: {e}")

# Main process
def main(input_path, output_path):
    # Load image
    img = Image.open(input_path).convert("RGB")  # Force RGB in case it's palette or grayscale

    # Resize with pillarbox if needed
    resized_img = resize_with_black_bars(img)

    # Convert to 8-bit
    img_8bit = convert_to_8bit(resized_img)

    # Save temp BMP
    temp_bmp = save_temp_bmp(img_8bit)

    # Convert to PCX
    bmp_to_pcx(temp_bmp, output_path)

    # Clean up temporary BMP file
    os.remove(temp_bmp)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Convert BMP to 320x200 8-bit PCX with aspect ratio maintained.")
    parser.add_argument("input_bmp", help="Path to input BMP")
    parser.add_argument("output_pcx", help="Path to output PCX")
    args = parser.parse_args()
    main(args.input_bmp, args.output_pcx)
#!/usr/bin/env python3

import argparse
import subprocess

def convert_bmp_to_pcx(input_bmp, output_pcx):
    try:
        subprocess.run([
            "convert",
            input_bmp,
            "-resize", "320x200",
            "-background", "black",
            "-gravity", "center",
            "-extent", "320x200",
            "-colors", "256",
            "-define", "bmp:subtype=RGB",
            output_pcx
        ], check=True)
        print(f"Image converted and saved as: {output_pcx}")
    except subprocess.CalledProcessError as e:
        print(f"ImageMagick convert failed: {e}")

def main():
    parser = argparse.ArgumentParser(description="Convert any image to 320x200 PCX (8-bit, centered, black bars if needed).")
    parser.add_argument("input_bmp", help="Path to input BMP (or any format ImageMagick supports)")
    parser.add_argument("output_pcx", help="Path to output PCX file")
    args = parser.parse_args()

    convert_bmp_to_pcx(args.input_bmp, args.output_pcx)

if __name__ == "__main__":
    main()
