WITH
  order_ids AS ( --all order_id_ns's and their requisite transaction_id_ns's for dual usage later on (parent logic and child logic)
    SELECT
      order_id_ns,
      transaction_id_ns,
      record_type,
      transaction_created_timestamp_pst,
      MAX(createdfrom) createdfrom
    FROM
      staging.order_item_detail
    GROUP BY
      order_id_ns,
      transaction_id_ns,
      record_type,
      transaction_created_timestamp_pst
  ),
  parent_ranking AS (--parent ranking for just the orders type transactions
    SELECT
      order_id_ns,
      transaction_id_ns,
      createdfrom,
      record_type,
      ROW_NUMBER() OVER (
        PARTITION BY
          order_id_ns
        ORDER BY
          CASE record_type
            WHEN 'salesorder' THEN 1
            WHEN 'cashsale' THEN 2
            WHEN 'invoice' THEN 2
            ELSE 3
          END,
          transaction_created_timestamp_pst
      ) AS RANK
    FROM
      order_ids
    WHERE
      (record_type in ('salesorder','purchaseorder'))
      OR (
        (
          record_type = 'cashsale'
          OR record_type = 'invoice'
        )
        AND createdfrom IS NULL
      )
  ),
  
  parent_type AS ( --quickly select the rank 1, so the most applicable parent's type for later sorting
    SELECT
      order_id_ns,
      record_type AS parent_type
    FROM
      parent_ranking
    WHERE
      RANK = 1
  ),
  final_ranking AS ( --finally rerank everything only for the transaction types that are the same as the rank 1 that was previously gotten, this is to prevent there for example being multiple parents with different record types like in SO1746720
    SELECT
      parent_ranking.order_id_ns,
      parent_ranking.transaction_id_ns,
      parent_ranking.record_type,
      createdfrom,
      ROW_NUMBER() OVER (
        PARTITION BY
          parent_ranking.order_id_ns
        ORDER BY
          parent_ranking.transaction_id_ns
      ) AS label,--used to generate the #1,#2, etc later on, basically ranking 
      parent_type
    FROM
      parent_ranking
      LEFT OUTER JOIN parent_type ON parent_type.order_id_ns = parent_ranking.order_id_ns
    WHERE
      record_type = parent_type or record_type ='purchaseorder'
  ),
  transaction_tree AS (
    -- Anchor member: Select initial transactions that are parents (present in final_ranking)
    SELECT
      final_ranking.order_id_ns,
      COUNT(*) OVER (
        PARTITION BY
          order_id_ns
      ) AS occurence,
      final_ranking.transaction_id_ns,
      final_ranking.createdfrom,
      ARRAY_CONSTRUCT(transaction_id_ns) AS path,
      label AS parent_label,
      order_id_ns || '#' || label AS labeled_order_id_ns,
      0 AS depth -- Initialize the path array with the transaction_id
    FROM
      final_ranking
    UNION ALL
    -- Recursive member: Join to find child transactions
    SELECT
      order_ids_2.order_id_ns,
      tt.occurence,
      order_ids_2.transaction_id_ns,
      order_ids_2.createdfrom,
      ARRAY_APPEND(tt.path, order_ids_2.transaction_id_ns),
      tt.parent_label,
      tt.labeled_order_id_ns,
      tt.depth + 1 AS depth
    FROM
      order_ids order_ids_2
      JOIN transaction_tree tt ON order_ids_2.createdfrom = tt.transaction_id_ns
    WHERE
      record_type != 'purchaseorder'
  ),
  counter AS ( --cte thats gonna be used later for the complicated parent->children->grandchildren trees
    SELECT
      order_id_ns,
      ARRAY_AGG(path) AS transaction_paths,
      COUNT_IF(depth = 0) AS parent_count, -- Count parents
      COUNT_IF(depth = 1) AS child_count, -- Count children
      COUNT_IF(depth = 2) AS grandchild_count, -- Count grandchildren
      COUNT_IF(depth = 3) AS great_grandchildren_count -- Count grandchildren
    FROM
      transaction_tree
    GROUP BY
      order_id_ns,
      parent_label
  )
SELECT
  CASE
    WHEN occurence > 1 THEN labeled_order_id_ns
    ELSE transaction_tree.order_id_ns
  END AS order_id_edw,
  transaction_tree.order_id_ns,
  CASE
    WHEN depth = 0 THEN TRUE
    ELSE FALSE
  END AS is_parent,
  transaction_tree.transaction_id_ns,
  record_type
FROM
  transaction_tree
  LEFT OUTER JOIN order_ids ON order_ids.transaction_id_ns = transaction_tree.transaction_id_ns
ORDER BY
  transaction_tree.order_id_ns