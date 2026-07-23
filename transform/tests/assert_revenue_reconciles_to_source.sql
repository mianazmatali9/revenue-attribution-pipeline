-- Fail if the attributed-revenue fact does not reconcile to the raw source total,
-- to the penny. This is the "numbers are true" guarantee: enrichment must not add,
-- drop, or duplicate a single dollar.

with fct as (
    select sum(revenue_amount) as fct_total
    from {{ ref('fct_attributed_revenue') }}
),

src as (
    select sum(revenue_amount) as src_total
    from {{ ref('stg_portfolio_revenue') }}
)

select
    fct.fct_total,
    src.src_total,
    round(fct.fct_total - src.src_total, 2) as difference
from fct
cross join src
where abs(fct.fct_total - src.src_total) > {{ var('reconciliation_tolerance') }}
