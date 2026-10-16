-- ============================================================
-- SECTION 5: FUNNEL ANALYSIS
-- ShopSmart Retention Analysis | Plabon Roy
-- ============================================================
-- Business Question:
--   Where in the order process does ShopSmart lose customers --
--   and is drop-off happening at the process level (cancellations)
--   or after the fact (returns), once an order has already been
--   fulfilled?
--
-- IMPORTANT -- no status filter here, unlike every section before:
--   Sections 1-4 all filter WHERE status = 'Delivered' because they
--   measure realized revenue. Funnel Analysis does the opposite --
--   it needs every order regardless of outcome, because the entire
--   point is tracking what happens to orders that do NOT survive.
--   Filtering to Delivered-only first would make every stage read
--   100% and the funnel would disappear.
--
-- Stage structure:
--   All 3 real statuses are mutually exclusive and exhaustive --
--   confirmed: 100 Delivered + 8 Cancelled + 7 Returned = 115,
--   exactly matching total order count (see Section 0.1, 0.3).
--   Stages: Placed -> Confirmed (i.e. not Cancelled) -> Delivered,
--   with Returned reported as its own measured outcome.
--
-- Percentage base -- DECIDED:
--   Every stage's percentage is measured against the ORIGINAL
--   total_orders_placed, not against the previous stage. This
--   keeps every number on the same base and directly comparable.
--
-- Known limitation -- Returned undercounts item-level returns:
--   The returns table holds 15 item-level return records across 8
--   distinct orders, but only 7 orders carry status = 'Returned' at
--   the order level -- 1 order has a partial item return while its
--   order-level status remains 'Delivered'. This section reports 7
--   returned orders (order-level grain, matching every other
--   analysis's grain), not 8. Documented here so it isn't mistaken
--   for an error if cross-checked against the returns table.
--
-- Supporting queries 5B and 5C:
--   The funnel rates show how often orders fail. They do not show
--   why, or whether the customers involved went on to leave.
--   5B groups the 15 return records by reason. 5C lists the
--   customers behind returned orders and when each last had a
--   Delivered order, measured against the last order date in the
--   data.
--
-- What this section supports (worded carefully):
--   Rates: 93.04% of orders are confirmed. Cancelled (6.96%) and
--   Returned (6.09%) are both small and close in size, so there is
--   no single dominant leak.
--   Causes: of 15 return records, 8 point to product quality or
--   fulfillment (defective 4, arrived damaged 1, damaged packaging
--   1, wrong item 1, wrong size 1), 3 are ambiguous (not as
--   described, not as expected, size unavailable for exchange) and
--   4 are customer preference (changed mind 3, better price
--   elsewhere 1). The grouping is an analyst judgment. The returns
--   that do happen are mostly within ShopSmart's control.
--   Customers: 5C finds 5 customers behind returned orders. Four
--   had a Delivered order within about five months of the end of
--   the data; the fifth (Pooja Reddy) has no Delivered order at
--   all. None of the four is in Section 7's INVEST NOW group.
--   Read together, this is no evidence that fulfillment problems
--   drive churn in this data. It does not prove they never do, and
--   the customer-level check covers only 4 people.
-- ============================================================

WITH funnel_stages AS (
    SELECT
        COUNT(DISTINCT order_id) AS total_orders_placed,
        COUNT(DISTINCT CASE WHEN status != 'Cancelled' THEN order_id END) AS orders_confirmed,
        COUNT(DISTINCT CASE WHEN status = 'Delivered'  THEN order_id END) AS orders_delivered,
        COUNT(DISTINCT CASE WHEN status = 'Returned'   THEN order_id END) AS orders_returned,
        COUNT(DISTINCT CASE WHEN status = 'Cancelled'  THEN order_id END) AS orders_cancelled
    FROM orders
)
SELECT
    total_orders_placed,

    orders_confirmed,
    ROUND(orders_confirmed / total_orders_placed * 100, 2) AS pct_confirmed,

    orders_delivered,
    ROUND(orders_delivered / total_orders_placed * 100, 2) AS pct_delivered,

    orders_returned,
    ROUND(orders_returned / total_orders_placed * 100, 2) AS pct_returned,

    orders_cancelled,
    ROUND(orders_cancelled / total_orders_placed * 100, 2) AS pct_cancelled
FROM funnel_stages;


-- ------------------------------------------------------------
-- Query 5B: Why do returns happen?
-- ------------------------------------------------------------
-- Item-level grain: one order can carry several return records,
-- so return_records can exceed orders_affected. Reasons are listed
-- as stored; any grouping into "product/fulfillment" vs "customer
-- preference" is an analyst judgment made outside this query.
-- ------------------------------------------------------------
SELECT
    reason,
    COUNT(*)                 AS return_records,
    COUNT(DISTINCT order_id) AS orders_affected
FROM returns
GROUP BY reason
ORDER BY return_records DESC, reason;


-- ------------------------------------------------------------
-- Query 5C: Are the customers who returned items still active?
-- ------------------------------------------------------------
-- Lists every customer with at least one order in the returns
-- table, how many Delivered orders they have, and how long before
-- the end of the data their last Delivered order was. The as-of
-- date is the latest order_date in the data, so the result does
-- not change from day to day.
--
-- LEFT JOIN on Delivered orders keeps customers with no Delivered
-- order at all (they show 0 and NULL, listed last) instead of
-- silently dropping them.
-- ------------------------------------------------------------
WITH returned_customers AS (
    SELECT
        o.customer_id,
        COUNT(DISTINCT r.order_id) AS orders_with_returns
    FROM returns AS r
    INNER JOIN orders AS o ON r.order_id = o.order_id
    GROUP BY o.customer_id
),
as_of AS (
    SELECT MAX(order_date) AS as_of_date FROM orders
)
SELECT
    c.customer_id,
    c.full_name,
    rc.orders_with_returns,
    COUNT(DISTINCT d.order_id)                 AS delivered_orders,
    MAX(d.order_date)                          AS last_delivered_order,
    DATEDIFF(a.as_of_date, MAX(d.order_date))  AS days_before_data_end
FROM returned_customers AS rc
INNER JOIN customers AS c ON rc.customer_id = c.customer_id
LEFT JOIN orders AS d
    ON d.customer_id = c.customer_id
    AND d.status = 'Delivered'
CROSS JOIN as_of AS a
GROUP BY c.customer_id, c.full_name, rc.orders_with_returns, a.as_of_date
ORDER BY MAX(d.order_date) IS NULL, MAX(d.order_date) DESC;
