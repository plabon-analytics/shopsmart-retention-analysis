-- ============================================================
-- SECTION 6: MARKET BASKET ANALYSIS (INTRO)
-- ShopSmart Retention Analysis | Plabon Roy
-- ============================================================
-- Business Question:
--   What should ShopSmart recommend or bundle for the customers
--   this project identifies as worth retaining? (Bonus/action
--   layer on top of Sections 3-4's segmentation and value work.)
--
-- KNOWN LIMITATION -- read before interpreting results:
--   Market Basket needs orders with 2+ DISTINCT products to form
--   even one pair. Of the 107 orders eligible under this section's
--   status filter (Delivered + Returned -- see below), 96 contain
--   exactly 1 item and only 11 contain exactly 2 items; none
--   contain 3 or more. That caps this entire analysis at a MAXIMUM
--   of 11 possible product pairs, before even checking whether any
--   of those 11 orders repeat the same product twice (which would
--   yield zero valid pairs under the product_id1 < product_id2
--   condition below).
--
--   This section is included as a technical demonstration of
--   co-occurrence analysis via self-join -- a technique none of
--   the other 7 analyses use -- NOT as a statistically reliable
--   "frequently bought together" system. With at most 11 pairs
--   possible, any single result could be coincidence rather than
--   a real pattern. State this explicitly in the README; do not
--   present specific pairings as confident recommendations.
--
--   Advanced Market Basket (Support/Confidence/Lift, Apriori/
--   FP-Growth) remains explicitly out of scope -- flagged as
--   possible future work, not attempted here.
--
-- Status filter -- DIFFERENT logic than every other section:
--   Sections 1-5 filter to Delivered only (realized revenue) or
--   all statuses (Funnel). Market Basket instead includes any
--   status representing a completed PURCHASE DECISION -- Delivered
--   AND Returned -- and excludes only Cancelled, since a cancelled
--   order was never actually purchased together. A return still
--   reflects a genuine co-purchase decision at checkout, even if
--   one item later came back.
--
-- Self-join logic:
--   order_items is joined to itself on a shared order_id. The
--   product_id1 < product_id2 condition does two things at once:
--   (a) prevents counting both (A,B) and (B,A) as separate pairs,
--   and (b) prevents a product pairing with itself.
-- ============================================================

SELECT
    p1.product_name AS product_a,
    p2.product_name AS product_b,
    COUNT(DISTINCT oi1.order_id) AS times_bought_together
FROM order_items AS oi1
INNER JOIN order_items AS oi2
    ON oi1.order_id = oi2.order_id
    AND oi1.product_id < oi2.product_id
INNER JOIN orders AS o ON oi1.order_id = o.order_id
INNER JOIN products AS p1 ON oi1.product_id = p1.product_id
INNER JOIN products AS p2 ON oi2.product_id = p2.product_id
WHERE o.status IN ('Delivered', 'Returned')
GROUP BY p1.product_name, p2.product_name
ORDER BY times_bought_together DESC, product_a, product_b;
