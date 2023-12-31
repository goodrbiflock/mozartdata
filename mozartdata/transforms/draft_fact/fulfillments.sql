--Idea for this is to replicate the logic we already have in place for SS->NS that makes it so that we'll have one shipment per row, 
SELECT
  shipments.ordernumber AS order_num,
  shipments.shipmentid ss_shipmentid,
  shipments.servicecode,
  shipments.shipmentcost,
  shipments.createdate,
  SUM(flattened.value:QUANTITY::INTEGER) over (partition by ss_shipmentid) AS quantity_listed,
  -- SUM(
  --   CASE
  --     WHEN tranline.itemtype = 'InvtPart'
  --     AND tranline.custcol1 IS NOT NULL THEN tranline.quantity * -1
  --     ELSE 0
  --   END
  -- ) over (
  --   PARTITION BY
  --     ss_shipmentid
  -- ) AS if_qty,
  shipments.voided AS void_flag
FROM
  shipstation_portable.shipstation_shipments_8589936627 shipments
  LEFT OUTER JOIN netsuite.transaction tran ON tran.custbody_shipment_id = shipments.shipmentid
  -- LEFT OUTER JOIN netsuite.transactionline tranline ON tranline.transaction = tran.id
  LEFT OUTER JOIN shipstation_portable.shipstation_shipment_items_8589936627 ship_item ON ship_item.shipmentid = shipments.shipmentid,
  LATERAL FLATTEN(input => ship_item.shipmentitems) AS flattened
WHERE
  shipments.createdate >= '2022-01-01T00:00:00Z'
  AND order_num = 'G1863077'