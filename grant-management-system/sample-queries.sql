-- Sample Analytical Queries — Grant Management System
--
-- These queries run against SQL views that sit on top of the normalized
-- fact table hierarchy. The views handle all multi-table JOINs, so
-- analytical queries are clean single-table SELECTs.
--
-- In the application, these are built using a composable Query builder
-- with a ColRef DSL for type-safe column references. The raw SQL below
-- shows the equivalent output.


-- ============================================================
-- 1. FUNDING FUNNEL — Status breakdown
-- ============================================================
-- How many records are in each pipeline stage?
-- Used by the dashboard funding funnel chart.

SELECT
    COALESCE(var.status, 'unknown') AS status,
    COUNT(*) AS count
FROM view_actionable_records var
GROUP BY var.status;


-- ============================================================
-- 2. PORTFOLIO CONCENTRATION — Top funders by dollar volume
-- ============================================================
-- Which funders represent the largest share of requested funding?
-- Answers the "are we over-reliant on a few funders?" question.

SELECT
    COALESCE(var.org_name, 'Unknown') AS org_name,
    var.org_id AS bernie_id,
    COALESCE(SUM(var.amount_requested), 0) AS requested,
    COALESCE(SUM(var.amount_awarded), 0) AS awarded,
    COUNT(*) AS record_count
FROM view_actionable_records var
GROUP BY var.org_id, var.org_name
ORDER BY requested DESC
LIMIT 15;


-- ============================================================
-- 3. WIN RATE — Year-over-year requested vs awarded
-- ============================================================
-- Track proposal success rates across fiscal years.
-- Compares total dollars requested against total awarded.

SELECT
    vr.fiscal_year,
    COALESCE(SUM(vr.amount_requested), 0) AS requested,
    COALESCE(SUM(vr.amount_awarded), 0) AS awarded,
    COUNT(*) AS record_count,
    CASE
        WHEN SUM(vr.amount_requested) > 0
        THEN ROUND(SUM(vr.amount_awarded) * 100.0 / SUM(vr.amount_requested), 1)
        ELSE 0
    END AS win_rate_pct
FROM view_records vr
WHERE vr.fiscal_year IS NOT NULL
GROUP BY vr.fiscal_year
ORDER BY vr.fiscal_year;


-- ============================================================
-- 4. STAFF WORKLOAD — Deadline distribution by team member
-- ============================================================
-- Pre-computed view showing urgency buckets per staff member.
-- Used by the team workload heatmap.

SELECT
    vsw.staff_name,
    vsw.role,
    vsw.overdue_count,
    vsw.urgent_count,
    vsw.soon_count,
    vsw.scheduled_count,
    vsw.unscheduled_count,
    COALESCE(vsw.total_requested, 0) AS total_requested,
    COALESCE(vsw.total_awarded, 0) AS total_awarded
FROM view_staff_workload vsw
WHERE vsw.is_active = 1
ORDER BY vsw.overdue_count DESC, vsw.urgent_count DESC;


-- ============================================================
-- 5. DEADLINE HEATMAP — Upcoming deadlines bucketed by week
-- ============================================================
-- Groups deadlines into weekly buckets for the next 12 weeks.
-- Week 0 captures overdue items. Shows both count and dollar volume.

SELECT
    CASE
        WHEN var.deadline < DATE('now') THEN 'Overdue'
        ELSE 'Week ' || CAST(
            (JULIANDAY(var.deadline) - JULIANDAY(DATE('now'))) / 7 + 1
            AS INTEGER)
    END AS week_label,
    COUNT(*) AS record_count,
    COALESCE(SUM(var.amount_requested), 0) AS total_requested
FROM view_actionable_records var
WHERE var.deadline IS NOT NULL
  AND (var.deadline < DATE('now')
       OR var.deadline < DATE('now', '+84 days'))
GROUP BY week_label
ORDER BY MIN(var.deadline);


-- ============================================================
-- 6. TASK AGING — Age distribution of active records
-- ============================================================
-- Buckets records by how far away their deadline is.
-- Useful for identifying items that need immediate attention.

SELECT
    CASE
        WHEN var.deadline IS NULL THEN 'No Deadline'
        WHEN var.deadline < DATE('now') THEN 'Overdue'
        WHEN var.deadline < DATE('now', '+7 days') THEN 'This Week'
        WHEN var.deadline < DATE('now', '+14 days') THEN 'Next Week'
        WHEN var.deadline < DATE('now', '+30 days') THEN '2-4 Weeks'
        WHEN var.deadline < DATE('now', '+90 days') THEN '1-3 Months'
        ELSE '3+ Months'
    END AS age_bucket,
    COUNT(*) AS record_count
FROM view_actionable_records var
GROUP BY age_bucket
ORDER BY
    CASE age_bucket
        WHEN 'Overdue' THEN 1
        WHEN 'This Week' THEN 2
        WHEN 'Next Week' THEN 3
        WHEN '2-4 Weeks' THEN 4
        WHEN '1-3 Months' THEN 5
        WHEN '3+ Months' THEN 6
        WHEN 'No Deadline' THEN 7
    END;


-- ============================================================
-- 7. FUNDING BY PROGRAM — Dollar amounts by program area
-- ============================================================
-- Joins through fact_programs to show which programs
-- attract the most funding. Uses the programs reference table.

SELECT
    rp.name AS program_name,
    COALESCE(SUM(var.amount_requested), 0) AS requested,
    COALESCE(SUM(var.amount_awarded), 0) AS awarded,
    COUNT(*) AS record_count
FROM view_actionable_records var
JOIN fact_programs fp ON fp.fact_record_id = var.fact_record_id
JOIN programs rp ON rp.program_id = fp.program_id
GROUP BY rp.program_id, rp.name
ORDER BY requested DESC;


-- ============================================================
-- 8. FUNDER TIMELINE — Year-over-year for a single funder
-- ============================================================
-- Shows funding history with a specific organization.
-- Replace the bernie_id value with the target funder.

SELECT
    vr.fiscal_year,
    COUNT(*) AS record_count,
    COALESCE(SUM(vr.amount_requested), 0) AS requested,
    COALESCE(SUM(vr.amount_awarded), 0) AS awarded
FROM view_records vr
WHERE vr.org_id = 'FUNDER_ID_HERE'
  AND vr.fiscal_year IS NOT NULL
GROUP BY vr.fiscal_year
ORDER BY vr.fiscal_year;


-- ============================================================
-- 9. FULL-TEXT SEARCH — Search across extracted document text
-- ============================================================
-- FTS5 index enables fast full-text search across 23,000+ documents.
-- Porter tokenizer handles stemming; unicode61 handles accented chars.

SELECT
    p.relative_path,
    d.file_extension,
    snippet(doc_text_fts, 0, '<b>', '</b>', '...', 32) AS match_snippet
FROM doc_text_fts
JOIN paths p ON p.id = doc_text_fts.path_id
LEFT JOIN documents d ON d.path_id = p.id
WHERE doc_text_fts MATCH 'workforce development'
ORDER BY rank
LIMIT 20;


-- ============================================================
-- 10. OPPORTUNITY SUMMARY — Aggregated view of grant opportunities
-- ============================================================
-- Each opportunity groups related source records (proposals, reports,
-- notes) from different systems into a single analytical unit.

SELECT
    vos.name,
    vos.closure_state,
    vos.primary_org_name,
    vos.record_count,
    vos.total_requested,
    vos.total_awarded,
    vos.earliest_deadline,
    vos.latest_deadline
FROM view_opportunity_summary vos
WHERE vos.closure_state = 'active'
ORDER BY vos.earliest_deadline ASC NULLS LAST;
