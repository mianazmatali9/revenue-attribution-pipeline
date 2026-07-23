-- int_campaign_attribution — links users to the specific campaign(s) that could
-- plausibly have driven them, WITHOUT trusting the unreliable utm_campaign tag.
--
-- Match rule (defensible): a campaign gets credit for a user only when
--   (1) the campaign's channel = the user's last-touch channel, AND
--   (2) the campaign targets the user's company, AND
--   (3) the user signed up within the campaign's active window.
--
-- DOUBLE-COUNT GUARD: if a user matches N campaigns (overlapping windows), their
-- revenue is split 1/N across them, so summing attributed_revenue over all campaigns
-- never exceeds the matched users' revenue. Users matching no campaign are simply not
-- attributed to any campaign (reported separately as "unattributable" spend coverage),
-- rather than being force-fit — that honesty is the point.

with journey as (
    select
        user_id,
        company_id,
        last_touch_channel,
        signup_date,
        total_revenue
    from {{ ref('int_user_journey') }}
),

campaigns as (
    select
        campaign_id,
        campaign_name,
        channel,
        company_id,
        budget,
        start_date,
        end_date
    from {{ ref('stg_campaign_metadata') }}
),

matches as (
    select
        j.user_id,
        j.total_revenue,
        c.campaign_id,
        c.campaign_name,
        c.channel,
        c.company_id,
        count(*) over (partition by j.user_id) as n_campaign_matches
    from journey j
    join campaigns c
        on  c.channel     = j.last_touch_channel
        and c.company_id  = j.company_id
        and j.signup_date between c.start_date and c.end_date
)

select
    user_id,
    campaign_id,
    campaign_name,
    channel,
    company_id,
    n_campaign_matches,
    total_revenue,
    -- split evenly across the campaigns a user matches
    round(total_revenue / n_campaign_matches, 4) as attributed_revenue
from matches
