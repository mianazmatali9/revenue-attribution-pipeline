-- dim_user_cohort — one row per user, assigning them to a signup-month cohort and
-- their acquisition channel. Grain = user, so cohort-retention queries can group by
-- cohort_month x channel and count how many users are still generating revenue N
-- months after signup.

with journey as (
    select * from {{ ref('int_user_journey') }}
)

select
    user_id,
    company_id,
    signup_date,
    signup_month                    as cohort_month,
    last_touch_channel              as acquisition_channel_last_touch,
    first_touch_channel             as acquisition_channel_first_touch,
    attribution_quality,
    revenue_type,
    active_months,
    first_revenue_month,
    last_revenue_month,
    total_revenue
from journey
