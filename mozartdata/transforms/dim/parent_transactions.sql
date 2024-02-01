WITH
  distinct_order_lines AS ( --sanitize the data to just transaction level information from order_item_detail for later ranking
    SELECT DISTINCT
      order_id_edw,
      transaction_id_ns,
      transaction_created_timestamp_pst,
      record_type,
      createdfrom
    FROM
      staging.order_item_detail
  ),
  first_select AS ( --first select the applicable records based on the where clause then rank them based on transaction type
    SELECT
      order_id_edw,
      record_type,
      transaction_id_ns,
      transaction_created_timestamp_pst,
      ROW_NUMBER() OVER (
        PARTITION BY
          order_id_edw
        ORDER BY
          CASE record_type
            WHEN 'salesorder' THEN 1
            WHEN 'cashsale' THEN 2
            WHEN 'invoice' THEN 2
            WHEN 'purchaseorder' THEN 3
            ELSE 4
          END,
          transaction_created_timestamp_pst
      ) AS RANK
    FROM
      distinct_order_lines
    WHERE
      (record_type = 'salesorder')
      OR (
        (
          record_type = 'cashsale'
          OR record_type = 'invoice'
        )
        AND createdfrom IS NULL
      )
      OR (record_type = 'purchaseorder')
  ),
  parent_type AS ( --quickly select the rank 1, so the most applicable parent's type for later sorting
    SELECT
      order_id_edw,
      record_type AS parent_type
    FROM
      first_select
    WHERE
      RANK = 1
  ),
  final_ranking AS ( --finally rerank everything only for the transaction types that are the same as the rank 1 that was previously gotten, this is to prevent there for example being multiple parents with different record types like in SO1746720
    SELECT
      first_select.order_id_edw,
      parent_type,
      first_select.record_type,
      first_select.transaction_id_ns,
      ROW_NUMBER() OVER (
        PARTITION BY
          first_select.order_id_edw
        ORDER BY
          transaction_created_timestamp_pst
      ) AS final_rank,
      COUNT(*) OVER (
        PARTITION BY
          first_select.order_id_edw
      ) AS cnt
    FROM
      first_select
      LEFT OUTER JOIN parent_type ON parent_type.order_id_edw = first_select.order_id_edw
    WHERE
      record_type = parent_type
  ),
  parents_ids AS (
    SELECT --finally concatenate the ones with a count>1 in the previous lists and give them new order_id_edw's with a # in them
      fr.order_id_edw,
      fr.record_type AS parent_record_type,
      fr.transaction_id_ns AS parent_id,
      fr.record_type,
      CASE
        WHEN MAX(
          CASE
            WHEN fr.record_type = 'salesorder' THEN 1
            ELSE 0
          END
        ) OVER (
          PARTITION BY
            fr.order_id_edw
        ) = 1
        AND cnt > 1 THEN CONCAT(fr.order_id_edw, '#', final_rank)
        WHEN MAX(
          CASE
            WHEN fr.record_type IN ('cashsale', 'invoice') THEN 1
            ELSE 0
          END
        ) OVER (
          PARTITION BY
            fr.order_id_edw
        ) = 1
        AND cnt > 1 THEN CONCAT(fr.order_id_edw, '#', final_rank)
        WHEN MAX(fr.record_type = 'purchaseorder') OVER (
          PARTITION BY
            fr.order_id_edw
        ) = 1
        AND cnt > 1 THEN CONCAT(fr.order_id_edw, '#', final_rank)
        ELSE fr.order_id_edw
      END AS custom_id
    FROM
      final_ranking fr
  ),
  distinct_order AS (
    SELECT DISTINCT
      transaction_id_ns,
      createdfrom,
      record_type
    FROM
      staging.order_item_detail
  ),
  children AS (
    SELECT
      fr.order_id_edw,
      fr.record_type AS parent_record_type,
      fr.parent_id AS parent_id,
      od.transaction_id_ns,
      od.record_type,
      fr.custom_id
    FROM
      parents_ids fr
      LEFT JOIN distinct_order od ON (fr.parent_id = od.createdfrom)
  ),
  parents AS (
    SELECT
      fr.order_id_edw,
      fr.record_type AS parent_record_type,
      fr.parent_id AS parent_id,
      od.transaction_id_ns,
      od.record_type,
      fr.custom_id
    FROM
      parents_ids fr
      LEFT JOIN distinct_order od ON (fr.parent_id = od.transaction_id_ns)
  )
SELECT
  *
FROM
  children
UNION ALL
SELECT
  *
FROM
  parents