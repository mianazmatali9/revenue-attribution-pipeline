-- Campaign master: one row per campaign. Budget = the spend we measure ROI against.
-- The campaign's OWN channel + target_company are trustworthy (unlike the user's
-- utm_campaign tag), so downstream campaign attribution keys off these.

with source as (
    select * from {{ source('raw', 'raw_campaign_metadata') }}
)

select
    campaign_id,
    campaign_name,
    lower(trim(channel))            as channel,
    target_company                  as company_id,
    cast(budget as integer)         as budget,
    cast(start_date as date)        as start_date,
    cast(end_date as date)          as end_date,
    utm_campaign
from source
