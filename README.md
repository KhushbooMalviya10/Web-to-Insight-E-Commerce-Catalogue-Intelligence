# Web-to-Insight-E-Commerce-Catalogue-Intelligence
E-Commerce Product Analysis

Project Overview

This end-to-end data analysis project examines an e-commerce product catalogue collected through web scraping. The project demonstrates the complete analytics workflow: extracting product data from web pages, cleaning and transforming it with Python, storing and querying it in SQL Server, and presenting business insights through an interactive Power BI report.

The final dataset contains 500 products, 15 product categories, and 20 vendors. The analysis focuses on product assortment, pricing, discounts, stock availability, customer ratings, reviews, categories, and vendor contribution.

Business Objective

The objective is to transform unstructured product information from a website into a clean analytical dataset and answer the following business questions:

How many products, categories, and vendors are present in the catalogue?

Which categories contain the most products?

Which vendors contribute the largest number of products?

What proportion of the product catalogue is currently in stock?

How are products distributed across different price categories?

How many products are discounted?

What is the average discount offered on discounted products?

Which product categories have the highest average prices?

Which categories offer the highest average discounts?

Is there a visible relationship between product price and customer rating?

Tools and Technologies

Stage

Tools used

Web scraping

Python, Requests, BeautifulSoup, JSON

Data cleaning and transformation

Python, Pandas, NumPy

Data storage and analysis

Microsoft SQL Server, SQL Server Management Studio

Data modelling and reporting

Power BI, Power Query, DAX

Development environment

Jupyter Notebook

Project Workflow

Website
   ↓
Python Web Scraping
   ↓
Raw Product Dataset
   ↓
Pandas and NumPy Cleaning
   ↓
Cleaned CSV Dataset
   ↓
SQL Server Analysis
   ↓
Power BI Data Model
   ↓
Interactive Two-Page Report

Dataset Description

The raw dataset contains 500 rows and the following 15 fields:

Column

Description

product_id

Unique identifier for each product

product_name

Product title

vendor

Product vendor or brand

category

Product category

price

Current selling price

original_price

Price before discount; may be missing for non-discounted products

rating

Customer rating

review_count

Number of customer reviews

in_stock

Boolean stock indicator

sku

Stock-keeping unit

tags

Product-related tags

description

Product description

created_at

Product creation date and time

image_url

Product image address

product_url

Source webpage for the product

After cleaning and feature engineering, additional analytical columns were created:

Derived column

Description

stock_status

Converts the stock flag into In Stock or Out of Stock

is_discounted

Identifies whether a valid discount exists

discount_amount

Difference between original price and selling price

discount_percentage

Discount amount as a percentage of original price

created_date

Date extracted from the original timestamp

created_year

Year of product creation

created_month

Numeric month of product creation

created_month_name

Month name used for reporting

price_category

Segments products into Budget, Affordable, Premium, and Luxury

rating_category

Groups products into meaningful rating bands

1. Web Scraping

The product pages were requested individually. Each page returned product information as JSON inside a <pre> HTML element. The scraper checked the HTTP response and the required element before parsing, which prevented failures when a page was unavailable or its content was missing.

Required libraries

# Import the libraries required for web scraping and data handling
import json
import time
import requests
import pandas as pd
from bs4 import BeautifulSoup

Scraping logic

# Store all successfully scraped products in this list
products = []

# Use a session to reuse the connection across requests
session = requests.Session()

# Identify the request as coming from a regular browser
headers = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 Chrome/136.0 Safari/537.36"
    )
}

# Scrape product IDs from 1 through 500
for product_id in range(1, 501):
    product_url = f"https://scrapingsandbox.com/products/{product_id}"

    try:
        # Download the current product page
        response = session.get(
            product_url,
            headers=headers,
            timeout=20
        )

        # Raise an error if the request was unsuccessful
        response.raise_for_status()

        # Parse the page HTML
        soup = BeautifulSoup(response.text, "html.parser")
        json_section = soup.find("pre")

        # Skip the page safely if product JSON is unavailable
        if json_section is None:
            print(f"No product data found for product {product_id}")
            continue

        # Convert the JSON text into a Python dictionary
        product = json.loads(json_section.get_text(strip=True))

        # Add the source URL and save the product
        product["product_url"] = product_url
        products.append(product)

    except (requests.RequestException, json.JSONDecodeError) as error:
        # Record the error without stopping the complete scraping process
        print(f"Product {product_id} could not be scraped: {error}")

    # Add a small delay to avoid sending requests too quickly
    time.sleep(0.2)

