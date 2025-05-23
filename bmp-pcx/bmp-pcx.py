#!/usr/bin/env python3

import argparse
import subprocess

def convert_to_pcx(input_image, output_pcx):
    try:
        subprocess.run([
            "convert",
            input_image,
            "-resize", "320x200",
            "-background", "black",
            "-gravity", "center",
            "-extent", "320x200",
            "-colors", "48",
            output_pcx
        ], check=True)
        print(f"Converted '{input_image}' to '{output_pcx}' successfully.")
    except subprocess.CalledProcessError as e:
        print(f"ImageMagick convert failed: {e}")

def main():
    parser = argparse.ArgumentParser(description="Convert any image to 320x200 PCX with black bars and 8-bit palette.")
    parser.add_argument("input_image", help="Path to input image (any supported format)")
    parser.add_argument("output_pcx", help="Path to output PCX file")
    args = parser.parse_args()

    convert_to_pcx(args.input_image, args.output_pcx)

if __name__ == "__main__":
    main()
