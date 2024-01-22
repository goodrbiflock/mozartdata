WITH
  line_amount AS (
    SELECT
      gt.transaction_id_ns,
      SUM(gt.net_amount) net_amount
    FROM
      fact.gl_transaction gt
    WHERE
      gt.account_number BETWEEN 4000 AND 4999
    GROUP BY
      gt.transaction_id_ns
  ),
  parent_transaction AS (
    SELECT DISTINCT
      order_id_edw,
      FIRST_VALUE(transaction_id_ns) OVER (
        PARTITION BY
          order_id_edw
        ORDER BY
          CASE
            WHEN record_type = 'salesorder'
            AND createdfrom IS NULL THEN 1
            WHEN record_type IN ('cashsale', 'invoice')
            AND createdfrom IS NULL THEN 2
            ELSE 3
          END,
          transaction_created_timestamp_pst ASC
      ) AS parent_id
    FROM
      fact.order_item_detail
  )
SELECT DISTINCT
  CONCAT(
    item_detail.order_id_edw,
    '_',
    item_detail.transaction_id_ns
  ) AS order_line_id,
  item_detail.order_id_edw,
  item_detail.transaction_id_ns,
  tran.tranid AS transaction_number_ns,
  item_detail.full_status AS transaction_status_ns,
  item_detail.record_type,
  channel.name AS channel,
  tran.saleschannel AS inventory_bucket,
  entity AS customer_id_ns,
  customer.email,
  CASE
    WHEN item_detail.record_type = 'cashrefund' THEN TRUE
    ELSE FALSE
  END AS has_refund,
  CASE
    WHEN memo LIKE '%RMA%' THEN TRUE
    ELSE FALSE
  END AS is_exchange,
  item_detail.transaction_created_timestamp_pst,
  DATE(tran.trandate) AS transaction_date,
  CASE
    WHEN item_detail.full_status LIKE ANY(
      '%Closed',
      '%Voided',
      '%Undefined',
      '%Rejected',
      '%Unapproved',
      '%Not Deposited'
    ) THEN TRUE
    ELSE FALSE
  END AS status_flag_edw,
  DATE(tran.startdate) AS shipping_window_start_date,
  DATE(tran.enddate) AS shipping_window_end_date,
  item_detail.createdfrom AS parent_transaction_id,
  TRY_TO_NUMBER(tran.custbody_boomi_orderid) shopify_id,
  CASE
    WHEN parent_id IS NOT NULL THEN TRUE
    ELSE FALSE
  END AS parent_transaction,
  SUM(
    CASE
      WHEN item_detail.item_type != 'InvtPart' THEN 0
      ELSE item_detail.total_quantity
    END
  ) over (
    PARTITION BY
      item_detail.order_id_edw,
      item_detail.transaction_id_ns
  ) order_line_quantity,
  la.net_amount AS order_line_amount,
  number.trackingnumber tracking_number,
  FIRST_VALUE(item_detail.location IGNORE NULLS) over (
    PARTITION BY
      item_detail.order_id_edw,
      item_detail.transaction_id_ns
    ORDER BY
      item_detail.product_id_edw
  ) location
FROM
  fact.order_item_detail item_detail
  LEFT OUTER JOIN parent_transaction ON item_detail.transaction_id_ns = parent_transaction.parent_id
  LEFT OUTER JOIN netsuite.transaction tran ON tran.id = item_detail.transaction_id_ns
  LEFT OUTER JOIN dim.channel channel ON channel.channel_id_ns = tran.cseg7
  LEFT OUTER JOIN netsuite.customer customer ON customer.id = tran.entity
  LEFT OUTER JOIN netsuite.trackingnumbermap map ON map.transaction = item_detail.transaction_id_ns
  LEFT OUTER JOIN netsuite.trackingnumber number ON number.id = map.trackingnumber
  LEFT OUTER JOIN line_amount la ON item_detail.transaction_id_ns = la.transaction_id_ns
WHERE
  item_detail.record_type IN (
    'cashsale',
    'itemfulfillment',
    'salesorder',
    'cashrefund',
    'invoice'
  )