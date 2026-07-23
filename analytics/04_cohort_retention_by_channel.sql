-- Q4. COHORT RETENTION BY CHANNEL — do users acquired via different channels retain
--     revenue differently?
--
-- Method: assign each user to their signup-month cohort and acquisition channel
-- (last-touch), then measure the share still generating revenue N months after signup.
-- retention_rate = active_users(month N) / cohort_users(month 0).
--
-- FINDING (and a limitation): retention is essentially flat across channels — the
-- lever is which channel brings MORE customers, not "better" ones. Also note
-- truncation: users who signed up late can't yet be observed at high month_index, so
-- later columns understate retention. Read the early months (0-6) with most confidence.

with rev as (
    select
        last_touch_channel as channel,
        user_id,
        date_diff('month', signup_month, revenue_month) as month_index
    from main_marts.fct_attributed_revenue
),

cohort_size as (
    select channel, count(distinct user_id) as cohort_users
    from rev
    where month_index = 0
    group by 1
),

active as (
    select channel, month_index, count(distinct user_id) as active_users
    from rev
    group by 1, 2
)

select
    a.channel,
    a.month_index,
    c.cohort_users,
    a.active_users,
    round(a.active_users * 1.0 / c.cohort_users, 3) as retention_rate
from active a
join cohort_size c using (channel)
where a.month_index between 0 and 12
order by a.channel, a.month_index;
