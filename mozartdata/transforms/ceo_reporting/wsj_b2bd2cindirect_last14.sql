SELECT
  DATE_TRUNC('DAY', timestamp_transaction_pst)::DATE AS transaction_date,
  b2b_d2c,
  COUNT(*) AS b2b_d2c_count
FROM
  dim.orders
WHERE
  DATE_TRUNC('DAY', timestamp_transaction_pst)::DATE >= CURRENT_DATE() - INTERVAL '15 DAY'
  AND DATE_TRUNC('DAY', timestamp_transaction_pst)::DATE < CURRENT_DATE()
GROUP BY
  transaction_date,
  b2b_d2c
ORDER BY
  transaction_date desc
limit 42