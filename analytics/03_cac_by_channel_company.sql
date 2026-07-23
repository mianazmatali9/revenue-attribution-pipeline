-- Q3. CUSTOMER ACQUISITION COST (CAC) — by channel, per company.
--
-- CAC = campaign spend on a channel/company / customers acquired via that channel
-- (last-touch) for that company. Only the six paid content channels carry spend, so
-- CAC is UNDEFINED for organic & referral (no budget) — we show them with NULL CAC
-- rather than hiding them, because "free" acquisition is itself a finding.
-- revenue_per_customer lets you compare CAC against value.

with acquired as (
    select
        last_touch_channel                as channel,
        company_id,
        count(distinct user_id)           as customers_acquired,
        round(sum(revenue_amount), 2)     as attributed_revenue
    from main_marts.fct_attributed_revenue
    group by 1, 2
),

spend as (
    select channel, company_id, sum(budget) as total_spend
    from main_staging.stg_campaign_metadata
    group by 1, 2
)

select
    a.company_id,
    a.channel,
    a.customers_acquired,
    s.total_spend,
    case when s.total_spend is not null and a.customers_acquired > 0
         then round(s.total_spend * 1.0 / a.customers_acquired, 2)
    end                                                            as cac,
    round(a.attributed_revenue / a.customers_acquired, 2)         as revenue_per_customer,
    case when s.total_spend > 0
         then round(a.attributed_revenue / s.total_spend, 2)
    end                                                            as revenue_per_dollar_spent
from acquired a
left join spend s on a.channel = s.channel and a.company_id = s.company_id
order by a.company_id, cac nulls last;
