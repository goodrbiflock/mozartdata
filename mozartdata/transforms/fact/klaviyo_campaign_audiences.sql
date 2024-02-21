with excluded as 
  (
SELECT
  c.campaign_id as campaign_id_klaviyo
, ex.value::varchar audience_id
, 'excluded' as type
FROM
  klaviyo_portable.klaviyo_v2_campaigns_8589937320 c,
LATERAL FLATTEN(input => c.audiences:EXCLUDED) ex
),
included as 
(
SELECT
  c.campaign_id as campaign_id_klaviyo
, inc.value::varchar audience_id
, 'included' as type
FROM
  klaviyo_portable.klaviyo_v2_campaigns_8589937320 c,
LATERAL FLATTEN(input => c.audiences:INCLUDED) inc
),
combined as
(
SELECT
  *
FROM
  excluded
UNION ALL
SELECT
  *
FROM
  included  
)
SELECT
  campaign_id_klaviyo
, audience_id
, type
, l.list_id
, s.segment_id
FROM
  combined c
LEFT JOIN
  klaviyo_portable.klaviyo_v2_lists_8589937320 l
  on audience_id = l.list_id
LEFT JOIN
  klaviyo_portable.klaviyo_v2_segments_8589937320 s
  on audience_id = s.segment_id


-- select * from klaviyo_portable.klaviyo_v2_segments_8589937320 where segment_id=  'UUpVX8'