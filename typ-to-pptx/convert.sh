#!/bin/bash

# Check for exactly one argument
if [ $# -ne 1 ]; then
  echo "Usage: $0 <input.typ|input.pdf>"
  exit 1
fi

input_file="$1"

# Check if file exists
if [ ! -f "$input_file" ]; then
  echo "Error: File '$input_file' not found."
  exit 1
fi

# Determine file type
extension="${input_file##*.}"
script_dir="$(dirname "$(realpath "$0")")"

if [ "$extension" == "typ" ]; then
  # Compile Typst to PDF
  base_name="${input_file%.typ}"
  pdf_file="${base_name}.pdf"

  echo "📄 Compiling Typst to PDF..."
  if typst compile "$input_file" "$pdf_file"; then
    echo "✅ PDF created: $pdf_file"
  else
    echo "❌ Typst compilation failed."
    exit 1
  fi
elif [ "$extension" == "pdf" ]; then
  pdf_file="$input_file"
  echo "📄 Using existing PDF: $pdf_file"
else
  echo "❌ Unsupported file type: .$extension"
  exit 1
fi

# Convert PDF to PowerPoint
echo "🎞️ Converting PDF to PowerPoint..."
if "$script_dir/pdf2pptx/pdf2pptx.sh" "$pdf_file" "widescreen" "2"; then
  pptx_file="${pdf_file}.pptx"
  echo "✅ PPTX created: $pptx_file"
else
  echo "❌ Conversion to PowerPoint failed."
  exit 1
fi

