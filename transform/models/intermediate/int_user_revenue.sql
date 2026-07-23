-- int_user_revenue — one row per user, summarising their revenue.
-- revenue_type is constant per user in the source (a user is either one-time or
-- recurring), so it collapses cleanly to the user grain. Used for reconciliation,
-- CAC (customers = users with revenue) and cohort retention.

with revenue as (
    select * from {{ ref('stg_portfolio_revenue') }}
)

select
    user_id,
    company_id,
    min(revenue_type)               as revenue_type,      -- constant per user
    count(*)                        as active_months,
    min(revenue_month)              as first_revenue_month,
    max(revenue_month)              as last_revenue_month,
    round(sum(revenue_amount), 2)   as total_revenue,
    round(avg(revenue_amount), 2)   as avg_monthly_revenue
from revenue
group by user_id, company_id
