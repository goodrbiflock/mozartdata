WITH
  cte_gltrans AS (
    SELECT
      channel,
      sum(net_amount) AS gl_net_amount,
      transaction_date AS gl_transaction_date,
      order_id_edw
    FROM
      fact.gl_transaction
    WHERE
      account_number = 4000 ---only product sales
      AND posting_flag = 'true'
      AND transaction_date >= '2024-01-01'
      AND transaction_date < '2024-02-01'
    GROUP BY
      order_id_edw,
      channel,
      transaction_date
  ),
  cte_orders AS (
    SELECT
      channel,
      order_id_edw,
      amount_sold AS orders_amount_sold, ---assuming does not include shipping
      sold_date AS orders_sold_date
    FROM
      fact.orders
    WHERE
      sold_date >= '2024-01-01'
      AND sold_date < '2024-02-01'
  ),
  cte_order_item AS (
    SELECT
      o.channel,
      oi.order_id_edw,
      sum(oi.amount_sold) AS orderitem_amount_sold,
      o.sold_date AS orderitem_sold_date
    FROM
      fact.order_item oi
      left join fact.orders o on o.order_id_edw = oi.order_id_edw
    WHERE
      sold_date >= '2024-01-01'
      AND sold_date < '2024-02-01'
  group by 
    1, 2, 4
  )
SELECT
  cte_gltrans.*,
  cte_orders.orders_amount_sold,
  cte_orders.orders_sold_date,
  cte_order_item.orderitem_amount_sold
FROM
  cte_gltrans
  LEFT JOIN cte_orders ON cte_gltrans.order_id_edw = cte_orders.order_id_edw
  LEFT JOIN cte_order_item ON cte_gltrans.order_id_edw = cte_order_item.order_id_edw
ORDER BY
  order_id_edw