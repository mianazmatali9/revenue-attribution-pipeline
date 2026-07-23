-- Fail if the attributed-revenue fact does not have exactly one row per source
-- revenue record. Guards against a join that quietly fans out (the classic
-- many-rows-per-user revenue trap).

with fct as (
    select count(*) as fct_rows from {{ ref('fct_attributed_revenue') }}
),

src as (
    select count(*) as src_rows from {{ ref('stg_portfolio_revenue') }}
)

select fct.fct_rows, src.src_rows
from fct cross join src
where fct.fct_rows <> src.src_rows
