-- ============================================================
-- USER ANALYTICS - SALES FUNNEL ANALYSIS
-- Google BigQuery SQL Project
-- ============================================================


-- ============================================================
-- 1. OVERALL SALES FUNNEL
-- Count the number of unique users at each funnel stage
-- ============================================================

SELECT
  COUNT(DISTINCT CASE
    WHEN event_type = 'page_view' THEN user_id
  END) AS stage_1_views,

  COUNT(DISTINCT CASE
    WHEN event_type = 'add_to_cart' THEN user_id
  END) AS stage_2_cart,

  COUNT(DISTINCT CASE
    WHEN event_type = 'checkout_start' THEN user_id
  END) AS stage_3_checkout,

  COUNT(DISTINCT CASE
    WHEN event_type = 'payment_info' THEN user_id
  END) AS stage_4_payment,

  COUNT(DISTINCT CASE
    WHEN event_type = 'purchase' THEN user_id
  END) AS stage_5_purchase

FROM `project-ced1631c-bbd3-44bb-ae4.User_Analytics.user_events`;


-- ============================================================
-- 2. SALES FUNNEL CONVERSION RATES
-- Measure how many users move from one stage to the next
-- ============================================================

WITH funnel_stages AS (

  SELECT
    COUNT(DISTINCT CASE
      WHEN event_type = 'page_view' THEN user_id
    END) AS stage_1_views,

    COUNT(DISTINCT CASE
      WHEN event_type = 'add_to_cart' THEN user_id
    END) AS stage_2_cart,

    COUNT(DISTINCT CASE
      WHEN event_type = 'checkout_start' THEN user_id
    END) AS stage_3_checkout,

    COUNT(DISTINCT CASE
      WHEN event_type = 'payment_info' THEN user_id
    END) AS stage_4_payment,

    COUNT(DISTINCT CASE
      WHEN event_type = 'purchase' THEN user_id
    END) AS stage_5_purchase

  FROM `project-ced1631c-bbd3-44bb-ae4.User_Analytics.user_events`
)

SELECT
  stage_1_views,
  stage_2_cart,
  stage_3_checkout,
  stage_4_payment,
  stage_5_purchase,

  ROUND(stage_2_cart * 100.0 / stage_1_views, 2)
    AS view_to_cart_rate,

  ROUND(stage_3_checkout * 100.0 / stage_2_cart, 2)
    AS cart_to_checkout_rate,

  ROUND(stage_4_payment * 100.0 / stage_3_checkout, 2)
    AS checkout_to_payment_rate,

  ROUND(stage_5_purchase * 100.0 / stage_4_payment, 2)
    AS payment_to_purchase_rate,

  ROUND(stage_5_purchase * 100.0 / stage_1_views, 2)
    AS overall_conversion_rate

FROM funnel_stages;


-- ============================================================
-- 3. SALES FUNNEL BY TRAFFIC SOURCE
-- Compare user behaviour across different acquisition channels
-- ============================================================

SELECT
  traffic_source,

  COUNT(DISTINCT CASE
    WHEN event_type = 'page_view' THEN user_id
  END) AS stage_1_views,

  COUNT(DISTINCT CASE
    WHEN event_type = 'add_to_cart' THEN user_id
  END) AS stage_2_cart,

  COUNT(DISTINCT CASE
    WHEN event_type = 'checkout_start' THEN user_id
  END) AS stage_3_checkout,

  COUNT(DISTINCT CASE
    WHEN event_type = 'payment_info' THEN user_id
  END) AS stage_4_payment,

  COUNT(DISTINCT CASE
    WHEN event_type = 'purchase' THEN user_id
  END) AS stage_5_purchase

FROM `project-ced1631c-bbd3-44bb-ae4.User_Analytics.user_events`

GROUP BY traffic_source
ORDER BY stage_1_views DESC;


-- ============================================================
-- 4. CONVERSION RATE BY TRAFFIC SOURCE
-- Measure which traffic sources convert users most effectively
-- ============================================================

