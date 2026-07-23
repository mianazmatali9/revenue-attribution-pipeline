-- fct_campaign_roi — spend vs attributed revenue per campaign. Grain = campaign.
--
-- Spend and revenue are aggregated SEPARATELY then joined, so the recurring-revenue
-- fan-out can't duplicate the budget. Attributed revenue comes from
-- int_campaign_attribution (window + channel + company match, split across ties),
-- NOT the unreliable utm_campaign tag.
--
-- roi_ratio = attributed_revenue / budget (revenue earned per $1 of spend).
-- Campaigns with 0 matched users show 0 attributed revenue — that is a real finding
-- (the campaign's window/channel/company didn't line up with paying users), not a bug.

with campaigns as (
    select * from {{ ref('stg_campaign_metadata') }}
),

attributed as (
    select
        campaign_id,
        count(distinct user_id)         as attributed_users,
        round(sum(attributed_revenue), 2) as attributed_revenue
    from {{ ref('int_campaign_attribution') }}
    group by campaign_id
)

select
    c.campaign_id,
    c.campaign_name,
    c.channel,
    c.company_id,
    c.budget,
    c.start_date,
    c.end_date,
    coalesce(a.attributed_users, 0)      as attributed_users,
    coalesce(a.attributed_revenue, 0)    as attributed_revenue,
    round(coalesce(a.attributed_revenue, 0) / nullif(c.budget, 0), 3) as roi_ratio,
    round((coalesce(a.attributed_revenue, 0) - c.budget), 2)         as net_return
from campaigns c
left join attributed a on c.campaign_id = a.campaign_id
