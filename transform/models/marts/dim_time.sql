-- dim_time — a continuous month spine spanning the revenue window (no gaps),
-- so trend/forecast queries have a row for every month even if a channel had none.

with bounds as (
    select
        min(revenue_month) as min_month,
        max(revenue_month) as max_month
    from {{ ref('stg_portfolio_revenue') }}
),

spine as (
    select unnest(generate_series(
        (select min_month from bounds),
        (select max_month from bounds),
        interval '1 month'
    )) as month_ts
)

select
    cast(month_ts as date)                as month_date,
    strftime(month_ts, '%Y-%m')           as month_str,
    year(month_ts)                        as year,
    month(month_ts)                       as month_num,
    quarter(month_ts)                     as quarter,
    year(month_ts) || '-Q' || quarter(month_ts) as year_quarter
from spine
order by month_date
