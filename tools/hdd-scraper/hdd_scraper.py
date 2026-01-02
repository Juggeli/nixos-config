#!/usr/bin/env python3
import re
import sys
from urllib.parse import urljoin

import requests
from bs4 import BeautifulSoup
from tabulate import tabulate


URL = "https://tietokonekauppa.fi/products/t/2017/3_5_SATA_III_HDD_Kunnostetut?sortby=aprice"


def fetch_html():
    try:
        headers = {
            "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        }
        response = requests.get(URL, headers=headers, timeout=30)
        response.raise_for_status()
        return response.text
    except requests.RequestException as e:
        print(f"Error fetching page: {e}", file=sys.stderr)
        sys.exit(1)


def parse_price(price_str):
    price_str = price_str.strip().replace("€", "").replace(" ", "").replace(",", ".")
    try:
        return float(price_str)
    except ValueError:
        return None


def extract_capacity(title):
    match = re.search(r"(\d+(?:\.\d+)?)\s*TB", title, re.IGNORECASE)
    if match:
        return float(match.group(1))

    match = re.search(r"(\d+)\s*GB", title, re.IGNORECASE)
    if match:
        return float(match.group(1)) / 1000

    return None


def extract_make(title, product_code):
    makes = [
        "Seagate",
        "Western Digital",
        "WD",
        "Toshiba",
        "Hewlett Packard Enterprise",
        "HPE",
        "HP",
    ]

    title_lower = title.lower()
    for make in makes:
        if make.lower() in title_lower:
            return make

    code_lower = product_code.lower()
    if "st" in code_lower:
        return "Seagate"
    if "wd" in code_lower:
        return "Western Digital"
    if "md" in code_lower or "mg" in code_lower:
        return "Toshiba"
    if "611" in code_lower or "ge262" in code_lower:
        return "HP"

    return "Unknown"


def clean_model(title, make):
    model = title.replace(make, "").strip()
    model = re.sub(r"\s+", " ", model)
    model = model.split(",")[0]
    model = re.sub(r"FACTORY REFURBISHED", "", model, flags=re.IGNORECASE)
    model = re.sub(r"Tehdaskunnostettu\.?", "", model, flags=re.IGNORECASE)
    model = re.sub(r"Recertified", "", model, flags=re.IGNORECASE)
    model = re.sub(r"\s+-\s+", " ", model)
    model = re.sub(r"\s+-", "", model)
    model = re.sub(r"-\s+$", "", model)
    model = re.sub(r"\s+", " ", model)
    return model.strip()[:100]


def parse_products(html):
    soup = BeautifulSoup(html, "lxml")
    products = []

    product_cards = soup.find_all("div", class_="product_card")

    for card in product_cards:
        title_elem = card.find("h3", class_="title")
        price_elem = card.find("div", class_="normal_price")
        code_elem = card.find("span", class_="type-manu")

        if not title_elem or not price_elem:
            continue

        title = title_elem.text.strip()
        price_str = price_elem.text.strip()
        product_code = code_elem.text.strip() if code_elem else ""

        price = parse_price(price_str)
        capacity_tb = extract_capacity(title)

        if not price or not capacity_tb or capacity_tb == 0 or capacity_tb < 8:
            continue

        make = extract_make(title, product_code)
        model = clean_model(title, make)
        price_per_tb = price / capacity_tb

        products.append(
            {
                "make": make,
                "model": model,
                "capacity_tb": capacity_tb,
                "price": price,
                "price_per_tb": price_per_tb,
            }
        )

    return products


def main():
    html = fetch_html()
    products = parse_products(html)

    if not products:
        print("No products found or unable to parse page", file=sys.stderr)
        sys.exit(1)

    products_sorted = sorted(products, key=lambda x: x["price_per_tb"])

    table_data = [
        [
            p["make"],
            p["model"],
            f"{p['capacity_tb']:.2f}",
            f"€{p['price']:.2f}",
            f"€{p['price_per_tb']:.2f}",
        ]
        for p in products_sorted
    ]

    headers = ["Make", "Model", "Capacity (TB)", "Price", "Price/TB"]

    print(tabulate(table_data, headers=headers, tablefmt="grid"))


if __name__ == "__main__":
    main()
