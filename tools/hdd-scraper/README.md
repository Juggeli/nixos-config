# HDD Price Scraper

Fetches HDD prices from tietokonekauppa.fi's refurbished 3.5" SATA III HDD category and displays them sorted by price per TB.

## Usage

```bash
# Run from development environment
nix develop
python hdd_scraper.py

# Or install via NixOS and run
hdd-scraper
```

## What It Does

- Fetches product list from tietokonekauppa.fi
- Parses product cards for make, model, capacity, and price
- Calculates price per TB
- Displays sorted table (cheapest per TB first)

## Development

Enter development shell:
```bash
cd tools/hdd-scraper
nix develop
```

Run the scraper:
```bash
python hdd_scraper.py
```
