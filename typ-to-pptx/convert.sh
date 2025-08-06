export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Check for exactly one argument
if [ $# -ne 1 ]; then
  echo "Usage: $0 <input.typ>"
  exit 1
fi

typ_file="$1"

# Check if file exists
if [ ! -f "$typ_file" ]; then
  echo "Error: Typst file '$typ_file' not found."
  exit 1
fi

# Strip .typ extension and get base name
base_name="${typ_file%.typ}"
pdf_file="${base_name}.pdf"

# Compile Typst to PDF
echo "📄 Compiling Typst to PDF..."
if typst compile "$typ_file" "$pdf_file"; then
  echo "✅ PDF created: $pdf_file"
else
  echo "❌ Typst compilation failed."
  exit 1
fi

# Convert PDF to PowerPoint
echo "🎞️ Converting PDF to PowerPoint..."
script_dir="$(dirname "$(realpath "$0")")"
if "$script_dir/pdf2pptx/pdf2pptx.sh" "$pdf_file"; then
  pptx_file="${pdf_file}.pptx"
  echo "✅ PPTX created: $pptx_file"
else
  echo "❌ Conversion to PowerPoint failed."
  exit 1
fi

