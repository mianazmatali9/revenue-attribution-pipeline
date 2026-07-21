#!/usr/bin/env python3
"""
generate_data.py — Deterministic synthetic data generator for
Option C: Cross-Portfolio Revenue Attribution & Forecasting Pipeline.

Produces four seeded source files under ./data:
  - content_performance.csv   (~1,370 rows)
  - user_signups.json         (~6,170 users)
  - portfolio_revenue.csv     (~27,070 rows)
  - campaign_metadata.csv     (30 rows)

The data is intentionally messy, matching the documented quality characteristics:
  - ~8%  of content rows have missing utm_source
  - ~12% of users have a missing UTM source
  - ~15% of users have missing campaign UTMs
  - some users have conflicting first_touch vs last_touch channel
  - some users have a referral_source that contradicts their UTM data
  - revenue spans multiple months per user (recurring vs one-time)

Referential integrity is preserved: every user_id in portfolio_revenue exists in
user_signups, every content_id referenced in signups exists in content_performance,
and every target_company / company_id is one of the four portfolio companies.

Run:  python generate_data.py
Deterministic: same seed -> byte-identical output.
"""

import csv
import json
import os
import random
from datetime import date, timedelta

SEED = 42
random.seed(SEED)

OUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "data")
os.makedirs(OUT_DIR, exist_ok=True)

# --------------------------------------------------------------------------- #
# Reference dimensions
# --------------------------------------------------------------------------- #
COMPANIES = [
    {"company_id": "CTC-001", "name": "GreenLeaf Landscaping", "industry": "Home Services", "avg_rev": 120},
    {"company_id": "CTC-002", "name": "BrightPath Education",  "industry": "Education",      "avg_rev": 85},
    {"company_id": "CTC-003", "name": "QuickFix Auto Repair",  "industry": "Automotive",     "avg_rev": 210},
    {"company_id": "CTC-004", "name": "Summit Dental Group",   "industry": "Healthcare",     "avg_rev": 165},
]
COMPANY_IDS = [c["company_id"] for c in COMPANIES]

# Content channels (paid/owned media). organic + referral only appear in signups.
CONTENT_CHANNELS = ["youtube", "twitter", "instagram", "newsletter", "podcast", "blog"]
SIGNUP_CHANNELS = CONTENT_CHANNELS + ["organic", "referral"]

# Weighted channel picker for signups: organic ~9%, referral ~9%, rest split the remainder.
SIGNUP_CHANNEL_WEIGHTS = {
    "youtube": 0.19, "twitter": 0.13, "instagram": 0.16,
    "newsletter": 0.12, "podcast": 0.11, "blog": 0.11,
    "organic": 0.09, "referral": 0.09,
}


def pick_signup_channel():
    r = random.random()
    cum = 0.0
    for ch, w in SIGNUP_CHANNEL_WEIGHTS.items():
        cum += w
        if r <= cum:
            return ch
    return "blog"

# channel -> (utm_source, utm_medium)
CHANNEL_UTM = {
    "youtube":    ("youtube",    "video"),
    "twitter":    ("twitter",    "social"),
    "instagram":  ("instagram",  "social"),
    "newsletter": ("newsletter", "email"),
    "podcast":    ("podcast",    "audio"),
    "blog":       ("blog",       "content"),
    "organic":    (None,         "organic"),
    "referral":   ("referral",   "referral"),
}

REFERRAL_SOURCES = ["partner_site", "friend_invite", "affiliate", "reddit", "hacker_news", "product_hunt"]

START = date(2024, 1, 1)
END = date(2025, 6, 30)
REV_END = date(2026, 6, 30)  # revenue may continue past the signup window


def rand_date(start=START, end=END):
    delta = (end - start).days
    return start + timedelta(days=random.randint(0, delta))


def month_str(d):
    return d.strftime("%Y-%m")


