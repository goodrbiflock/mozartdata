/*
questions - 
do we use loyalty or swell?
suppressions list is always null
*/
SELECT
  p.profile_id as profile_id_klayvio
, p.created as profile_created_timestamp
, date(p.created) as profile_created_date
, p.email
, p.first_name
, p.last_name
, p.title
, p.location:ADDRESS1::varchar as address_1
, p.location:ADDRESS2::varchar as address_2
, p.location:CITY::varchar as city
, p.location:REGION::varchar as region
, p.location:ZIP::varchar as zip_code
, p.location:COUNTRY::varchar as country
, p.location:TIMEZONE::varchar as timezone
, p.location:LATITUDE::varchar as latitude
, p.location:LONGITUDE::varchar as longitude
, p.phone_number
, p._organization as company
, JSON_EXTRACT_PATH_TEXT(p.properties,'"Accepts Marketing"')::boolean as accepts_marketing_flag
, JSON_EXTRACT_PATH_TEXT(p.properties,'"Expected Date Of Next Order"')::date as expected_next_order_date
, JSON_EXTRACT_PATH_TEXT(p.properties,'"First Purchase Date"')::date as first_purchase_date
, p.subscriptions:EMAIL:MARKETING:CONSENT::varchar as subscription_consent
, case when p.subscriptions:EMAIL:MARKETING:METHOD::varchar = 'EMAIL_UNSUBSCRIBE' then p.subscriptions:EMAIL:MARKETING:TIMESTAMP::datetime end as unsubscribe_timestamp
, case when p.subscriptions:EMAIL:MARKETING:METHOD::varchar = 'EMAIL_UNSUBSCRIBE' then date(p.subscriptions:EMAIL:MARKETING:TIMESTAMP::datetime) end as unsubscribe_date
, case when p.subscriptions:EMAIL:MARKETING:METHOD::varchar = 'SPAM_COMPLAINT' then p.subscriptions:EMAIL:MARKETING:TIMESTAMP::datetime end as spam_complaint_timestamp
, case when p.subscriptions:EMAIL:MARKETING:METHOD::varchar = 'SPAM_COMPLAINT' then date(p.subscriptions:EMAIL:MARKETING:TIMESTAMP::datetime) end as spam_complaint_date
, p.subscriptions:EMAIL:MARKETING:CUSTOM_METHOD_DETAIL::varchar as subscription_custom_method_detail
, p.subscriptions:EMAIL:MARKETING:DOUBLE_OPTIN::boolean as subscription_double_opt_in_flag
  -- , p.subscriptions:EMAIL:MARKETING:SUPPRESSIONS::varchar as subscription_suppression
-- , p.subscriptions:EMAIL:MARKETING:SUPPRESSIONS:REASON::varchar as subscription_suppression_reason
-- , p.subscriptions:EMAIL:MARKETING:SUPPRESSIONS:TIMESTAMP::datetime as subscription_suppression_timestamp
, p.subscriptions:EMAIL:MARKETING:LIST_SUPPRESSIONS::varchar as subscription_suppressions_list 
, p.subscriptions:EMAIL:MARKETING:METHOD::varchar as subscription_method
, p.subscriptions:EMAIL:MARKETING:METHOD_DETAIL::varchar as subscription_method_detail
, p.subscriptions:EMAIL:MARKETING:TIMESTAMP::datetime as subscription_timestamp
FROM
  klaviyo_portable.klaviyo_v2_profiles_8589937320 p
order by profile_id_klayvio