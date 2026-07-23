-- dim_company — the four portfolio companies with their reference attributes.
select * from (
    values
        ('CTC-001', 'GreenLeaf Landscaping', 'Home Services', 120),
        ('CTC-002', 'BrightPath Education',  'Education',     85),
        ('CTC-003', 'QuickFix Auto Repair',  'Automotive',    210),
        ('CTC-004', 'Summit Dental Group',   'Healthcare',    165)
) as t(company_id, company_name, industry, avg_revenue_per_user_benchmark)