# Convert the collected product dictionaries into a DataFrame
df = pd.DataFrame(products)

# Display the resulting dataset dimensions
print(f"Rows: {df.shape[0]}, Columns: {df.shape[1]}")

The scraper should be used only on websites that permit automated access. Request frequency should be kept reasonable and the website's terms and robots policy should be reviewed before scraping.

2. Initial Data Assessment

The following checks were performed before cleaning:

# Display sample rows to understand the dataset structure
display(df.head())

# Review column names, non-null counts, and data types
df.info()

# Count missing values in every column
print(df.isnull().sum())

# Count completely duplicated rows
print("Duplicate rows:", df.duplicated().sum())

# Review numerical distributions and possible unusual values
display(df.describe())

# Examine important categorical fields
print(df["category"].value_counts())
print(df["vendor"].value_counts())
print(df["in_stock"].value_counts(dropna=False))

Initial observations

The scraped dataset contained 500 records.

No completely duplicated rows were found.

original_price contained missing values because many products were not discounted.

Price and rating columns were numeric.

The in_stock column was Boolean.

Missing original prices were treated as valid business information rather than automatically replaced with zero.

3. Data Cleaning and Feature Engineering

# Import NumPy before using np.where
import numpy as np

# Work on a copy to preserve the original scraped DataFrame
clean_df = df.copy()

# Standardize column names
clean_df.columns = (
    clean_df.columns
    .str.strip()
    .str.lower()
    .str.replace(" ", "_", regex=False)
)

# Remove duplicated records and reset the index
clean_df = clean_df.drop_duplicates().reset_index(drop=True)

# Convert analytical columns to numeric values
numeric_columns = ["price", "original_price", "rating", "review_count"]
for column in numeric_columns:
    clean_df[column] = pd.to_numeric(clean_df[column], errors="coerce")

# Standardize text fields by removing surrounding spaces
text_columns = ["product_name", "vendor", "category", "sku"]
for column in text_columns:
    clean_df[column] = clean_df[column].astype("string").str.strip()

# Convert the stock field into a clean Boolean field
clean_df["in_stock"] = clean_df["in_stock"].fillna(False).astype(bool)

# Create a readable stock-status field
clean_df["stock_status"] = np.where(
    clean_df["in_stock"],
    "In Stock",
    "Out of Stock"
)

# A product is discounted only when its original price is valid
# and greater than its current selling price
clean_df["is_discounted"] = (
    clean_df["original_price"].notna()
    & (clean_df["original_price"] > clean_df["price"])
)

# Calculate the absolute discount amount
clean_df["discount_amount"] = np.where(
    clean_df["is_discounted"],
    clean_df["original_price"] - clean_df["price"],
    0
).round(2)

# Calculate the discount as a whole-number percentage
clean_df["discount_percentage"] = np.where(
    clean_df["is_discounted"],
    (
        (clean_df["original_price"] - clean_df["price"])
        / clean_df["original_price"]
    ) * 100,
    0
).round(2)

# Convert the timestamp into a valid datetime value
clean_df["created_at"] = pd.to_datetime(
    clean_df["created_at"],
    errors="coerce"
)

# Create reporting-friendly date columns
clean_df["created_date"] = clean_df["created_at"].dt.date
clean_df["created_year"] = clean_df["created_at"].dt.year
clean_df["created_month"] = clean_df["created_at"].dt.month
clean_df["created_month_name"] = clean_df["created_at"].dt.month_name()

# Create business-friendly price segments
clean_df["price_category"] = pd.cut(
    clean_df["price"],
    bins=[-np.inf, 50, 100, 150, np.inf],
    labels=["Budget", "Affordable", "Premium", "Luxury"],
    right=False
)

# Create rating segments for analysis
clean_df["rating_category"] = pd.cut(
    clean_df["rating"],
    bins=[-np.inf, 3.5, 4.5, np.inf],
    labels=["Good", "Very Good", "Excellent"],
    right=False
)

Final validation

