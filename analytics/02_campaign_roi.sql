-- Q2. CAMPAIGN ROI — spend vs attributed revenue per campaign, ranked by efficiency.
--
-- Double-count guard (see int_campaign_attribution): a user's revenue is split across
-- every campaign whose channel + company + active window match them, so no dollar is
-- counted twice and budgets are never duplicated by recurring revenue.
--
-- Honesty note: attributed revenue here only covers users who matched a campaign's
-- window/channel/company. The final row shows how much of total revenue that is — most
-- revenue can't be tied to a specific campaign, so campaign-level ROI is directional.

select
    campaign_id,
    campaign_name,
    channel,
    company_id,
    budget,
    attributed_users,
    attributed_revenue,
    roi_ratio,                       -- attributed revenue earned per $1 of budget
    net_return                       -- attributed_revenue - budget
from main_marts.fct_campaign_roi
order by roi_ratio desc;

-- Coverage check: what share of total revenue is attributable to ANY campaign?
select
    round(sum(attributed_revenue), 2)                                  as revenue_tied_to_campaigns,
    (select round(sum(revenue_amount), 2) from main_marts.fct_attributed_revenue) as total_revenue,
    round(100.0 * sum(attributed_revenue)
          / (select sum(revenue_amount) from main_marts.fct_attributed_revenue), 1) as pct_covered,
    sum(budget)                                                        as total_spend
from main_marts.fct_campaign_roi;
