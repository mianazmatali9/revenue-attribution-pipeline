-- dim_channel — the acquisition channels, with display names and a paid/owned flag.
-- youtube..blog are paid/owned content channels (they carry campaign spend and
-- content); organic + referral appear only in signups (no spend, no content) — which
-- is why CAC is undefined for them.
select * from (
    values
        ('youtube',    'YouTube',      'content', true),
        ('twitter',    'Twitter/X',    'content', true),
        ('instagram',  'Instagram',    'content', true),
        ('newsletter', 'Newsletter',   'content', true),
        ('podcast',    'Podcast',      'content', true),
        ('blog',       'Blog',         'content', true),
        ('organic',    'Organic',      'earned',  false),
        ('referral',   'Referral',     'earned',  false)
) as t(channel, channel_display_name, channel_type, is_paid_content_channel)
