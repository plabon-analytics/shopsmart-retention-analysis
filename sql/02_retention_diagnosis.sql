-- ============================================================
-- SECTION 2: RETENTION DIAGNOSIS (COHORT + RETENTION)
-- ShopSmart Retention Analysis | Plabon Roy
-- ============================================================
-- Business Question:
--   Is customer drop-off a real, measurable problem at ShopSmart --
--   and does it get worse or better for customers who joined more
--   recently vs. customers who joined earlier?
--
-- Grain decision -- YEARLY, not monthly or quarterly:
--   Only 19 of ShopSmart's 50 customers have at least one
--   Delivered order, which is what a cohort needs to anchor on:
--   29 customers never ordered (Section 0.4) and 2 more placed
--   orders but none were Delivered, so none of those 31 can be
--   assigned a cohort. A monthly cohort check showed 17 distinct
--   months, nearly all with exactly 1 customer, which is unusable
--   as a retention curve. Quarterly grouping did not meaningfully
--   improve this. Yearly grain was the smallest grain that
--   produced cohorts large enough to read:
--     2022 cohort = 12 customers
--     2023 cohort =  6 customers
--     2024 cohort =  1 customer  <-- CAVEAT BELOW
--
-- CAVEAT -- 2024 cohort (n=1):
--   Any retention % derived from the 2024 cohort is based on a
--   single customer and should be treated as directional only,
--   never as a statistically meaningful rate. Report it, but
--   flag it explicitly wherever it appears (README + chart
--   annotations), and do not draw comparative conclusions
--   ("2024 retains worse than 2022") from it.
--
-- CAVEAT -- 2026 is a partial year:
--   The data ends on 2026-05-28. The last column of every cohort
--   (2022 cohort Year 4, 2023 cohort Year 3, 2024 cohort Year 2)
--   is calendar 2026, about five months. Retention there is
--   understated by construction and should not be read as a
--   decline. Compare cohorts on full years only.
--
-- Revenue definition:
--   revenue = unit_price * quantity * (1 - discount/100) -- NET
--   revenue, consistent with Section 1 and every section after.
--
-- Statement scoping note:
--   MySQL does not let a WITH clause defined in one statement
--   carry into a second statement. Query 2B (Retention) therefore
--   redefines the same first_purchase / orders_with_cohort /
--   cohort_activity logic used in Query 2A -- this is necessary
--   duplication, not redundant design (see Section 1's header for
--   the same note).
-- ============================================================


-- ------------------------------------------------------------
-- Query 2A: Cohort Activity
-- ------------------------------------------------------------
-- For each cohort (grouped by the YEAR of a customer's first
-- delivered order), tracks how many of that cohort's customers
-- were still active -- and how much net revenue they generated --
-- in each subsequent year, aligned on years_since_first_purchase
-- so cohorts of different starting years can be compared on
-- equal footing (Year 0, Year 1, Year 2...).
-- ------------------------------------------------------------
WITH first_purchase AS (
    SELECT
        customer_id,
        YEAR(MIN(order_date)) AS cohort_year
    FROM orders
    WHERE status = 'Delivered'
    GROUP BY customer_id
),
orders_with_cohort AS (
    SELECT
        o.customer_id,
        fp.cohort_year,
        YEAR(o.order_date) AS order_year,
        oi.unit_price * oi.quantity * (1 - oi.discount / 100) AS revenue
    FROM orders AS o
    INNER JOIN first_purchase AS fp ON o.customer_id = fp.customer_id
    INNER JOIN order_items AS oi ON o.order_id = oi.order_id
    WHERE o.status = 'Delivered'
),
cohort_activity AS (
    SELECT
        cohort_year,
        order_year,
        order_year - cohort_year AS years_since_first_purchase,
        COUNT(DISTINCT customer_id)  AS active_customers,
        ROUND(SUM(revenue), 2)       AS cohort_revenue
    FROM orders_with_cohort
    GROUP BY cohort_year, order_year
)
SELECT *
FROM cohort_activity
ORDER BY cohort_year, years_since_first_purchase;


-- ------------------------------------------------------------
-- Query 2B: Retention (%)
-- ------------------------------------------------------------
-- Converts cohort activity into a retention RATE: what % of a
-- cohort's original size is still active in each subsequent
-- year. Year 0 will always show 100% by definition (the cohort
-- is defined by its first purchase). Watch Year 1 onward for the
-- real drop-off pattern -- remember the 2024 cohort caveat above
-- applies here with even more force, since a 1-customer cohort's
-- retention_pct can only ever read 100% or 0%.
-- ------------------------------------------------------------
WITH first_purchase AS (
    SELECT
        customer_id,
        YEAR(MIN(order_date)) AS cohort_year
    FROM orders
    WHERE status = 'Delivered'
    GROUP BY customer_id
),
orders_with_cohort AS (
    SELECT
        o.customer_id,
        fp.cohort_year,
        YEAR(o.order_date) AS order_year,
        oi.unit_price * oi.quantity * (1 - oi.discount / 100) AS revenue
    FROM orders AS o
    INNER JOIN first_purchase AS fp ON o.customer_id = fp.customer_id
    INNER JOIN order_items AS oi ON o.order_id = oi.order_id
    WHERE o.status = 'Delivered'
),
cohort_activity AS (
    SELECT
        cohort_year,
        order_year,
        order_year - cohort_year AS years_since_first_purchase,
        COUNT(DISTINCT customer_id) AS active_customers
    FROM orders_with_cohort
    GROUP BY cohort_year, order_year
),
cohort_size AS (
    SELECT
        cohort_year,
        COUNT(DISTINCT customer_id) AS total_customers
    FROM first_purchase
    GROUP BY cohort_year
)
SELECT
    ca.cohort_year,
    ca.years_since_first_purchase,
    ca.active_customers,
    cs.total_customers,
    ROUND(ca.active_customers / cs.total_customers * 100, 2) AS retention_pct
FROM cohort_activity AS ca
INNER JOIN cohort_size AS cs ON ca.cohort_year = cs.cohort_year
ORDER BY ca.cohort_year, ca.years_since_first_purchase;
