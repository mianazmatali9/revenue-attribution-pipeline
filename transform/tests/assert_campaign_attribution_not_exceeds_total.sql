-- Fail if campaign-attributed revenue exceeds total revenue. The split-by-N-matches
-- allocation in int_campaign_attribution must keep the sum bounded (each matched
-- user's revenue is divided across the campaigns they match, so it can total at most
-- their revenue, and unmatched users add nothing).

with campaign_attr as (
    select sum(attributed_revenue) as attributed_rev
    from {{ ref('int_campaign_attribution') }}
),

total as (
    select sum(revenue_amount) as total_rev
    from {{ ref('stg_portfolio_revenue') }}
)

select
    c.attributed_rev,
    t.total_rev
from campaign_attr c
cross join total t
where c.attributed_rev > t.total_rev + {{ var('reconciliation_tolerance') }}
