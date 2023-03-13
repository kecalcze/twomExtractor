# TWoM Extractor

set of tools we use to extract data from provided source `.docx` files

## Porocess:

To extract data from docx we used this process:

- via libre office copy whole table from Writer -> Sheet
- save sheets as `*.ods` -> copy them to `files` folder
- use this `main.php` script to convert them to `*.csv`
- use @Conanien's script `jsonConstructor_[cs|en].ps1` to parse the csv -> json
- import json to app and do handmade adjustments

## Thanks to:

Conanien for extractor/parser

Pyromantic for help and ideas
