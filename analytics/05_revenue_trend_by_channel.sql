-- Q5a. REVENUE TREND — month-over-month revenue by channel (last-touch), with MoM
--      growth % and a 3-month trailing average (the smoothing that feeds the forecast).
--
-- Read with the truncation caveat: revenue ramps to a ~$242K/mo plateau through
-- 2025-05, then runs off because signups stop at 2025-06 (no new acquisition in the
-- dataset). The decline after mid-2025 is a data-window artifact, not churn.

with monthly as (
    select
        last_touch_channel  as channel,
        revenue_month,
        sum(revenue_amount) as revenue
    from main_marts.fct_attributed_revenue
    group by 1, 2
),

with_trend as (
    select
        channel,
        revenue_month,
        revenue,
        lag(revenue) over (partition by channel order by revenue_month) as prev_month_revenue,
        round(avg(revenue) over (
            partition by channel order by revenue_month
            rows between 2 preceding and current row
        ), 2) as trailing_3mo_avg
    from monthly
)

select
    channel,
    strftime(revenue_month, '%Y-%m') as month,
    round(revenue, 2)                as revenue,
    round(100.0 * (revenue - prev_month_revenue)
          / nullif(prev_month_revenue, 0), 1) as mom_growth_pct,
    trailing_3mo_avg
from with_trend
order by channel, revenue_month;
