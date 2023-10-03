SELECT DISTINCT
  tran.custbody_goodr_shopify_order order_num,
  COUNT(
    DISTINCT CASE
      WHEN tran.recordtype = 'salesorder' THEN tran.id
    END
  ) AS so_count,
  COUNT(
    DISTINCT CASE
      WHEN tran.recordtype = 'itemfulfillment' THEN tran.id
    END
  ) AS if_count,
  COUNT(
    DISTINCT CASE
      WHEN tran.recordtype = 'cashsale' THEN tran.id
    END
  ) AS cs_count,
  COUNT(
    DISTINCT CASE
      WHEN tran.recordtype = 'invoice' THEN tran.id
    END
  ) AS inv_count,
  COUNT(
    DISTINCT CASE
      WHEN tran.recordtype = 'cashrefund' THEN tran.id
    END
  ) AS cr_count
FROM
  netsuite.transaction tran
WHERE
  cseg7 = 10
  AND createddate >= '2023-09-20T00:00:00Z'
GROUP BY
  order_num
HAVING
  so_count > 1
  OR if_count > 1
  OR cs_count > 1
  OR inv_count > 1
  OR cr_count > 1
UNION ALL
SELECT
  tran.custbody_goodr_shopify_order order_num,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL
FROM
  netsuite.transaction tran
WHERE
  cseg7 = 10
  AND createddate >= '2023-09-20T00:00:00Z'
  AND order_num NOT LIKE '%CS-%'
AND order_num NOT LIKE '%SD-%'
AND order_num NOT LIKE '%CI-%'
AND order_num NOT LIKE '%DON-%'