# Confirm the cleaned dataset structure
clean_df.info()

# Check that each product has a unique identifier
assert clean_df["product_id"].is_unique

# Check for invalid negative prices and review counts
assert (clean_df["price"] >= 0).all()
assert (clean_df["review_count"] >= 0).all()

# Ensure ratings remain within the expected range
assert clean_df["rating"].between(0, 5).all()

# Review the newly created analytical fields
display(
    clean_df[[
        "price",
        "original_price",
        "is_discounted",
        "discount_amount",
        "discount_percentage"
    ]].head(10)
)

4. Exporting the Datasets

Three datasets can be retained to make the workflow traceable:

# Save the original scraped dataset
df.to_csv("products_raw.csv", index=False)

# Save the fully cleaned dataset
clean_df.to_csv("products_cleaned.csv", index=False)

# Remove long text and URL fields for the SQL reporting table
sql_df = clean_df.drop(
    columns=["description", "image_url", "product_url"],
    errors="ignore"
)

# Save the SQL-ready dataset
sql_df.to_csv("products_sql.csv", index=False)

5. SQL Server Analysis

The SQL-ready CSV file was imported manually into Microsoft SQL Server as dbo.products.

Data-quality validation

-- Confirm that all 500 product records were imported
SELECT COUNT(*) AS total_products
FROM dbo.products;

-- Check whether any product IDs occur more than once
SELECT product_id, COUNT(*) AS duplicate_count
FROM dbo.products
GROUP BY product_id
HAVING COUNT(*) > 1;

-- Review missing values in important analytical columns
SELECT
    SUM(CASE WHEN product_name IS NULL THEN 1 ELSE 0 END) AS missing_product_names,
    SUM(CASE WHEN category IS NULL THEN 1 ELSE 0 END) AS missing_categories,
    SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END) AS missing_prices,
    SUM(CASE WHEN rating IS NULL THEN 1 ELSE 0 END) AS missing_ratings
FROM dbo.products;

Core business queries

-- 1. Calculate overall product catalogue KPIs
SELECT
    COUNT(*) AS total_products,
    COUNT(DISTINCT category) AS total_categories,
    COUNT(DISTINCT vendor) AS total_vendors,
    ROUND(AVG(price), 2) AS average_price,
    ROUND(AVG(rating), 2) AS average_rating,
    SUM(review_count) AS total_reviews
FROM dbo.products;

-- 2. Find product count by category
SELECT
    category,
    COUNT(*) AS product_count
FROM dbo.products
GROUP BY category
ORDER BY product_count DESC;

-- 3. Identify the five vendors with the largest product assortment
SELECT TOP 5
    vendor,
    COUNT(*) AS product_count
FROM dbo.products
GROUP BY vendor
ORDER BY product_count DESC;

-- 4. Analyse catalogue stock availability
SELECT
    stock_status,
    COUNT(*) AS product_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS product_percentage
FROM dbo.products
GROUP BY stock_status
ORDER BY product_count DESC;

-- 5. Analyse product distribution by price category
SELECT
    price_category,
    COUNT(*) AS product_count
FROM dbo.products
GROUP BY price_category
ORDER BY
    CASE price_category
        WHEN 'Budget' THEN 1
        WHEN 'Affordable' THEN 2
        WHEN 'Premium' THEN 3
        WHEN 'Luxury' THEN 4
    END;

