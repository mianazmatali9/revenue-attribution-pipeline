-- Signup master: one row per user. This is where the messy attribution lives.
-- We surface every quality issue as a boolean flag rather than dropping rows;
-- int_user_attribution turns these flags into a single attribution_quality label.

with source as (
    select * from {{ source('raw', 'raw_user_signups') }}
)

select
    user_id,
    cast(signup_date as date)                        as signup_date,
    date_trunc('month', cast(signup_date as date))   as signup_month,
    company_id,

    lower(trim(first_touch_channel))                 as first_touch_channel,
    lower(trim(last_touch_channel))                  as last_touch_channel,
    first_touch_content_id,
    last_touch_content_id,

    utm_source,
    utm_medium,
    utm_campaign,
    referral_source,

    -- ---- data-quality flags (carried end-to-end) --------------------------
    (lower(trim(last_touch_channel)) = 'organic')        as is_organic,
    (utm_source is not null)                             as has_utm_source,
    (utm_campaign is not null)                           as has_utm_campaign,
    (lower(trim(first_touch_channel))
        <> lower(trim(last_touch_channel)))             as is_touch_conflict,
    -- NULL utm_source on a non-organic user = genuine tracking loss
    (utm_source is null
        and lower(trim(last_touch_channel)) <> 'organic') as is_utm_tracking_loss,
    -- referral_source present but neither touch is 'referral' = contradictory signal
    (referral_source is not null
        and lower(trim(first_touch_channel)) <> 'referral'
        and lower(trim(last_touch_channel)) <> 'referral') as has_referral_mismatch
from source
