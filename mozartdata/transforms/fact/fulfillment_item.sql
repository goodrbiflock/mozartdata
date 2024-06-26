
WITH ss_qty AS (SELECT fulfillment_id_edw,
					   order_id_edw,
					   sku,
					   ITEM_ID,
					   SUM(quantity) total_quantity
				FROM fact.fulfillment_item_detail
				WHERE source = 'Shipstation'
				GROUP BY fulfillment_id_edw,
						 order_id_edw,
						 sku,
						 ITEM_ID),
	 stord_qty AS (SELECT fulfillment_id_edw,
						  order_id_edw,
						  sku,
						  ITEM_ID,
						  SUM(quantity) total_quantity
				   FROM fact.fulfillment_item_detail
				   WHERE source = 'Stord'
				   GROUP BY fulfillment_id_edw,
							order_id_edw,
							sku,
							ITEM_ID),
	 netsuite_qty AS (SELECT fulfillment_id_edw,
							 order_id_edw,
							 sku,
							 ITEM_ID,
							 SUM(quantity) total_quantity
					  FROM fact.fulfillment_item_detail
					  WHERE source = 'Netsuite'
					  GROUP BY fulfillment_id_edw,
							   order_id_edw,
							   sku,
							   ITEM_ID)
SELECT DISTINCT detail.fulfillment_id_edw,
				detail.order_id_edw,
				detail.sku,
				CONCAT(detail.fulfillment_id_edw, '_', detail.order_id_edw) AS fulfillment_item_id,
				ss_qty.total_quantity                                       AS quantity_ss,
				stord_qty.total_quantity                                    AS quantity_stord,
				netsuite_qty.total_quantity                                 AS quantity_ns
FROM fact.FULFILLMENT_ITEM_DETAIL detail
		 LEFT OUTER JOIN ss_qty ON (ss_qty.fulfillment_id_edw = detail.FULFILLMENT_ID_EDW AND ss_qty.sku = detail.sku)
		 LEFT OUTER JOIN stord_qty
						 ON (stord_qty.fulfillment_id_edw = detail.FULFILLMENT_ID_EDW AND stord_qty.sku = detail.sku)
		 LEFT OUTER JOIN netsuite_qty ON (netsuite_qty.fulfillment_id_edw = detail.FULFILLMENT_ID_EDW AND
										  netsuite_qty.sku = detail.sku)




