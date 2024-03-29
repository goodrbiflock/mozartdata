SELECT
  oi.*,
  o.customer_id_edw,
  o.booked_date,
  p.family,
  p.collection,
  p.merchandise_class,
  p.d2c_launch_date,
  p.b2b_launch_date,
  c.customer_id_ns,
  c.company_name
FROM
  fact.order_item oi
  LEFT JOIN fact.orders o ON o.order_id_edw = oi.order_id_edw
  LEFT JOIN dim.product p on p.product_id_edw = oi.product_id_edw
  LEFT JOIN fact.customer_ns_map c ON o.customer_id_edw = c.customer_id_edw
WHERE
  o.booked_date BETWEEN '2023-01-01' AND '2024-01-01'
  AND o.channel = 'Key Account'
  AND oi.order_id_edw LIKE 'PB%'