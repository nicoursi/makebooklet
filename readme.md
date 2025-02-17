# PDF Booklet Generator Script

This script converts a PDF into a booklet format by arranging pages side by side, ready to be printed and folded. It can handle A4 and A5 source pages and offers options to configure signature size, margins, and more.

## Prerequisites

- **pdflatex**: LaTeX compiler to generate the booklet PDF.
- **pdfinfo**: Tool to extract page information from the source PDF (for auto-detecting total pages and page size). Install it by running:

```
sudo apt-get install poppler-utils
```

## Usage

```
./generate_booklet.sh -i <input.pdf> [-a4 | -a5] [-s <signature>] [-p <totalpages>] [-t <'L T R B'>] [-d <'X Y'>] [-o <output.pdf>]
```


### Options

- `-i <input.pdf>`
  (Required) The input PDF file you want to convert into a booklet.

- `-a4`
  Force the source pages to be treated as A4 size. This is the default if no page size is detected or specified.

- `-a5`
  Force the source pages to be treated as A5 size. This works correctly when pages are arranged on A4 paper in a booklet layout.

- `-s <signature>`
  Set the signature size (the number of pages per fold). Default is `20`. Valid values are multiples of 4 (e.g., 20, 24, 28).

- `-p <totalpages>`
  Total number of pages in the input PDF. If not specified, the script will auto-detect the total pages.

- `-t <'L T R B'>`
  Set trim margins for each page (Left Top Right Bottom). For example, `'1cm 1cm 1cm 1cm'`. Default is `'0cm 0cm 0cm 0cm'`.

- `-d <'X Y'>`
  Set delta adjustments (horizontal and vertical). Default is `'0cm 0cm'`.

- `-o <output.pdf>`
  Specify the output PDF file name. If not specified, it will default to `<input>-booklet.pdf`.

- `-h`
  Show this help message.

## Example

Convert an A4-sized PDF to a booklet with a signature of 20 pages and custom margins:

```bash
./generate_booklet.sh -i input.pdf -s 20 -t "1cm 1cm 1cm 1cm"
```
Convert an A5-sized PDF to a booklet:
```
./generate_booklet.sh -i input.pdf -a5
```

## How it Works

- **Page Size Detection**: If no page size is provided, the script will try to auto-detect the page size using `pdfinfo`. If multiple sizes are found, it will default to A4.

- **Signature Size**: The script automatically selects the best signature size to minimize white pages. Valid signature sizes are multiples of 4 (e.g., 20, 24, 28). The default is `20`.

- **Booklet Layout**: The script uses `pdfpages` in LaTeX to arrange pages in a booklet format, including trimming and delta adjustments. If A5 is detected, it ensures the booklet pages are printed on A4 paper without rotating them sideways.

- **Output**: The script generates a PDF file where pages are arranged correctly for printing and folding into a booklet.

## Troubleshooting

- **Missing Dependencies**: Ensure you have both `pdflatex` and `pdfinfo` installed.

- **Invalid Signature**: If the script fails to detect a suitable signature size, you can manually specify one using the `-s` option.

## License

This script is provided under the MIT License. See `LICENSE` for details.
