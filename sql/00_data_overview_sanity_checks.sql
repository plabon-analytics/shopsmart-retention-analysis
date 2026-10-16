-- ============================================================
-- SECTION 0: DATA OVERVIEW & SANITY CHECKS
-- ShopSmart Retention Analysis | Plabon Roy
-- ============================================================
-- Purpose:
--   This is the SQL equivalent of the EDA phase in a Python/ML
--   project. Before trusting any Section 1-7 result, confirm
--   the shape of the data: how many rows exist per table, what
--   date range we're working with, whether statuses behave as
--   expected, and whether any customers/orders look broken.
--
--   If a later section (e.g. Rolling Average) shows something
--   unexpected, this section is the first place to check --
--   rule out "bad/incomplete data" before theorizing about
--   business causes.
-- ============================================================

-- ------------------------------------------------------------
-- 0.1 Row counts per table
-- ------------------------------------------------------------
-- Confirms scale matches expectation (50 customers, 30 products,
-- 115 orders) and that no table is unexpectedly empty.
-- ------------------------------------------------------------
SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL
SELECT 'returns', COUNT(*) FROM returns
UNION ALL
SELECT 'marketing_campaigns', COUNT(*) FROM marketing_campaigns;


-- ------------------------------------------------------------
-- 0.2 Date range of orders
-- ------------------------------------------------------------
-- Confirms the actual span of order_date (expected: 2022-2026).
-- Every time-based analysis (Rolling Avg, MoM/YoY, Cohort,
-- Retention) depends on this range being what you think it is.
-- ------------------------------------------------------------
SELECT
    MIN(order_date) AS earliest_order,
    MAX(order_date) AS latest_order,
    TIMESTAMPDIFF(MONTH, MIN(order_date), MAX(order_date)) AS span_months
FROM orders;


-- ------------------------------------------------------------
-- 0.3 Order status distribution
-- ------------------------------------------------------------
-- Every downstream query filters on status (Delivered /
-- Cancelled / Returned). Confirm there are no unexpected status
-- values (typos, NULLs, extra statuses) before relying on those
-- filters everywhere else.
-- ------------------------------------------------------------
SELECT
    status,
    COUNT(*) AS order_count,
    ROUND(COUNT(*) / (SELECT COUNT(*) FROM orders) * 100, 2) AS pct_of_total
FROM orders
GROUP BY status
ORDER BY order_count DESC;


-- ------------------------------------------------------------
-- 0.4 Customers with zero orders
-- ------------------------------------------------------------
-- RFM, CLV, Cohort, and Retention all INNER JOIN customers to
-- orders -- meaning customers with zero orders are silently
-- excluded from those analyses. Confirm how many customers this
-- affects, so the exclusion is a documented decision, not a
-- surprise a reviewer finds later.
-- ------------------------------------------------------------
SELECT
    COUNT(*) AS customers_with_zero_orders
FROM customers AS c
LEFT JOIN orders AS o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;


-- ------------------------------------------------------------
-- 0.5 Orders with zero order_items (orphaned orders)
-- ------------------------------------------------------------
-- An order with no line items would produce NULL/zero revenue
-- in every revenue-based analysis and silently distort totals.
-- Should return 0 rows on a clean database -- if not, decide
-- how to handle before Section 1.
-- ------------------------------------------------------------
SELECT
    o.order_id,
    o.customer_id,
    o.status,
    o.order_date
FROM orders AS o
LEFT JOIN order_items AS oi ON o.order_id = oi.order_id
WHERE oi.item_id IS NULL;


-- ------------------------------------------------------------
-- 0.6 order_items referencing a non-existent product
-- ------------------------------------------------------------
-- Confirms referential integrity between order_items and
-- products. Should return 0 rows -- if not, Market Basket and
-- revenue queries could silently drop or misattribute rows.
-- ------------------------------------------------------------
SELECT
    oi.item_id,
    oi.order_id,
    oi.product_id
FROM order_items AS oi
LEFT JOIN products AS p ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;


-- ------------------------------------------------------------
-- 0.7 Negative or zero values in price/quantity
-- ------------------------------------------------------------
-- Any negative or zero unit_price/quantity would corrupt every
-- revenue calculation downstream (CLV, RFM Monetary, Rolling
-- Avg, MoM/YoY). Should return 0 rows.
-- ------------------------------------------------------------
SELECT *
FROM order_items
WHERE unit_price <= 0 OR quantity <= 0;
