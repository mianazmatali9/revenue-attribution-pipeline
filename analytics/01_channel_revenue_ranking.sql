-- Q1. CHANNEL REVENUE RANKING — which channels drive the most attributed revenue,
--     under BOTH attribution models, and where the answer changes.
--
-- Story: the top 3 (YouTube, Instagram, Twitter) are stable under both models, so that
-- ranking is trustworthy. The models disagree in the mid/tail — most sharply on
-- Referral (a closing channel: big under last-touch, small under first-touch) and
-- YouTube (a discovery channel: bigger under first-touch). Both columns reconcile to
-- the same $4,011,694.74 total, so this is a pure re-allocation, not a re-count.

with last_touch as (
    select last_touch_channel as channel,
           sum(revenue_amount) as attributed_revenue,
           count(distinct user_id) as attributed_users
    from main_marts.fct_attributed_revenue
    group by 1
),

first_touch as (
    select first_touch_channel as channel,
           sum(revenue_amount) as attributed_revenue,
           count(distinct user_id) as attributed_users
    from main_marts.fct_attributed_revenue
    group by 1
)

select
    coalesce(l.channel, f.channel)                              as channel,
    round(l.attributed_revenue, 2)                             as last_touch_revenue,
    round(f.attributed_revenue, 2)                             as first_touch_revenue,
    round(l.attributed_revenue - f.attributed_revenue, 2)      as last_minus_first,
    rank() over (order by l.attributed_revenue desc)           as last_touch_rank,
    rank() over (order by f.attributed_revenue desc)           as first_touch_rank,
    round(100.0 * l.attributed_revenue
          / sum(l.attributed_revenue) over (), 1)              as pct_of_total_last_touch
from last_touch l
full outer join first_touch f using (channel)
order by last_touch_revenue desc;
