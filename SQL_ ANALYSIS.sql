USE  Product_Analysis;


SELECT * FROM products;

-- Checking the first 10 imported records
SELECT TOP 10 *
FROM products;
GO


-- Confirming  that all 500 products were imported
SELECT COUNT(*) AS TotalProducts
FROM products;


-- Check whether any product_id appears more than once
SELECT
    product_id,
    COUNT(*) AS DuplicateCount
FROM products
GROUP BY product_id
HAVING COUNT(*) > 1;


-- Check whether any SKU appears more than once
SELECT
    sku,
    COUNT(*) AS DuplicateCount
FROM products
GROUP BY sku
HAVING COUNT(*) > 1;


-- Count missing values in important columns
SELECT
    SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END)
        AS MissingProductIDs,

    SUM(CASE WHEN product_name IS NULL THEN 1 ELSE 0 END)
        AS MissingProductNames,

    SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END)
        AS MissingPrices,

    SUM(CASE WHEN rating IS NULL THEN 1 ELSE 0 END)
        AS MissingRatings,

    SUM(CASE WHEN original_price IS NULL THEN 1 ELSE 0 END)
        AS MissingOriginalPrices
FROM products;



-- Check for invalid price, rating, review and discount values
SELECT
    SUM(CASE WHEN price <= 0 THEN 1 ELSE 0 END)
    AS InvalidPrices,

    SUM(CASE WHEN rating NOT BETWEEN 1 AND 5 THEN 1 ELSE 0 END)
    AS InvalidRatings,

    SUM(CASE WHEN review_count < 0 THEN 1 ELSE 0 END)
        AS InvalidReviewCounts,

    SUM(CASE WHEN discount_percentage < 0 THEN 1 ELSE 0 END)
   AS InvalidDiscounts
FROM products;


--Product Analysis 

--- Question 1 - Find the total number of products, categories and vendors.

SELECT
  COUNT(*) AS TotalProducts,
    COUNT(DISTINCT category) AS TotalCategories,
    COUNT(DISTINCT vendor) AS TotalVendors
FROM dbo.products;


---Question 2
--Calculate the average product price, average product rating and total number of reviews.

SELECT
    ROUND(AVG(price), 2) AS AverageProductPrice,
    ROUND(AVG(rating), 2) AS AverageProductRating,
    SUM(review_count) AS TotalReviews
FROM dbo.products;


---Question 3 -  Count the number of in-stock and out-of-stock products.

SELECT
    stock_status,
    COUNT(*) AS ProductCount
FROM dbo.products
GROUP BY stock_status
ORDER BY ProductCount DESC;


---Question 4 - Find the number of products available in each category.

SELECT
    category,
    COUNT(*) AS ProductCount
FROM dbo.products
GROUP BY category
ORDER BY ProductCount DESC;

--- Question 4 - Find the number of products available in each category.

SELECT
    category,
    COUNT(*) AS ProductCount
FROM dbo.products
GROUP BY category
ORDER BY ProductCount DESC;


--Question 5 - Calculate the average price and average rating for each product category.

-- Calculate category-level product count, average price and average rating
SELECT
    category,
    COUNT(*) AS ProductCount,
    ROUND(AVG(price), 2) AS AveragePrice,
    ROUND(AVG(rating), 2) AS AverageRating
FROM dbo.products
GROUP BY category
ORDER BY AveragePrice DESC;


--Question 6 - Find the five most expensive products.

SELECT TOP 5
    product_id,
    product_name,
    vendor,
    category,
    price,
    rating
FROM dbo.products
ORDER BY price DESC;


---Question 7 - Find the five products with the highest discount percentages.

SELECT TOP 5
    product_id,
    product_name,
    vendor,
    category,
    price,
    original_price,
    discount_amount,
    discount_percentage
FROM dbo.products
WHERE is_discounted = 1
ORDER BY discount_percentage DESC;


---Question 8 - Calculate the number of discounted and non-discounted products.

SELECT
    CASE
        WHEN is_discounted = 1 THEN 'Discounted'
        ELSE 'Not Discounted'
    END AS DiscountStatus,

    COUNT(*) AS ProductCount

FROM dbo.products

GROUP BY
    CASE
        WHEN is_discounted = 1 THEN 'Discounted'
        ELSE 'Not Discounted'
    END

ORDER BY ProductCount DESC;

---Question 9 - Calculate the average discount percentage for each product category.

SELECT
    category,
    COUNT(*) AS DiscountedProductCount,
    ROUND(
        AVG(discount_percentage),
        2
    ) AS AverageDiscountPercentage
FROM dbo.products
WHERE is_discounted = 1
GROUP BY category
ORDER BY AverageDiscountPercentage DESC;

--Question 10 - Find all products priced above the overall average product price.

SELECT
    product_id,
    product_name,
    vendor,
    category,
    price,
    rating
FROM dbo.products
WHERE price > (
    SELECT AVG(price)
    FROM dbo.products
)
ORDER BY price DESC;


---Question 11 - Find categories whose average product price is higher than the overall average product price.

SELECT
    category,
    COUNT(*) AS ProductCount,
    ROUND(AVG(price), 2) AS CategoryAveragePrice
FROM dbo.products
GROUP BY category
HAVING AVG(price) > (
    SELECT AVG(price)
    FROM dbo.products)
ORDER BY CategoryAveragePrice DESC;


---Question 12 - Find the ten products with the highest number of customer reviews.

SELECT TOP 10
    product_id,
    product_name,
    vendor,
    category,
    price,
    rating,
    review_count
FROM dbo.products
ORDER BY review_count DESC;
