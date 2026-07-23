-- Content master: one row per content piece. channel is always known even when
-- utm_source is missing (~8% of rows), so content is always attributable to a channel.

with source as (
    select * from {{ source('raw', 'raw_content_performance') }}
)

select
    content_id,
    title,
    lower(trim(channel))                    as channel,
    cast(publish_date as date)              as publish_date,
    date_trunc('month', cast(publish_date as date)) as publish_month,
    cast(views as bigint)                   as views,
    cast(clicks as bigint)                  as clicks,
    -- guard against divide-by-zero; round to 4dp
    round(case when views > 0 then clicks * 1.0 / views else 0 end, 4) as click_through_rate,
    utm_source,
    utm_medium,
    utm_campaign,
    (utm_source is not null)                as has_utm_source
from source
