-- fct_content_performance — content output & engagement by channel x month.
-- Grain = channel x publish_month. This is the "supply" side (what we published)
-- that the attribution facts explain the "demand" side (what it earned).

with content as (
    select * from {{ ref('stg_content_performance') }}
)

select
    channel,
    publish_month,
    count(*)                                    as content_pieces,
    sum(views)                                  as total_views,
    sum(clicks)                                 as total_clicks,
    round(avg(click_through_rate), 4)           as avg_click_through_rate,
    round(sum(clicks) * 1.0
          / nullif(sum(views), 0), 4)           as blended_click_through_rate,
    count(*) filter (where not has_utm_source)  as pieces_missing_utm_source
from content
group by channel, publish_month
