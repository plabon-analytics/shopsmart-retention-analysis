-- ============================================================
-- SECTION 7: FINAL SYNTHESIS & RECOMMENDATION
-- ShopSmart Retention Analysis | Plabon Roy
-- ============================================================
-- Business Question (the project's central question, answered
-- directly by this section):
--   Which customers should ShopSmart invest retention budget in,
--   and why?
--
-- Design decision -- CLV-first, RFM as context (not the reverse):
--   Section 4 found that RFM segment does NOT predict CLV rank --
--   "Champions" landed at #3, #7 and #8 by predictive CLV, not
--   #1-3. Sorting this final table by RFM segment would bury that
--   finding. Instead, this section ranks by predictive_clv (how
--   much revenue is actually at stake) and uses RFM's r_score as a
--   second, independent signal: not "how valuable is this
--   customer" (CLV already answers that) but "how urgent is their
--   risk of lapsing" (recency does that better than a segment
--   label can).
--
-- The retention_priority matrix:
--   clv_tier = NTILE(3) on predictive_clv (tier 3 = highest value),
--   consistent with the NTILE(3) resolution used throughout this
--   project for a 19-customer sample. r_score is reused directly
--   from Section 3 (3 = most recent/engaged, 1 = least recent/at
--   risk). These two signals are crossed into 4 clear action
--   buckets -- deliberately simplified from a 3x3 grid (9 overlapping
--   combinations) to 4, because a final recommendation table should
--   be actionable, not just granular:
--
--                    r_score = 1 (at risk)   r_score 2-3 (engaged)
--     clv_tier = 3    INVEST NOW              PROTECT
--     clv_tier 1-2    LOW PRIORITY            MONITOR
--
--   INVEST NOW  = high value, going quiet -- the direct answer to
--                 this project's central question.
--   PROTECT     = high value, still engaged -- don't neglect them
--                 into becoming an INVEST NOW case later.
--   MONITOR     = lower value but still active -- watch for growth.
--   LOW PRIORITY = lower value, not recently active -- not worth
--                 dedicated retention spend right now.
--
-- NULL CLV handling:
--   Vikram Singh and Rahul Verma (single-order customers, see
--   Section 4) have NULL predictive_clv. MySQL's NTILE sorts NULLs
--   first under ORDER BY ... ASC, so they land in clv_tier = 1 by
--   default -- consistent with their already-"Lost" RFM segment,
--   and arguably correct: no observable spend pattern to justify
--   prioritizing them.
--
-- Scope reminder:
--   All 19 real (at least one Delivered order) customers are
--   included. Priya Patel and Pooja Reddy (orders exist, none
--   Delivered) remain excluded by the same status filter used
--   throughout this entire project.
--
-- As-of date:
--   recency_days is measured from the latest order_date in the
--   data, not from CURDATE(), so every run gives the same numbers
--   (see Section 3's header for the reasoning).
--
-- Tie-breaking:
--   Every NTILE here ends with a deterministic tiebreaker, as in
--   Section 3, so scores and tiers do not depend on row order.
-- ============================================================

WITH
-- ---- RFM chain (Section 3) ----
customer_rfm_base AS (
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
),
rfm_segmented AS (
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
),

-- ---- CLV chain (Section 4) ----
first_purchase AS (
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
        YEAR(o.order_date) AS order_year
    FROM orders AS o
    INNER JOIN first_purchase AS fp ON o.customer_id = fp.customer_id
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
),
retention_calc AS (
    SELECT
        ca.cohort_year,
        ca.years_since_first_purchase,
        ROUND(ca.active_customers / cs.total_customers * 100, 2) AS retention_pct
    FROM cohort_activity AS ca
    INNER JOIN cohort_size AS cs ON ca.cohort_year = cs.cohort_year
),
churn_rate AS (
    SELECT
        1 - (AVG(retention_pct) / 100) AS annual_churn_rate
    FROM retention_calc
    WHERE years_since_first_purchase > 0
      AND cohort_year != 2024
),
customer_summary AS (
    SELECT
        c.customer_id,
        COUNT(DISTINCT o.order_id)                                        AS total_orders,
        ROUND(SUM(oi.unit_price * oi.quantity * (1 - oi.discount / 100)), 2) AS total_revenue,
        TIMESTAMPDIFF(MONTH, MIN(o.order_date), MAX(o.order_date))       AS lifespan_months
    FROM customers AS c
    INNER JOIN orders AS o ON c.customer_id = o.customer_id
    INNER JOIN order_items AS oi ON o.order_id = oi.order_id
    WHERE o.status = 'Delivered'
    GROUP BY c.customer_id
),
clv_calc AS (
    SELECT
        cs.customer_id,
        ROUND(
            (cs.total_revenue / cs.total_orders)
            * (cs.total_orders / NULLIF(cs.lifespan_months, 0))
            * (1 / cr.annual_churn_rate * 12)
        , 2) AS predictive_clv
    FROM customer_summary AS cs
    CROSS JOIN churn_rate AS cr
),
clv_tiered AS (
    SELECT
        *,
        NTILE(3) OVER (ORDER BY predictive_clv ASC, customer_id) AS clv_tier
    FROM clv_calc
)

-- ---- Final synthesis ----
SELECT
    rs.customer_id,
    rs.full_name,
    ct.predictive_clv,
    ct.clv_tier,
    rs.rfm_segment,
    rs.recency_days,
    rs.r_score,
    CASE
        WHEN ct.clv_tier = 3 AND rs.r_score = 1 THEN 'INVEST NOW'
        WHEN ct.clv_tier = 3 AND rs.r_score >= 2 THEN 'PROTECT'
        WHEN ct.clv_tier <= 2 AND rs.r_score = 1 THEN 'LOW PRIORITY'
        ELSE 'MONITOR'
    END AS retention_priority
FROM rfm_segmented AS rs
INNER JOIN clv_tiered AS ct ON rs.customer_id = ct.customer_id
ORDER BY ct.predictive_clv DESC, rs.customer_id;