# --------------------------------------------------------------------------- #
# 1) Campaign metadata (30 rows)
# --------------------------------------------------------------------------- #
def gen_campaigns():
    campaigns = []
    for i in range(1, 31):
        channel = random.choice(CONTENT_CHANNELS)
        company = random.choice(COMPANY_IDS)
        start = rand_date(START, date(2025, 3, 1))
        end = start + timedelta(days=random.randint(21, 120))
        budget = random.choice([2500, 5000, 7500, 10000, 15000, 20000, 30000])
        campaigns.append({
            "campaign_id": f"CMP-{i:03d}",
            "campaign_name": f"{channel}_{company.lower().replace('-', '')}_{start.strftime('%b%Y').lower()}",
            "channel": channel,
            "target_company": company,
            "budget": budget,
            "start_date": start.isoformat(),
            "end_date": end.isoformat(),
            "utm_campaign": f"cmp_{i:03d}",
        })
    return campaigns


# --------------------------------------------------------------------------- #
# 2) Content performance (~1,370 rows)
# --------------------------------------------------------------------------- #
def gen_content(campaigns):
    n = 1370
    rows = []
    camp_by_channel = {}
    for c in campaigns:
        camp_by_channel.setdefault(c["channel"], []).append(c["utm_campaign"])

    for i in range(1, n + 1):
        channel = random.choice(CONTENT_CHANNELS)
        src, medium = CHANNEL_UTM[channel]
        publish = rand_date()
        # engagement scales loosely by channel
        base_views = {
            "youtube": 45000, "twitter": 12000, "instagram": 22000,
            "newsletter": 8000, "podcast": 15000, "blog": 6000,
        }[channel]
        views = max(50, int(random.gauss(base_views, base_views * 0.6)))
        ctr = random.uniform(0.008, 0.06)
        clicks = int(views * ctr)

        utm_source = src
        # ~8% of content rows: missing utm_source
        if random.random() < 0.08:
            utm_source = ""

        utm_campaign = ""
        if channel in camp_by_channel and random.random() < 0.55:
            utm_campaign = random.choice(camp_by_channel[channel])

        rows.append({
            "content_id": f"CNT-{i:05d}",
            "title": f"{channel.capitalize()} piece #{i}",
            "channel": channel,
            "publish_date": publish.isoformat(),
            "views": views,
            "clicks": clicks,
            "utm_source": utm_source,
            "utm_medium": medium,
            "utm_campaign": utm_campaign,
        })
    return rows


# --------------------------------------------------------------------------- #
# 3) User signups (~6,170) with messy attribution
# --------------------------------------------------------------------------- #
def gen_users(content_rows, campaigns):
    n = 6170
    users = []
    content_by_channel = {}
    for r in content_rows:
        content_by_channel.setdefault(r["channel"], []).append(r["content_id"])
    camp_ids = [c["utm_campaign"] for c in campaigns]

    for i in range(1, n + 1):
        signup = rand_date(date(2024, 1, 1), date(2025, 6, 1))
        company = random.choice(COMPANY_IDS)

        first_touch = pick_signup_channel()
        # ~30% of users get a genuinely different last-touch channel (conflict)
        if random.random() < 0.30:
            last_touch = random.choice([c for c in SIGNUP_CHANNELS if c != first_touch])
        else:
            last_touch = first_touch

        src, medium = CHANNEL_UTM[last_touch]
        utm_source = src            # organic is naturally None
        utm_medium = medium

        # ~12% of users overall missing utm_source: organic (~9%) is naturally null;
        # force-drop on a small slice of the rest to represent tracking loss.
        if utm_source is not None and random.random() < 0.025:
            utm_source = None

        # Assign a campaign to (almost) every user, then null ~15% -> "missing campaign UTM".
        utm_campaign = random.choice(camp_ids)
        if random.random() < 0.15:
            utm_campaign = ""

        # referral_source: set for referral users; occasionally set (and mismatched) for others
        referral_source = None
        if last_touch == "referral" or first_touch == "referral":
            referral_source = random.choice(REFERRAL_SOURCES)
        elif random.random() < 0.06:
            # deliberate mismatch: referral_source present but UTM says a different channel
            referral_source = random.choice(REFERRAL_SOURCES)

        # content links, when the touch is a content channel
        first_content = (random.choice(content_by_channel[first_touch])
                         if first_touch in content_by_channel else None)
        last_content = (random.choice(content_by_channel[last_touch])
                        if last_touch in content_by_channel else None)

        users.append({
            "user_id": f"USR-{i:06d}",
            "signup_date": signup.isoformat(),
            "company_id": company,
            "first_touch_channel": first_touch,
            "last_touch_channel": last_touch,
            "first_touch_content_id": first_content,
            "last_touch_content_id": last_content,
            "utm_source": utm_source,
            "utm_medium": utm_medium,
            "utm_campaign": utm_campaign if utm_campaign else None,
            "referral_source": referral_source,
        })
    return users


