-- ============================================================
-- SECTION 3: CUSTOMER SEGMENTATION (RFM)
-- ShopSmart Retention Analysis | Plabon Roy
-- ============================================================
-- Business Question:
--   Which named groups of customers exist based on how recently,
--   how often, and how much they buy -- and which of those groups
--   look like retention candidates vs. lost causes?
--
-- Sample size decision -- NTILE(3), not NTILE(5):
--   ShopSmart's real analytical base is 19 customers (those with
--   at least one Delivered order -- see Section 0.4 and Section 2
--   header for the full 29 / 2 / 19 customer breakdown). NTILE(5)
--   across 19 customers would produce buckets of ~3-4 customers
--   each, too coarse to call a "score" meaningful. NTILE(3) gives
--   cleaner, more defensible Low/Medium/High buckets at this
--   sample size.
--
-- Revenue definition:
--   monetary = unit_price * quantity * (1 - discount/100) -- NET
--   revenue, consistent with every section so far.
--
-- Exclusion note:
--   Priya Patel and Pooja Reddy (orders exist, but none Delivered)
--   are excluded here by the same WHERE status = 'Delivered'
--   filter used throughout -- not a new exclusion, just the same
--   one surfacing again. Documented once here, not re-derived.
--
-- CAUTION -- NTILE direction (confirmed working, verify again if
-- reused elsewhere): recency_days is ordered DESC because a LOWER
-- day count is better (more recent) -- so the most recent buyers
-- land in the highest-numbered bucket. frequency and monetary are
-- ordered ASC, since higher values are straightforwardly better.
--
-- As-of date:
--   recency_days is measured from the latest order_date in the
--   data (SELECT MAX(order_date) FROM orders), not from CURDATE().
--   That keeps the results identical on every run. Using the run
--   date would add the same number of days to every customer, so
--   scores and segments would not change, but the displayed day
--   counts would drift daily.
--
-- Tie-breaking inside NTILE:
--   Several customers share the same frequency (five customers
--   have exactly 4 orders). NTILE splits tied values across
--   buckets in whatever order the database happens to return the
--   rows, so without a tiebreaker one customer's score could
--   differ between engines or runs. Every NTILE therefore ends
--   with a deterministic tiebreaker. For frequency, ties are
--   broken by monetary (more spend ranks higher), then by
--   customer_id. Results are identical on every run.
-- ============================================================

WITH customer_rfm_base AS (
    SELECT
        c.customer_id,
        c.full_name,
        DATEDIFF((SELECT MAX(order_date) FROM orders), MAX(o.order_date))                           AS recency_days,
        COUNT(DISTINCT o.order_id)                                        AS frequency,
        ROUND(SUM(oi.unit_price * oi.quantity * (1 - oi.discount / 100)), 2) AS monetary
    FROM customers AS c
    INNER JOIN orders AS o ON c.customer_id = o.customer_id
    INNER JOIN order_items AS oi ON o.order_id = oi.order_id
    WHERE o.status = 'Delivered'
    GROUP BY c.customer_id, c.full_name
)
SELECT
    *,
    NTILE(3) OVER (ORDER BY recency_days DESC, customer_id) AS r_score,
    NTILE(3) OVER (ORDER BY frequency ASC, monetary ASC, customer_id)     AS f_score,
    NTILE(3) OVER (ORDER BY monetary ASC, customer_id)      AS m_score
FROM customer_rfm_base
ORDER BY customer_id;


-- ------------------------------------------------------------
-- Query 3B: RFM Segment Labels
-- ------------------------------------------------------------
-- Converts raw r/f/m scores into named segments. Rules were
-- derived by hand-checking every (r,f,m) combination present in
-- the actual 19-customer output -- not a generic template -- and
-- verified to cover all 19 customers with no gaps or overlaps.
--
-- IMPORTANT: CASE WHEN evaluates top to bottom and stops at the
-- first match. The order below is deliberate -- e.g. a customer
-- with (r=3, f=3, m=2) must be caught by the "Loyal Customers"
-- rule BEFORE the "Potential Loyalists" rule is ever checked, or
-- it would be mislabeled. Re-verify by hand against real data
-- before reordering these rules.
-- ------------------------------------------------------------
WITH customer_rfm_base AS (
    SELECT
        c.customer_id,
        c.full_name,
        DATEDIFF((SELECT MAX(order_date) FROM orders), MAX(o.order_date))                           AS recency_days,
        COUNT(DISTINCT o.order_id)                                        AS frequency,
        ROUND(SUM(oi.unit_price * oi.quantity * (1 - oi.discount / 100)), 2) AS monetary
    FROM customers AS c
    INNER JOIN orders AS o ON c.customer_id = o.customer_id
    INNER JOIN order_items AS oi ON o.order_id = oi.order_id
    WHERE o.status = 'Delivered'
    GROUP BY c.customer_id, c.full_name
),
rfm_scores AS (
    SELECT
        *,
        NTILE(3) OVER (ORDER BY recency_days DESC, customer_id) AS r_score,
        NTILE(3) OVER (ORDER BY frequency ASC, monetary ASC, customer_id)     AS f_score,
        NTILE(3) OVER (ORDER BY monetary ASC, customer_id)      AS m_score
    FROM customer_rfm_base
)
SELECT
    *,
    CASE
        WHEN r_score = 3 AND f_score = 3 AND m_score = 3           THEN 'Champions'
        WHEN r_score >= 2 AND f_score = 3                          THEN 'Loyal Customers'
        WHEN r_score = 3 AND f_score <= 2                          THEN 'Potential Loyalists'
        WHEN r_score = 1 AND (f_score >= 2 OR m_score >= 2)        THEN 'At Risk'
        WHEN r_score = 1 AND f_score = 1 AND m_score = 1           THEN 'Lost'
        ELSE 'Needs Attention'
    END AS rfm_segment
FROM rfm_scores
ORDER BY rfm_segment, customer_id;
