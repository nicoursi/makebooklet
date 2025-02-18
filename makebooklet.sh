#!/bin/bash

# Default values
input=""
signature=20
pagesize=""  # Auto-detected
trim="0cm 0cm 0cm 0cm"
delta="0cm 0cm"
output=""
temp_tex="temp_booklet.tex"
totalpages=""
clip_option=""

# Help message
usage() {
    echo "Usage: $0 -i <input.pdf> [-a4 | -a5] [-s <signature>] [-p <totalpages>] [-t <'L T R B'>] [-d <'X Y'>] [-o <output.pdf>] [-c]"
    echo
    echo "Options:"
    echo "  -i   Input PDF file (required)"
    echo "  -a4  Force A4 source pages"
    echo "  -a5  Force A5 source pages"
    echo "  -s   Signature size (default: $signature)"
    echo "  -p   Total number of pages (auto-detected if not provided)"
    echo "  -t   Trim margins (left top right bottom), e.g., '1cm 1cm 1cm 1cm' (default: $trim)"
    echo "  -d   Delta adjustments (horizontal vertical), e.g., '0.5cm 0cm' (default: $delta)"
    echo "  -o   Output PDF file (default: '<input>-booklet.pdf')"
    echo "  -c   Clip the input PDF page content (useful for cropping a specific area). For example if you need to get rid of page numbers from the original document"
    echo "  -h   Show this help message"
    exit 1
}

# Parse command-line arguments
while getopts "i:s:p:t:d:o:a45ch" opt; do
    case ${opt} in
        i) input="$OPTARG" ;;
        s) signature="$OPTARG" ;;
        p) totalpages="$OPTARG" ;;
        t) trim="$OPTARG" ;;
        d) delta="$OPTARG" ;;
        o) output="$OPTARG" ;;
        a4) pagesize="A4" ;;
        a5) pagesize="A5" ;;
        c) clip_option="clip" ;;
        h) usage ;;
        *) usage ;;
    esac
done

# Validate input
if [[ -z "$input" ]]; then
    echo "Error: Input PDF is required."
    usage
fi

# Remove path and extension to get filename
filename=$(basename -- "$input")
filename="${filename%.*}"

# Set default output file if not provided
if [[ -z "$output" ]]; then
    output="${filename}-booklet.pdf"
fi

# Auto-detect total pages if not provided
if [[ -z "$totalpages" ]]; then
    if command -v pdfinfo >/dev/null 2>&1; then
        totalpages=$(pdfinfo "$input" | awk '/Pages:/ {print $2}')
        echo "ℹ️  Auto-detected total pages: $totalpages"
    else
        echo "⚠️  Warning: 'pdfinfo' not found. Install poppler-utils or provide -p <totalpages>."
        usage
    fi
fi

# Auto-detect page size if not manually set
if [[ -z "$pagesize" ]]; then
    if command -v pdfinfo >/dev/null 2>&1; then
        page_sizes=$(pdfinfo "$input" | awk '/Page size:/ {print $3, $5}' | sort -u)
        num_sizes=$(echo "$page_sizes" | wc -l)

        if [[ $num_sizes -gt 1 ]]; then
            echo "⚠️  Warning: Multiple page sizes detected in PDF. Booklet results may not be optimal."
        fi

        if echo "$page_sizes" | awk '{if ($1 >= 594 && $1 <= 596 && $2 >= 840 && $2 <= 842) print "A4"}' | grep -q "A4"; then
            pagesize="A4"
        elif echo "$page_sizes" | awk '{if ($1 >= 418 && $1 <= 421 && $2 >= 594 && $2 <= 596) print "A5"}' | grep -q "A5"; then
            pagesize="A5"
        else
            echo "⚠️  Warning: Unknown page size detected. Defaulting to A4."
            pagesize="A4"
        fi
        echo "ℹ️  Auto-detected source page size: $pagesize"
    else
        echo "⚠️  Warning: 'pdfinfo' not found. Unable to auto-detect page size. Defaulting to A4."
        pagesize="A4"
    fi
fi

# Auto-calculate best signature (must be a multiple of 4 and between 20-28)
best_signature=20
min_white_pages=1000  # Large initial value for min white pages
for sig in 20 24 28; do
    remainder=$((totalpages % sig))
    white_pages=$(( (remainder == 0) ? 0 : (sig - remainder) ))
    if [[ $white_pages -lt $min_white_pages ]]; then
        min_white_pages=$white_pages
        best_signature=$sig
    fi
done
signature=$best_signature
echo "ℹ️  Auto-selected signature size: $signature to minimize white pages ($min_white_pages blank pages)."

# Apply preset settings based on source page size
if [[ "$pagesize" == "A5" ]]; then
    doc_class="\\documentclass[a4paper,landscape]{article}"
    landscape_flag=""  # A5 doesn't need the landscape option in \includepdf
else
    doc_class="\\documentclass[a4paper,portrait]{article}"
    landscape_flag=",landscape"  # A4 requires the landscape option in \includepdf
fi

# Generate LaTeX file
cat > "$temp_tex" <<EOF
$doc_class
\\usepackage{pdfpages}
\\begin{document}

\\includepdf[pages=-,delta=$delta,fitpaper=false,trim=$trim,noautoscale=false,signature=$signature,rotateoversize=false$landscape_flag,$clip_option]{${input}}

\\end{document}
EOF

# Compile with pdflatex
pdflatex -interaction=nonstopmode "$temp_tex" > /dev/null 2>&1

# Rename and clean up
mv temp_booklet.pdf "$output"
rm -f temp_booklet.aux temp_booklet.log temp_booklet.tex

echo "✅ Booklet created: $output"
