WITH
  cte_bulk_orders AS (
    SELECT
      o.id order_id,
      o.created_at,
      CASE 
        when o.created_at between '2023-03-01' and '2023-04-01' then 'March'
        when o.created_at between '2023-04-01' and '2023-05-01' then 'April'
        when o.created_at between '2023-05-01' and '2023-06-01' then 'May'
        when o.created_at between '2023-06-01' and '2023-07-01' then 'June'
        when o.created_at between '2023-07-01' and '2023-08-01' then 'July'
        when o.created_at between '2023-08-01' and '2023-09-01' then 'August'
        ELSE 'other'
      END as order_month,
      SUM(quantity) total_quantity,
      d.code,
      d.type,
      CASE
        WHEN total_quantity BETWEEN 24 AND 49  THEN 'small bulk'
        WHEN total_quantity BETWEEN 50 AND 99  THEN 'med bulk'
        WHEN total_quantity BETWEEN 100 AND 500  THEN 'large bulk'
        ELSE 'huge bulk'
      END AS quantity_label
    FROM
      shopify.order_line ol
      LEFT JOIN shopify."ORDER" o ON o.id = ol.order_id
      LEFT JOIN shopify.order_discount_code d ON o.id = d.order_id
    WHERE
      o.created_at > '2023-03-31'
      AND o.created_at < '2023-08-31'
    GROUP BY
      o.id,
      o.created_at,
      d.code,
      d.type
    HAVING
      SUM(quantity) >= 24
    ORDER BY
      created_at desc
  )
SELECT
  o.id order_id,
  b.order_month,
  ol.id,
  ol.name,
  ol.quantity sku_quantity,
  b.code promo_code,
  b.type promo_type,
  b.quantity_label
FROM shopify.order_line ol
LEFT JOIN shopify."ORDER" o ON o.id = ol.order_id
INNER JOIN cte_bulk_orders b ON o.id = b.order_id