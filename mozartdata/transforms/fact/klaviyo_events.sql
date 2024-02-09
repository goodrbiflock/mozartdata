/*
conversion based on placed order
*/

SELECT
  e.datetime as event_timestamp
, date(e.datetime) as event_date
, e.metric_id as metric_id_klaviyo
, m.name as metric_name
, e.profile_id as profile_id_klaviyo
, JSON_EXTRACT_PATH_TEXT(e.event_properties,'"$message"')::varchar as campaign_id_klaviyo
, JSON_EXTRACT_PATH_TEXT(e.event_properties,'"event_id"')::varchar as order_id_shopify
, JSON_EXTRACT_PATH_TEXT(e.event_properties,'"value"')::varchar as property_value
, JSON_EXTRACT_PATH_TEXT(e.event_properties,'"total_discounts"')::varchar as property_total_discounts
, JSON_EXTRACT_PATH_TEXT(e.event_properties,'"shipping_rate"')::varchar as property_shipping_rate
, JSON_EXTRACT_PATH_TEXT(e.event_properties,'"source_name"')::varchar as property_source_name
, JSON_EXTRACT_PATH_TEXT(e.event_properties,'"item_count"')::varchar as property_item_count
FROM
  klaviyo_portable.klaviyo_v2_events_8589937320 e
LEFT JOIN
  klaviyo_portable.klaviyo_v2_metrics_8589937320 m
  on e.metric_id = m.metric_id
UNION ALL
SELECT
  to_timestamp_ntz(ke.datetime) as event_timestamp
, date(ke.datetime) as event_date
, ke.metric_id as metric_id_klaviyo
, km.name as metric_name
, ke.person_id as profile_id_klaviyo -->need to change this to a profile instead of person
, ke.campaign_id as campaign_id_klaviyo
, ke.property_event_id as order_id_shopify
, ke.property_value
, ke.property_total_discounts
, ke.property_shipping_rate
, ke.property_source_name
, ke.property_item_count
FROM
  klaviyo.event ke
LEFT JOIN
  klaviyo.metric km
  on ke.metric_id = km.id

-- where metric_name like 'Placed Order' and event_date = '2024-01-10' --3971 vs 3967

-- select name, date(e.datetime), count(distinct person_id) from klaviyo.event e inner join klaviyo.metric m on e.metric_id = m.id where  m.name in ('Placed Order') and date(e.datetime) 
-- select name, date(e.datetime), e.* from klaviyo.event e inner join klaviyo.metric m on e.metric_id = m.id where  m.name in ('Placed Order') and date(e.datetime) = '2024-01-10'
--   select * from klaviyo.campaign where id = ''

-- select * from dim.klaviyo_campaigns where campaign_id_klaviyo = '01HNX4SRSAXPT6D2SS11A4S62X'
-- select * From klaviyo_portable.klaviyo_v2_events_8589937320


-- SELECT
-- ke.*
-- FROM
--   klaviyo.event ke
--   LEFT JOIN
--   klaviyo.metric km
--     on ke.metric_id = km.id
-- where type = 'Placed Order'
-- group by 1