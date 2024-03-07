/* According to Klaviyo's attribution model on 3/7/2024, the last email which was Clicked or Opened within 4 days prior to placing an order, is attributed to the campaign*/
with orders as
(
  SELECT
    ke.event_timestamp as order_timestamp
  , ke.event_date as order_date
  , ke.event_id_klaviyo
  , ke.order_id_shopify
  , ke.profile_id_klaviyo
  , ke.total_amount
  FROM
    fact.klaviyo_events ke
  WHERE
    ke.metric_name = 'Placed Order'  
)
,  emails as
(
  SELECT
    ke.profile_id_klaviyo
  , ke.event_timestamp
  , ke.event_date
  , ke.event_id_klaviyo
  , ke.metric_name
  , ke.campaign_id_klaviyo
  , c.name as campaign_name
  , ke.flow_id_klaviyo
  , f.name as flow_name
  FROM
    fact.klaviyo_events ke
  LEFT JOIN
    dim.klaviyo_campaigns c
    on ke.campaign_id_klaviyo = c.campaign_id_klaviyo
  LEFT JOIN
    dim.klaviyo_flows f
    on ke.flow_id_klaviyo = f.flow_id_klaviyo
  WHERE
    ke.metric_name in ('Clicked Email','Opened Email') 
)
, attribution as
(
  SELECT
    o.*
  , e.event_timestamp
  , e.campaign_id_klaviyo
  , e.campaign_name
  , e.flow_id_klaviyo
  , e.flow_name
  , e.metric_name
  , datediff(day,e.event_timestamp,o.order_timestamp) day_diff
  , row_number() over(partition by o.order_id_shopify order by e.event_timestamp desc) rn
  FROM
    orders o
  LEFT JOIN
    emails e
    ON o.profile_id_klaviyo = e.profile_id_klaviyo
    AND e.event_timestamp < o.order_timestamp
    AND datediff(day,e.event_timestamp,o.order_timestamp) <=4
)
SELECT
  a.campaign_id_klaviyo
, a.campaign_name
, a.flow_id_klaviyo
, a.flow_name
, count(distinct a.order_id_shopify) order_count
, count(distinct a.profile_id_klaviyo) profile_count
, sum(a.total_amount) total_amount
FROM
  attribution a
WHERE
  a.rn = 1
group by
  a.campaign_id_klaviyo
, a.campaign_name
, a.flow_id_klaviyo
, a.flow_name
ORDER BY
  a.campaign_name
, a.flow_name