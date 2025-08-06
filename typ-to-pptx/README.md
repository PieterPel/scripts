# typ-to-pptx

This repository contains a script to convert Typst files or PDFs to PowerPoint presentations. 
The script is wrapped as a Nix flake, so you dont have to worry about dependencies.
By default shows two pages per slide.

## How to use

1.  **Install Nix.**
2.  **Run the script:**
    ```bash
    nix run github:PieterPel/scripts?dir=typ-to-pptx -- <input.typ|input.pdf>
    ```

    This will create a `.pptx` file in the same directory as the input file.

## Under the hood

The script uses the following tools:

*   [Typst](https://typst.app/) to compile `.typ` files to `.pdf`.
*   [pdf2pptx](https://github.com/shafaei/pdf2pptx) to convert `.pdf` files to `.pptx`.
*   [ImageMagick](https://imagemagick.org/) to convert PDF pages to images.
*   [Nix](https://nixos.org/) to provide a reproducible environment.
