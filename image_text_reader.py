#!/usr/bin/env python3
"""
Image Text Reader using OCR
Reads text from image files using Tesseract OCR
"""

import os
import sys
from PIL import Image
import pytesseract
import argparse
import glob

def setup_tesseract():
    """
    Setup Tesseract path if needed (mainly for Windows)
    """
    # Uncomment and modify the path below if on Windows
    pytesseract.pytesseract.tesseract_cmd = r'C:\Program Files\Tesseract-OCR\tesseract.exe'
    pass

def read_text_from_image(image_path, lang='eng', config=''):
    """
    Extract text from an image file
    
    Args:
        image_path (str): Path to the image file
        lang (str): Language for OCR (default: 'eng')
        config (str): Additional Tesseract configuration
    
    Returns:
        str: Extracted text
    """
    try:
        # Open and process the image
        image = Image.open(image_path)
        
        # Convert to RGB if necessary
        if image.mode != 'RGB':
            image = image.convert('RGB')
        
        # Extract text using Tesseract
        text = pytesseract.image_to_string(image, lang=lang, config=config)
        
        return text.strip()
    
    except Exception as e:
        print(f"Error processing {image_path}: {str(e)}")
        return None

def process_multiple_images(image_paths, lang='eng', output_file=None):
    """
    Process multiple images and extract text
    
    Args:
        image_paths (list): List of image file paths
        lang (str): Language for OCR
        output_file (str): Optional output file to save results
    """
    results = []
    
    for image_path in image_paths:
        print(f"Processing: {image_path}")
        text = read_text_from_image(image_path, lang)
        
        if text:
            result = {
                'file': image_path,
                'text': text
            }
            results.append(result)
            print(f"Text extracted successfully from {image_path}")
            print("-" * 50)
            print(text)
            print("-" * 50)
        else:
            print(f"Failed to extract text from {image_path}")
    
    # Save to file if specified
    if output_file and results:
        with open(output_file, 'w', encoding='utf-8') as f:
            for result in results:
                f.write(f"File: {result['file']}\n")
                f.write(f"Text:\n{result['text']}\n")
                f.write("=" * 80 + "\n\n")
        print(f"Results saved to {output_file}")
    
    return results

def main():
    """Main function to handle command line arguments"""
    setup_tesseract()
    
    parser = argparse.ArgumentParser(description='Extract text from images using OCR')
    parser.add_argument('images', nargs='+', help='Image file(s) or pattern (e.g., *.jpg)')
    parser.add_argument('-l', '--lang', default='eng', 
                       help='Language for OCR (default: eng). Use eng+fra for multiple languages')
    parser.add_argument('-o', '--output', help='Output file to save extracted text')
    parser.add_argument('--config', default='', 
                       help='Additional Tesseract config (e.g., "--psm 6")')
    
    args = parser.parse_args()
    
    # Expand file patterns
    image_files = []
    for pattern in args.images:
        if '*' in pattern or '?' in pattern:
            image_files.extend(glob.glob(pattern))
        else:
            image_files.append(pattern)
    
    # Filter for valid image files
    valid_extensions = {'.png', '.jpg', '.jpeg', '.tiff', '.bmp', '.gif'}
    image_files = [f for f in image_files if os.path.splitext(f.lower())[1] in valid_extensions]
    
    if not image_files:
        print("No valid image files found!")
        sys.exit(1)
    
    print(f"Found {len(image_files)} image file(s) to process")
    
    # Process images
    results = process_multiple_images(image_files, args.lang, args.output)
    
    print(f"\nProcessing complete! Successfully extracted text from {len(results)} image(s)")

def simple_example():
    """
    Simple example function for basic usage
    """
    # Example usage for a single image
    image_path = "example.jpg"  # Replace with your image path
    
    if os.path.exists(image_path):
        text = read_text_from_image(image_path)
        if text:
            print("Extracted text:")
            print(text)
        else:
            print("No text found or error occurred")
    else:
        print(f"Image file {image_path} not found")

if __name__ == "__main__":
    # Check if any arguments were provided
    if len(sys.argv) > 1:
        main()
    else:
        print("Image Text Reader")
        print("Usage examples:")
        print("  python script.py image.jpg")
        print("  python script.py *.png -o output.txt")
        print("  python script.py image.jpg -l eng+fra")
        print("\nFor help: python script.py -h")
        print("\nRunning simple example...")
        simple_example()
