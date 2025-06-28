#!/bin/bash

help_message() {
    echo "Usage: $0 -i input.pdf [-o output.pdf] [options]"
    echo "\nOptions:"
    echo "  -i, --input <file>        Input PDF file (required)"
    echo "  -o, --output <file>       Output PDF file (default: input filename with '-trimmed.pdf' suffix)"
    echo "  -p, --pages <range>       Pages to include (default: '$pages')"
    echo "  -t, --trim <values>       Trim margins: 'left bottom right top' (default: '$trim')"
    echo "  -f, --fitpaper <true|false>  Scale to fit page (default: $fitpaper)"
    echo "  -n, --noautoscale <true|false>  Disable auto-scaling (default: $noautoscale)"
    echo "  -c, --clip               Clip PDF (default: off)"
    echo "  -r, --rotateoversize <true|false>  Rotate oversized pages (default: $rotateoversize)"
    echo "  -O, --offset <x y>       Offset adjustments (default: '0cm 0cm')"
    echo "  -P, --pagenumbers        Enable page numbers (default: $pagenumbers)"
    echo "  --topmargin <value>      Set top margin for the page numbers (default: '$topmargin')"
    echo "  --oddsidemargin <value>  smaller values move odd pages number to the left (default: '$oddsidemargin')"
    echo "  --evensidemargin <value> smaller values move even pages number to the left (default: '$evensidemargin')"
    echo "  --pagenumtextwidth <value>  Set width of page number text area (default: '$pagenumtextwidth')"
    echo "  -h, --help               Show this help message"
    exit 0
}


# Default values
pages="-"
trim="0cm 0cm 0cm 0cm"
offset="0cm 0cm"
fitpaper=true
noautoscale=false
rotateoversize=false
clip=""
pagenumbers=false
topmargin="-1.715cm"
oddsidemargin="-3.5cm"
evensidemargin="-1.6cm"
pagenumtextwidth="21cm"

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -i|--input)
            input_pdf="$2"
            shift 2;;
        -o|--output)
            output_pdf="$2"
            shift 2;;
        -p|--pages)
            pages="$2"
            shift 2;;
        -t|--trim)
            trim="$2"
            shift 2;;
        -O|--offset)
            offset="$2"
            shift 2;;
        -f|--fitpaper)
            fitpaper="$2"
            shift 2;;
        -n|--noautoscale)
            noautoscale="$2"
            shift 2;;
        -c|--clip)
            clip="clip"
            shift;;
        -r|--rotateoversize)
            rotateoversize="$2"
            shift 2;;
        -P|--pagenumbers)
            pagenumbers=true
            shift;;
        -h|--help)
            help_message;;
        --topmargin)
            topmargin="$2"
            shift 2;;
        --oddsidemargin)
            oddsidemargin="$2"
            shift 2;;
        --evensidemargin)
            evensidemargin="$2"
            shift 2;;
        --pagenumtextwidth)
            pagenumtextwidth="$2"
            shift 2;;
        *)
            echo "Unknown option: $1"; exit 1;;
    esac
done

# Validate input
if [[ -z "$input_pdf" ]]; then
    echo "Error: Input PDF file is required." >&2
    exit 1
fi

if [[ -z "$output_pdf" ]]; then
    output_pdf="${input_pdf%.pdf}-trimmed.pdf"
fi

temp_dir=$(mktemp -d)
temp_tex="$temp_dir/document.tex"
temp_pdf="$temp_dir/document.pdf"
#echo $temp_dir

# Generate LaTeX file
cat > "$temp_tex" <<EOF
\documentclass[a4paper,portrait]{article}
\usepackage{pdfpages}
EOF

if [[ "$pagenumbers" == "true" ]]; then
    cat > "$temp_tex" <<EOF
\documentclass[twoside,a4paper,portrait]{article}
\usepackage{pdfpages}
\usepackage{fancyhdr}
\usepackage{changepage}
\setlength\topmargin{$topmargin}
%\setlength\textheight{2.0in}
\setlength\textwidth{$pagenumtextwidth}
\setlength\oddsidemargin{$oddsidemargin}
\setlength\evensidemargin{$evensidemargin}
\strictpagecheck
\fancypagestyle{mystyle}{%
    \fancyhf{}
    \fancyhead[LE,RO]{\small\thepage}
    \renewcommand{\headrulewidth}{0pt}
}
EOF
pagecommand="pagecommand={\thispagestyle{mystyle}}"
else
    pagecommand=""
fi

cat >> "$temp_tex" <<EOF
\begin{document}
\includepdf[pages=$pages,fitpaper=$fitpaper,noautoscale=$noautoscale,$clip,trim=$trim,offset=$offset,rotateoversize=$rotateoversize,$pagecommand]{$input_pdf}
\end{document}
EOF

# Compile the PDF
#pdflatex -output-directory="$temp_dir" "$temp_tex" >/dev/null 2>&1
pdflatex -output-directory="$temp_dir" "$temp_tex" > "$temp_dir/error.log" 2>&1

# Move output PDF to final destination
if [[ -f "$temp_pdf" ]]; then
    mv "$temp_pdf" "$output_pdf"
    echo "Output saved as: $output_pdf"
else
    echo "Error: PDF generation failed. See the log files located in the folder $temp_dir" >&2
    #mv "$temp_dir/error.log" "${output_pdf%.pdf}-errors.log"
    exit 1
fi

# Cleanup
test -d "$temp_dir" && rm -rf "$temp_dir"
