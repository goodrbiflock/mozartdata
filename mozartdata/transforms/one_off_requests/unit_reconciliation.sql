WITH SalesOrder_CTE AS (
  SELECT order_id_edw, full_quantity AS salesorder_quantity
  FROM fact.order_item_detail
  WHERE recordtype = 'salesorder'
),
CashSale_CTE AS (
  SELECT order_id_edw, full_quantity AS cashsale_quantity
  FROM fact.order_item_detail
  WHERE recordtype = 'cashsale'
),
ItemFulfillment_CTE AS (
  SELECT order_id_edw, full_quantity AS itemfulfillment_quantity
  FROM fact.order_item_detail
  WHERE recordtype = 'itemfulfillment'
)

SELECT DISTINCT s.order_id_edw,
  salesorder_quantity,
  cashsale_quantity,
  itemfulfillment_quantity
FROM SalesOrder_CTE s
JOIN CashSale_CTE c ON s.order_id_edw = c.order_id_edw
JOIN ItemFulfillment_CTE i ON s.order_id_edw = i.order_id_edw
WHERE s.salesorder_quantity <> c.cashsale_quantity
  OR s.salesorder_quantity <> i.itemfulfillment_quantity
  OR c.cashsale_quantity <> i.itemfulfillment_quantity;