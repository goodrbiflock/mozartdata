SELECT
  o.order_id_edw,
  o.order_id_ns,
  oi.order_item_id,
  oi.product_id_edw,
  oi.item_id_ns,
  oi.sku,
  oi.plain_name,
  oi.quantity_booked,
  oi.quantity_sold,
  oi.quantity_fulfilled,
  oi.amount_booked,
  oi.amount_sold,
  oi.amount_fulfilled,
  p.family,
  p.stage,
  p.collection,
  p.merchandise_class,
  p.merchandise_department,
  p.merchandise_division
FROM
  fact.orders o
  LEFT JOIN fact.order_item oi ON o.order_id_edw = oi.order_id_edw
  LEFT JOIN dim.product p ON p.product_id_edw = oi.product_id_edw
WHERE
  o.channel = 'Global'