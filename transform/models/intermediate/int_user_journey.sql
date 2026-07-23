-- int_user_journey — the stitched user record: attribution + revenue in one row.
-- One row per user. This is the "user-journey stitching" model: it joins signup
-- attribution to the user's realised revenue so downstream marts can attribute
-- revenue to a channel without re-deriving the logic.
--
-- A LEFT join from attribution -> revenue would keep users with zero revenue; every
-- user here has revenue (referential integrity confirmed 0 orphans, and every user
-- has >=1 revenue row), but we LEFT join defensively and coalesce to 0.

with attribution as (
    select * from {{ ref('int_user_attribution') }}
),

revenue as (
    select * from {{ ref('int_user_revenue') }}
)

select
    a.user_id,
    a.company_id,
    a.signup_date,
    a.signup_month,

    a.first_touch_channel,
    a.last_touch_channel,
    a.attribution_quality,
    a.is_touch_conflict,
    a.is_campaign_tag_trustworthy,
    a.utm_campaign,

    r.revenue_type,
    coalesce(r.active_months, 0)        as active_months,
    r.first_revenue_month,
    r.last_revenue_month,
    coalesce(r.total_revenue, 0)        as total_revenue,
    coalesce(r.avg_monthly_revenue, 0)  as avg_monthly_revenue,
    (r.user_id is not null)             as has_revenue
from attribution a
left join revenue r on a.user_id = r.user_id
