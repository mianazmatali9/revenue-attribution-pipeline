-- Revenue master: one row per user-month. This is the grain that everything must
-- reconcile to — sum(revenue_amount) here is the single source of truth for total
-- revenue ($4,011,694.74). Attribution enriches these rows; it never multiplies them.

with source as (
    select * from {{ source('raw', 'raw_portfolio_revenue') }}
)

select
    -- surrogate key: exactly one revenue row per user per month
    md5(user_id || '|' || revenue_month)                as revenue_id,
    user_id,
    company_id,
    revenue_month                                       as revenue_month_str,
    cast(revenue_month || '-01' as date)                as revenue_month,
    cast(revenue_amount as double)                      as revenue_amount,
    lower(trim(revenue_type))                           as revenue_type
from source
