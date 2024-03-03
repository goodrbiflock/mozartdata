WITH
  first_pass AS (
    SELECT DISTINCT
      order_id_ns,
      transaction_id_ns,
      record_type
    FROM
      staging.order_item_detail
  )
  -- ,
  -- if_dupes AS ( --Selecting all the IF dupes for tracking related checks
  --   SELECT
  --     first_pass.order_id_ns,
  --     transaction_id_ns
  --   FROM
  --     first_pass
  --     LEFT OUTER JOIN staging.order_item_detail detail ON detail.order_id_ns = first_pass.order_id_ns
  --   WHERE
  --     itemfulfillment_count > 1
  -- )
,
  inv_dupes AS ( --Selecting all the Inv dupes for quantity related checks
    SELECT
      first_pass.order_id_ns,
      first_pass.transaction_id_ns,
      SUM(
        CASE
          WHEN plain_name NOT IN ('Shipping', 'Tax') THEN total_quantity
          ELSE 0
        END
      ) invoice_qty,
      CASE
        WHEN invoice_qty = 0 THEN TRUE
        ELSE FALSE
      END AS dupe_flag
    FROM
      first_pass
      LEFT OUTER JOIN staging.order_item_detail detail ON detail.transaction_id_ns = first_pass.transaction_id_ns
    WHERE
      first_pass.record_type = 'invoice'
    GROUP BY
      first_pass.order_id_ns,
      first_pass.transaction_id_ns
  )
  -- , full_closed as (
  -- )
  --Here I'll have it select the original full list, then join with it depending on what CTE it came from and have there be a final boolean that will determine if te transaction_id_ns should be excluded
SELECT DISTINCT --Had to add a distinct as adding in the secondary CTE join made a shitload of duplicates combined with the case when, you can see this if you remove the distinct and filter for 'CS-DENVERGOV070722'
  first_pass.order_id_ns,
  first_pass.record_type,
  first_pass.transaction_id_ns,
  CASE --boolean switch that basically goes through each CTE, and if the given transaction had a true to it then display that cte's dupe flag, or else move on
    WHEN inv_dupes.dupe_flag THEN inv_dupes.dupe_flag
    ELSE FALSE
  END AS exception_flag
FROM
  first_pass
  LEFT OUTER JOIN inv_dupes ON inv_dupes.order_id_ns = first_pass.order_id_ns
ORDER BY
  order_id_ns,
  exception_flag