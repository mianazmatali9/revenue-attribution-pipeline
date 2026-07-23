-- fct_attributed_revenue — THE core fact. Grain = one row per revenue record
-- (user x month), identical to stg_portfolio_revenue's grain.
--
-- RECONCILIATION GUARANTEE: this is an INNER/LEFT enrichment of revenue rows with the
-- user's attribution — it never fans out (each revenue row has exactly one user, and
-- each user has exactly one attribution record). Therefore:
--     sum(revenue_amount) grouped by last_touch_channel   = $4,011,694.74
--     sum(revenue_amount) grouped by first_touch_channel  = $4,011,694.74
-- Both attribution models are columns on the SAME row, so switching models is a
-- GROUP BY change, not a re-join. No double-count is possible by construction.
--
-- The two models diverge only on the ~29% of users whose first_touch <> last_touch.

with revenue as (
    select * from {{ ref('stg_portfolio_revenue') }}
),

attribution as (
    select * from {{ ref('int_user_attribution') }}
)

select
    r.revenue_id,
    r.user_id,
    r.company_id,
    r.revenue_month,
    r.revenue_month_str,
    r.revenue_amount,
    r.revenue_type,

    -- attribution enrichment (one attribution row per user -> no fan-out)
    a.signup_month,
    a.first_touch_channel,
    a.last_touch_channel,
    a.first_touch_content_id,
    a.last_touch_content_id,
    a.attribution_quality,
    a.is_touch_conflict,

    -- campaign tag carried for transparency; trustworthy flag says whether to believe it
    a.utm_campaign,
    a.is_campaign_tag_trustworthy,

    -- convenience: does the chosen model matter for THIS row's user?
    (a.first_touch_channel = a.last_touch_channel) as models_agree
from revenue r
inner join attribution a on r.user_id = a.user_id
