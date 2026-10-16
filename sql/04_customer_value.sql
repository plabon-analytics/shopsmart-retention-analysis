-- ============================================================
-- SECTION 4: CUSTOMER LIFETIME VALUE (CLV)
-- ShopSmart Retention Analysis | Plabon Roy
-- ============================================================
-- Business Question:
--   If we retain a given customer/segment, how much revenue is
--   actually at stake -- both historically observed, and
--   predicted forward using the population-level churn rate
--   derived from Section 2's retention data?
--
-- Revenue definition:
--   Net revenue -- unit_price * quantity * (1 - discount/100) --
--   consistent with every section so far.
--
-- Churn rate derivation -- IMPORTANT, READ BEFORE TRUSTING THE
-- PREDICTIVE CLV NUMBERS:
--   Churn rate is computed as 1 - AVG(retention_pct)/100, taken
--   across every (cohort_year, years_since_first_purchase > 0)
--   row from Section 2's retention logic. This is an ANNUAL
--   churn rate, because Section 2's grain is yearly.
--
--   The 2024 cohort (n=1, see Section 2's header) is excluded
--   here -- a single customer's binary active/inactive status
--   would distort a population-level average.
--
--   The final calendar year (2026) is also excluded. The data ends
--   on 2026-05-28, so 2026 covers about five months, and counting
--   a customer as "not retained" because they have not yet bought
--   again in a partial year would overstate churn. Including it
--   gives 28.57% annual churn (3.5-year lifespan); excluding it
--   gives 20.00% (5-year lifespan). Every customer's predictive
--   CLV scales by the same factor between the two, so rankings,
--   tiers and the Section 7 priorities do not change; only the
--   absolute rupee values do.
--
--   LIMITATION: this is a simplifying average, not a strict
--   probabilistic churn model. Section 2 showed the 2022 cohort
--   bouncing from 66.67% back up to 83.33% retention -- real
--   lapse-and-return behavior that the classic "Lifespan =
--   1/Churn Rate" formula does not strictly account for (it
--   assumes monotonic, one-way attrition). Treat predictive_clv
--   as a directional estimate, not a precise forecast, and say
--   so explicitly in the README.
--
-- NULLIF handling:
--   Single-order customers have lifespan_months = 0, so
--   purchase_frequency_monthly (and therefore both CLV columns)
--   return NULL rather than crashing on a divide-by-zero. This
--   is expected -- e.g. Vikram Singh and Rahul Verma (RFM
--   "Lost", frequency = 1) will show NULL CLV here. A one-order
--   customer has no observable purchase cadence to project from.
-- ============================================================

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
      AND cohort_year + years_since_first_purchase
          < (SELECT YEAR(MAX(order_date)) FROM orders)   -- skip the incomplete final year, see header
      AND cohort_year != 2024   -- exclude n=1 cohort, see header
),
customer_summary AS (
    SELECT
        c.customer_id,
        c.full_name,
        COUNT(DISTINCT o.order_id)                                        AS total_orders,
        ROUND(SUM(oi.unit_price * oi.quantity * (1 - oi.discount / 100)), 2) AS total_revenue,
        MIN(o.order_date) AS first_order_date,
        MAX(o.order_date) AS last_order_date,
        TIMESTAMPDIFF(MONTH, MIN(o.order_date), MAX(o.order_date)) AS lifespan_months
    FROM customers AS c
    INNER JOIN orders AS o ON c.customer_id = o.customer_id
    INNER JOIN order_items AS oi ON o.order_id = oi.order_id
    WHERE o.status = 'Delivered'
    GROUP BY c.customer_id, c.full_name
)
SELECT
    cs.customer_id,
    cs.full_name,
    cs.total_orders,
    cs.total_revenue,
    cs.lifespan_months,
    ROUND(cs.total_revenue / cs.total_orders, 2)                      AS aov,
    ROUND(cs.total_orders / NULLIF(cs.lifespan_months, 0), 4)         AS purchase_frequency_monthly,
    ROUND(
        (cs.total_revenue / cs.total_orders)
        * (cs.total_orders / NULLIF(cs.lifespan_months, 0))
        * cs.lifespan_months
    , 2)                                                               AS historical_clv,
    ROUND(cr.annual_churn_rate * 100, 2)                              AS population_churn_rate_pct,
    ROUND(1 / cr.annual_churn_rate, 2)                                AS predictive_lifespan_years,
    ROUND(
        (cs.total_revenue / cs.total_orders)
        * (cs.total_orders / NULLIF(cs.lifespan_months, 0))
        * (1 / cr.annual_churn_rate * 12)
    , 2)                                                               AS predictive_clv
FROM customer_summary AS cs
CROSS JOIN churn_rate AS cr
ORDER BY predictive_clv DESC, cs.customer_id;