# --------------------------------------------------------------------------- #
# 4) Portfolio revenue (~27,070 rows) — recurring vs one-time
# --------------------------------------------------------------------------- #
def gen_revenue(users):
    rows = []
    avg_by_company = {c["company_id"]: c["avg_rev"] for c in COMPANIES}

    for u in users:
        company = u["company_id"]
        base = avg_by_company[company]
        signup = date.fromisoformat(u["signup_date"])
        start_month = signup.replace(day=1)

        # ~40% one-time, ~60% recurring
        if random.random() < 0.40:
            n_months = 1
            rev_type = "one_time"
        else:
            rev_type = "recurring"
            # months drawn to average ~7 among recurring, capped to data window
            n_months = max(2, min(20, int(random.expovariate(1 / 5.5)) + 2))

        m = start_month
        for _ in range(n_months):
            if m > REV_END.replace(day=1):
                break
            amount = round(max(5.0, random.gauss(base, base * 0.25)), 2)
            rows.append({
                "user_id": u["user_id"],
                "company_id": company,
                "revenue_month": month_str(m),
                "revenue_amount": amount,
                "revenue_type": rev_type,
            })
            # advance one month
            if m.month == 12:
                m = m.replace(year=m.year + 1, month=1)
            else:
                m = m.replace(month=m.month + 1)
    return rows


# --------------------------------------------------------------------------- #
# Writers
# --------------------------------------------------------------------------- #
def write_csv(path, rows, fields):
    with open(path, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fields)
        w.writeheader()
        for r in rows:
            w.writerow(r)


def main():
    campaigns = gen_campaigns()
    content = gen_content(campaigns)
    users = gen_users(content, campaigns)
    revenue = gen_revenue(users)

    write_csv(os.path.join(OUT_DIR, "campaign_metadata.csv"), campaigns,
              ["campaign_id", "campaign_name", "channel", "target_company",
               "budget", "start_date", "end_date", "utm_campaign"])

    write_csv(os.path.join(OUT_DIR, "content_performance.csv"), content,
              ["content_id", "title", "channel", "publish_date", "views",
               "clicks", "utm_source", "utm_medium", "utm_campaign"])

    with open(os.path.join(OUT_DIR, "user_signups.json"), "w") as f:
        json.dump(users, f, indent=2)

    write_csv(os.path.join(OUT_DIR, "portfolio_revenue.csv"), revenue,
              ["user_id", "company_id", "revenue_month", "revenue_amount", "revenue_type"])

    # ---- report ----
    miss_content_src = sum(1 for r in content if not r["utm_source"]) / len(content)
    miss_user_src = sum(1 for u in users if not u["utm_source"]) / len(users)
    miss_user_camp = sum(1 for u in users if not u["utm_campaign"]) / len(users)
    conflict = sum(1 for u in users if u["first_touch_channel"] != u["last_touch_channel"]) / len(users)
    recurring = sum(1 for r in revenue if r["revenue_type"] == "recurring")

    print("Generated (seed={}):".format(SEED))
    print(f"  campaign_metadata.csv : {len(campaigns):>6} rows")
    print(f"  content_performance.csv: {len(content):>6} rows  (missing utm_source: {miss_content_src:.1%})")
    print(f"  user_signups.json      : {len(users):>6} users (missing utm_source: {miss_user_src:.1%}, "
          f"missing utm_campaign: {miss_user_camp:.1%}, first/last conflict: {conflict:.1%})")
    print(f"  portfolio_revenue.csv  : {len(revenue):>6} rows  (recurring rows: {recurring})")
    total_rev = sum(r["revenue_amount"] for r in revenue)
    print(f"  total revenue          : ${total_rev:,.2f}")


if __name__ == "__main__":
    main()
