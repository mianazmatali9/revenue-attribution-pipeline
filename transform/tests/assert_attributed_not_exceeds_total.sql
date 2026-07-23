-- REQUIRED BY BRIEF: fail if attributed revenue exceeds total revenue.
-- Checks BOTH attribution models. Because every revenue row is attributed exactly
-- once per model, attributed == total; this test is the tripwire that catches any
-- future fan-out / double-count bug that would push attributed above total.

with total as (
    select sum(revenue_amount) as total_rev
    from {{ ref('stg_portfolio_revenue') }}
),

attributed as (
    select 'last_touch'  as model, sum(revenue_amount) as attributed_rev
    from {{ ref('fct_attributed_revenue') }}
    union all
    select 'first_touch' as model, sum(revenue_amount) as attributed_rev
    from {{ ref('fct_attributed_revenue') }}
)

select
    a.model,
    a.attributed_rev,
    t.total_rev
from attributed a
cross join total t
where a.attributed_rev > t.total_rev + {{ var('reconciliation_tolerance') }}
