-- purpose:
-- One row per transaction.
-- This transform creates the transactions dimension by combining data from netsuite and shopify.
-- aliases: 
-- ns = netsuite
-- shop = shopify
-- cust = customer
with prodsales as (
select
  transaction, 
  netamount, --After discount?
  rate --Before discount?
  from 
  netsuite.transactionline where transaction = 13356008
)
-- select 
--   count(NS_transaction_ID) as countran
--   from(
SELECT
  transaction.tranid AS NS_transaction_ID,
  transaction.trandate AS ns_trandate,
  transaction.recordtype AS ns_transaction_type,
  transaction.entity AS ns_cust_id,
  transaction.id AS NS_ID,
  transactionline.netamount AS revenue,
  shopord.id AS shopify_id,
  shopord.name AS shopify_tran_id,
  channel.name AS ns_channel,
  transtatus.fullname AS ns_transaction_status,
  billaddress.state as ns_billing_state,
  shipaddress.state as ns_shipping_state
FROM
  netsuite.transaction transaction
  LEFT OUTER JOIN netsuite.customrecord_cseg7 channel ON transaction.cseg7 = channel.id
  LEFT OUTER JOIN netsuite.transactionline transactionline ON transaction.id = transactionline.transaction
  LEFT OUTER JOIN shopify."ORDER" shopord ON shopord.name = transaction.custbody_goodr_shopify_order
  LEFT OUTER JOIN netsuite.transactionstatus transtatus ON (
    transaction.status = transtatus.id
    AND transaction.type = transtatus.trantype
  )
  left outer join netsuite.transactionBillingAddress billaddress on billaddress.nkey = transaction.billingaddress
  left outer join netsuite.transactionShippingAddress shipaddress on shipaddress.nkey = transaction.shippingaddress
WHERE
  transactionline.linesequencenumber = 0 --as per joshas recc, use the 0th line for the netamount that ends up being the total
  -- and transactionline.accountinglinetype is null --leave it commented out until INV issue is resolved
  AND ns_transaction_id IS NOT NULL -- Filtering out all the seemingly null transactions we have
  -- AND ns_transaction_type IN ('salesorder', 'cashsale', 'invoice') --optional filter
ORDER BY
  ns_transaction_id desc
  -- )