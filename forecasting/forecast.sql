-- FORECAST — simple 3-month revenue forecast per company (trailing moving average).
--
-- Method: take each company's last observed month, compute the average of its most
-- recent 3 months of revenue, and project that flat for the next 3 months. This is
-- deliberately simple — per the brief, the forecast is not the differentiator.
--
-- Output combines the last 6 actual months with the 3 forecast months (row_type
-- distinguishes them) so the projection can be read in context.
--
-- LIMITATIONS (when this breaks down):
--   * No seasonality / trend term — a flat MA can't see turning points.
--   * TRUNCATION: this dataset stops acquiring users after 2025-06, so the most recent
--     months are a run-off of the existing book. The trailing MA therefore projects the
--     DECAY of that run-off, not a real business trajectory. In production (acquisition
--     ongoing), you'd anchor the forecast on the acquisition-active plateau (~$242K/mo
--     total) instead of the tail. Treat the numeric forecast as a mechanical baseline,
--     not a business prediction.
--   * Short history (30 months) and small per-company samples widen the error.

with monthly as (
    select company_id, revenue_month, sum(revenue_amount) as revenue
    from main_marts.fct_attributed_revenue
    group by 1, 2
),

bounds as (
    select company_id, max(revenue_month) as last_month
    from monthly
    group by 1
),

trailing_avg as (
    select m.company_id, round(avg(m.revenue), 2) as trailing_3mo_avg
    from monthly m
    join bounds b using (company_id)
    where m.revenue_month >= b.last_month - to_months(2)
    group by 1
),

recent_actuals as (
    select m.company_id, m.revenue_month, round(m.revenue, 2) as revenue, 'actual' as row_type
    from monthly m
    join bounds b using (company_id)
    where m.revenue_month >= b.last_month - to_months(5)
),

forecast as (
    select
        b.company_id,
        b.last_month + to_months(s.g) as revenue_month,
        t.trailing_3mo_avg            as revenue,
        'forecast'                    as row_type
    from bounds b
    join trailing_avg t using (company_id)
    cross join (select unnest([1, 2, 3]) as g) s
)

select
    company_id,
    strftime(revenue_month, '%Y-%m') as month,
    revenue,
    row_type
from (
    select * from recent_actuals
    union all
    select * from forecast
)
order by company_id, month;