-- 6. Calculate discounted-product KPIs
SELECT
    SUM(CASE WHEN is_discounted = 1 THEN 1 ELSE 0 END) AS discounted_products,
    ROUND(
        100.0 * SUM(CASE WHEN is_discounted = 1 THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS discounted_product_percentage,
    ROUND(
        AVG(CASE WHEN is_discounted = 1 THEN discount_percentage END),
        2
    ) AS average_discount_percentage
FROM dbo.products;

-- 7. Find average price by category
SELECT
    category,
    ROUND(AVG(price), 2) AS average_price
FROM dbo.products
GROUP BY category
ORDER BY average_price DESC;

-- 8. Find categories offering the highest average discounts
SELECT
    category,
    ROUND(AVG(discount_percentage), 2) AS average_discount_percentage
FROM dbo.products
WHERE is_discounted = 1
GROUP BY category
ORDER BY average_discount_percentage DESC;

-- 9. Compare discount status within each price category
SELECT
    price_category,
    SUM(CASE WHEN is_discounted = 1 THEN 1 ELSE 0 END) AS discounted_products,
    SUM(CASE WHEN is_discounted = 0 THEN 1 ELSE 0 END) AS non_discounted_products,
    ROUND(
        100.0 * SUM(CASE WHEN is_discounted = 1 THEN 1 ELSE 0 END)
        / COUNT(*),
        2
    ) AS discounted_percentage
FROM dbo.products
GROUP BY price_category
ORDER BY
    CASE price_category
        WHEN 'Budget' THEN 1
        WHEN 'Affordable' THEN 2
        WHEN 'Premium' THEN 3
        WHEN 'Luxury' THEN 4
    END;

-- 10. Identify highly rated and highly reviewed products
SELECT TOP 10
    product_name,
    vendor,
    category,
    price,
    rating,
    review_count
FROM dbo.products
ORDER BY rating DESC, review_count DESC;

6. Power BI Data Preparation

Power BI was connected to the SQL Server products table. Long descriptive fields and URLs were excluded from the reporting model because they were not required by the visuals.

Main DAX measures

// Counts every product in the current filter context
Total Products =
COUNTROWS(Products)

// Counts unique product categories
Total Categories =
DISTINCTCOUNT(Products[category])

// Counts unique vendors
Total Vendors =
DISTINCTCOUNT(Products[vendor])

// Calculates the average current selling price
Average Price =
AVERAGE(Products[price])

// Calculates the average customer rating
Average Rating =
AVERAGE(Products[rating])

// Calculates the total number of customer reviews
Total Reviews =
SUM(Products[review_count])

// Counts products that are currently available
In-Stock Products =
CALCULATE(
    [Total Products],
    Products[stock_status] = "In Stock"
)

// Calculates the proportion of products currently in stock
Stock Availability % =
DIVIDE(
    [In-Stock Products],
    [Total Products],
    0
)

// Counts products with a valid discount
Discounted Products =
CALCULATE(
    [Total Products],
    Products[is_discounted] = TRUE()
)

// Calculates the proportion of discounted products
Discounted Products % =
DIVIDE(
    [Discounted Products],
    [Total Products],
    0
)

// Calculates average discount for discounted products only
// Division by 100 converts values such as 30.63 into 0.3063
// so the measure can be formatted as a Power BI percentage
Average Discount % =
DIVIDE(
    CALCULATE(
        AVERAGE(Products[discount_percentage]),
        Products[is_discounted] = TRUE()
    ),
    100
)

Supporting calculated columns

// Creates readable labels for discounted and non-discounted products
Discount Status =
IF(
    Products[is_discounted] = TRUE(),
    "Discounted",
    "Not Discounted"
)

// Creates the numeric order used to sort price-category labels
Price Category Sort =
SWITCH(
    TRUE(),
    Products[price] < 50, 1,
    Products[price] < 100, 2,
    Products[price] < 150, 3,
    4
)

The price_category column was sorted by Price Category Sort to display the correct logical order:

Budget → Affordable → Premium → Luxury

7. Power BI Report Design

The final report contains two pages with a consistent dark theme, light-blue primary visuals, white text, aligned containers, and a page navigator.

Page 1: Product Overview

Purpose: Provide a high-level executive view of the entire product catalogue.

KPI cards

Total Products

Total Categories

Total Vendors

Average Price

Stock Availability %

Visuals

Product Count by Category — clustered bar chart

Products by Stock Status — doughnut chart

Top 5 Vendors by Product Count — treemap

Product Distribution by Price Category — column chart

Discount Status by Price Category — 100% stacked column chart

Page 2: Pricing & Discount Analysis

Purpose: Examine product prices, discounting behaviour, ratings, and category-level differences.

KPI cards

Average Discount %

Discounted Products

Average Rating

Total Reviews

Discounted Products %

Visuals

Average Price by Category — clustered bar chart

Average Discount % by Category — column chart filtered to the top categories

Price vs Customer Rating — scatter chart with bubble size based on review count

Interactive slicers

Category

Price Category

Discount Status

Navigation

A Power BI page navigator allows users to move between Product Overview and Pricing & Discount Analysis.

8. Dashboard Results

KPI

Result

Total products

500

Total categories

15

Total vendors

20

Average price

$104.10

Stock availability

85.4%

Discounted products

189

Discounted products as a share of catalogue

37.8%

Average discount among discounted products

30.6%

Average product rating

4.03

Total reviews

Approximately 117K

9. Key Business Insights

The catalogue contains 500 products from 20 vendors across 15 categories, showing broad product and supplier coverage.

85.4% of products are in stock, while 14.6% are unavailable, indicating generally strong catalogue availability.

Electronics is the largest category with 44 products, followed by Music with 39 and Food & Beverage with 38.

PageTurner contributes the most products with 35, followed by SoundWave with 33, TasteBud with 32, NovaTech with 31, and AutoParts Pro with 29.

Luxury is the largest price segment with 135 products, followed by Premium with 131, Affordable with 122, and Budget with 112.

189 products, or 37.8% of the catalogue, are discounted. The average discount among these products is 30.6%.

Luxury products have the highest discounted-product share at 45.93%, whereas Affordable products have the lowest at 30.33%.

Home & Garden has the highest average product price at approximately $127, while Electronics has the lowest at approximately $86.

Home & Garden also has the highest average discount at 33.7%, closely followed by Jewellery at 33.4%.

Customer ratings occur across all four price segments, so the scatter plot does not show a clear relationship between a higher price and a higher rating.

10. Business Recommendations

Investigate the out-of-stock products within high-volume categories and prioritise replenishment where customer demand or review volume is high.

Review why Electronics has the largest assortment but the lowest average price, and evaluate whether profitable premium-product opportunities exist within that category.

Assess the performance of Luxury discounting because this segment has the highest proportion of discounted products.

Avoid assuming that a higher price produces a better customer rating; use product-level reviews and feedback when making assortment decisions.

Monitor vendor concentration and product performance together instead of evaluating suppliers only by catalogue size.

Compare discount levels with ratings and review counts before expanding promotions, since a large discount alone does not guarantee stronger customer engagement.

11. Suggested Repository Structure

E-Commerce-Product-Analysis/
│
├── data/
│   ├── products_raw.csv
│   ├── products_cleaned.csv
│   └── products_sql.csv
│
├── notebooks/
│   └── e_commerce_web_scraping_and_cleaning.ipynb
│
├── sql/
│   └── product_analysis_queries.sql
│
├── powerbi/
│   └── E-Commerce_Product_Analysis.pbix
│
├── images/
│   ├── product_overview.png
│   └── pricing_discount_analysis.png
│
└── README.md

12. How to Run the Project

Python

Install Python 3 and Jupyter Notebook.

Install the required packages:

pip install pandas numpy requests beautifulsoup4

Open the scraping and cleaning notebook.

Run the cells in order.

Confirm that products_raw.csv, products_cleaned.csv, and products_sql.csv are generated.

SQL Server

Create a SQL Server database for the project.

Import products_sql.csv into a table named dbo.products.

Verify the column data types and product count.

Run the SQL analysis queries.

Power BI

Open Power BI Desktop.

Connect to the SQL Server database.

Load the products table.

Create the documented DAX measures and calculated columns.

Build the two report pages or open the provided .pbix file.

Test all slicers, visual interactions, and page navigation.

13. Data Quality and Analytical Limitations

The project uses a web-scraping sandbox rather than live commercial transaction data.

Product count represents catalogue assortment, not units sold.

Review count is an engagement indicator and should not be interpreted as sales volume.

Missing original_price values generally represent non-discounted products and were preserved rather than replaced with zero.

The analysis reflects a snapshot taken when the website was scraped; product prices and availability can change over time.

The scatter chart shows association visually but does not establish causation between price and rating.

Because the data is synthetic or demonstration-oriented, business recommendations illustrate analytical reasoning rather than operational advice for a real company.

14. Skills Demonstrated

Web scraping and HTML parsing

JSON extraction and exception handling

Data profiling and validation

Missing-value and duplicate analysis

Data-type conversion and text standardisation

Feature engineering with Pandas and NumPy

CSV preparation and SQL Server import

SQL aggregation, conditional analysis, grouping, ranking, and window calculations

DAX measure development

Power BI visual design and report navigation

Business-question formulation and insight communication
