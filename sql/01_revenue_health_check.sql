-- ============================================================
-- SECTION 1: REVENUE HEALTH CHECK
-- ShopSmart Retention Analysis | Plabon Roy
-- ============================================================
-- Business Question:
--   Is ShopSmart's revenue actually growing, declining, or flat --
--   and does that justify a retention-focused intervention at all?
--
-- Approach:
--   Rolling 3-month average smooths short-term noise to reveal the
--   true underlying trend. MoM/YoY growth then quantifies that
--   trend precisely, period over period and year over year.
--
-- Reused foundation:
--   Both queries below run on top of the SAME monthly_revenue CTE,
--   defined once. This avoids duplicating the base aggregation
--   logic across two analyses that share an identical grain
--   (one row per calendar month).
--
-- Revenue definition:
--   revenue = unit_price * quantity * (1 - discount/100) -- NET
--   revenue, i.e. what ShopSmart actually collects after any
--   per-line-item discount. Gross revenue (ignoring discount)
--   would overstate true revenue and distort every trend below.
--
-- Scope note:
--   Only 'Delivered' orders count as realized revenue. Cancelled
--   and Returned orders are excluded here (unlike Market Basket,
--   which deliberately includes Returned -- see Section 6).
--
-- Calendar assumption:
--   LAG(revenue, 1) and LAG(revenue, 12) step back by ROWS, not by
--   calendar months. That is only correct if every month appears in
--   monthly_revenue. In this data all 53 months from 2022-01 to
--   2026-05 have at least one Delivered order (checked), so the
--   comparisons are true month-over-month and year-over-year. If a
--   month had no Delivered orders its row would be missing and the
--   comparisons would silently skip it.
-- ============================================================

WITH monthly_revenue AS (
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m')          AS order_year_month,
        ROUND(SUM(oi.unit_price * oi.quantity * (1 - oi.discount / 100)), 2) AS revenue
    FROM orders AS o
    INNER JOIN order_items AS oi ON o.order_id = oi.order_id
    WHERE o.status = 'Delivered'
    GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
)

-- ------------------------------------------------------------
-- Query 1A: Rolling 3-Month Average Revenue
-- ------------------------------------------------------------
-- Smooths out one-off spikes/dips so we can see the real trend
-- direction, not noise. First 2 months will show a PARTIAL
-- window (fewer than 3 months of data) -- disclosed in README.
-- ------------------------------------------------------------
SELECT
    order_year_month,
    revenue,
    ROUND(AVG(revenue) OVER (
        ORDER BY order_year_month
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) AS rolling_3month_avg
FROM monthly_revenue
ORDER BY order_year_month;


-- ------------------------------------------------------------
-- Query 1B: Month-over-Month & Year-over-Year Growth
-- ------------------------------------------------------------
-- Quantifies exact % change vs. the previous month (MoM) and
-- vs. the same month last year (YoY). Complements the rolling
-- average above: rolling avg shows the smoothed trend line,
-- this shows the precise period-to-period movement.
--
-- NULLIF guards against divide-by-zero for the first month(s)
-- of data, where no prior period exists yet.
-- ------------------------------------------------------------
WITH monthly_revenue AS (
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m')          AS order_year_month,
        ROUND(SUM(oi.unit_price * oi.quantity * (1 - oi.discount / 100)), 2) AS revenue
    FROM orders AS o
    INNER JOIN order_items AS oi ON o.order_id = oi.order_id
    WHERE o.status = 'Delivered'
    GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
),
growth_calc AS (
    SELECT
        order_year_month,
        revenue,
        LAG(revenue, 1)  OVER (ORDER BY order_year_month) AS prev_month_revenue,
        LAG(revenue, 12) OVER (ORDER BY order_year_month) AS prev_year_revenue
    FROM monthly_revenue
)
SELECT
    order_year_month,
    revenue,
    ROUND((revenue - prev_month_revenue) / NULLIF(prev_month_revenue, 0) * 100, 2) AS mom_growth_pct,
    ROUND((revenue - prev_year_revenue)  / NULLIF(prev_year_revenue, 0)  * 100, 2) AS yoy_growth_pct
FROM growth_calc
ORDER BY order_year_month;