WITH source_funnel AS (

  SELECT
    traffic_source,

    COUNT(DISTINCT CASE
      WHEN event_type = 'page_view' THEN user_id
    END) AS stage_1_views,

    COUNT(DISTINCT CASE
      WHEN event_type = 'add_to_cart' THEN user_id
    END) AS stage_2_cart,

    COUNT(DISTINCT CASE
      WHEN event_type = 'checkout_start' THEN user_id
    END) AS stage_3_checkout,

    COUNT(DISTINCT CASE
      WHEN event_type = 'payment_info' THEN user_id
    END) AS stage_4_payment,

    COUNT(DISTINCT CASE
      WHEN event_type = 'purchase' THEN user_id
    END) AS stage_5_purchase

  FROM `project-ced1631c-bbd3-44bb-ae4.User_Analytics.user_events`

  GROUP BY traffic_source
)

SELECT
  traffic_source,
  stage_1_views,
  stage_2_cart,
  stage_3_checkout,
  stage_4_payment,
  stage_5_purchase,

  ROUND(stage_2_cart * 100.0 / stage_1_views, 2)
    AS view_to_cart_rate,

  ROUND(stage_3_checkout * 100.0 / stage_2_cart, 2)
    AS cart_to_checkout_rate,

  ROUND(stage_4_payment * 100.0 / stage_3_checkout, 2)
    AS checkout_to_payment_rate,

  ROUND(stage_5_purchase * 100.0 / stage_4_payment, 2)
    AS payment_to_purchase_rate,

  ROUND(stage_5_purchase * 100.0 / stage_1_views, 2)
    AS overall_conversion_rate

FROM source_funnel

ORDER BY overall_conversion_rate DESC;


-- ============================================================
-- 5. TIME TO CONVERSION
-- Measure how long converted users take to move through the funnel
-- ============================================================

WITH user_journey AS (

  SELECT
    user_id,

    MIN(CASE
      WHEN event_type = 'page_view' THEN event_date
    END) AS view_time,

    MIN(CASE
      WHEN event_type = 'add_to_cart' THEN event_date
    END) AS cart_time,

    MIN(CASE
      WHEN event_type = 'purchase' THEN event_date
    END) AS purchase_time

  FROM `project-ced1631c-bbd3-44bb-ae4.User_Analytics.user_events`

  GROUP BY user_id

  HAVING MIN(CASE
    WHEN event_type = 'purchase' THEN event_date
  END) IS NOT NULL
)

SELECT
  COUNT(*) AS converted_users,

  ROUND(
    AVG(TIMESTAMP_DIFF(cart_time, view_time, MINUTE)),
    2
  ) AS avg_view_to_cart_minutes,

  ROUND(
    AVG(TIMESTAMP_DIFF(purchase_time, cart_time, MINUTE)),
    2
  ) AS avg_cart_to_purchase_minutes,

  ROUND(
    AVG(TIMESTAMP_DIFF(purchase_time, view_time, MINUTE)),
    2
  ) AS avg_total_journey_minutes

FROM user_journey

WHERE view_time IS NOT NULL
  AND cart_time IS NOT NULL;


-- ============================================================
-- 6. REVENUE ANALYSIS
-- Measure total purchases, buyers, revenue and average order value
-- ============================================================

SELECT
  COUNTIF(event_type = 'purchase')
    AS total_purchases,

  COUNT(DISTINCT CASE
    WHEN event_type = 'purchase' THEN user_id
  END) AS purchasing_users,

  ROUND(
    SUM(CASE
      WHEN event_type = 'purchase' THEN amount
      ELSE 0
    END),
    2
  ) AS total_revenue,

  ROUND(
    SUM(CASE
      WHEN event_type = 'purchase' THEN amount
      ELSE 0
    END)
    / COUNTIF(event_type = 'purchase'),
    2
  ) AS average_order_value

FROM `project-ced1631c-bbd3-44bb-ae4.User_Analytics.user_events`;