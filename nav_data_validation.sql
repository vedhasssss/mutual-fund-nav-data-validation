-- ============================================================
-- Mutual Fund NAV Data Validation (MySQL)
-- Data: sample of AMFI's public daily NAV file (nav_data_small.csv)
-- Goal: find bad records using SQL checks and log the reason for each
-- ============================================================


-- ------------------------------------------------------------
-- 1. SETUP: create database and raw table
-- ------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS nav_project;
USE nav_project;

DROP TABLE IF EXISTS nav_raw;
CREATE TABLE nav_raw (
  scheme_code        INT,
  isin_payout_growth VARCHAR(30),
  isin_reinvestment  VARCHAR(30),
  scheme_name        VARCHAR(255),
  plan               VARCHAR(100),
  option_type        VARCHAR(150),   -- some values are long, so a wide column is needed
  nav                DECIMAL(15,4),
  nav_date           VARCHAR(20)     -- loaded as text first, converted to a real date below
);

-- Now import nav_data_small.csv into nav_raw
-- (MySQL Workbench: right-click nav_raw > Table Data Import Wizard)


-- ------------------------------------------------------------
-- 2. LOAD CHECK: confirm the import worked
-- ------------------------------------------------------------
SELECT COUNT(*) AS rows_loaded FROM nav_raw;        -- expected: 2470
SELECT nav_date FROM nav_raw LIMIT 5;               -- look at the date format


-- ------------------------------------------------------------
-- 3. DATE FIX: convert the text date into a proper DATE column
-- ------------------------------------------------------------
SET SQL_SAFE_UPDATES = 0;
ALTER TABLE nav_raw ADD COLUMN nav_date_clean DATE;
UPDATE nav_raw SET nav_date_clean = STR_TO_DATE(nav_date, '%Y-%m-%d');

SELECT COUNT(*) AS bad_dates FROM nav_raw WHERE nav_date_clean IS NULL;  -- expected: 0


-- ------------------------------------------------------------
-- 4. ISSUES TABLE: stores every flagged record with its reason
-- ------------------------------------------------------------
DROP TABLE IF EXISTS data_issues;
CREATE TABLE data_issues (
  scheme_code INT,
  scheme_name VARCHAR(255),
  nav         DECIMAL(15,4),
  nav_date    DATE,
  reason      VARCHAR(50)
);


-- ------------------------------------------------------------
-- 5. VALIDATION CHECKS (run each once)
-- ------------------------------------------------------------

-- Check 1: NAV is zero or negative (a NAV should always be positive)
INSERT INTO data_issues
SELECT scheme_code, scheme_name, nav, nav_date_clean, 'NAV zero or negative'
FROM nav_raw
WHERE nav <= 0;

-- Check 2: ISIN is missing (empty, NULL or '-')
INSERT INTO data_issues
SELECT scheme_code, scheme_name, nav, nav_date_clean, 'Missing ISIN'
FROM nav_raw
WHERE isin_payout_growth IS NULL OR isin_payout_growth IN ('', '-');

-- Check 3: NAV date is older than the latest date in the file (stale NAV)
INSERT INTO data_issues
SELECT scheme_code, scheme_name, nav, nav_date_clean, 'Old NAV date'
FROM nav_raw
WHERE nav_date_clean < (SELECT MAX(nav_date_clean) FROM nav_raw);

-- Check 4: plan details are missing
INSERT INTO data_issues
SELECT scheme_code, scheme_name, nav, nav_date_clean, 'Missing plan'
FROM nav_raw
WHERE plan IS NULL OR plan = '';

-- Check 5: the same ISIN appears on more than one record
INSERT INTO data_issues
SELECT scheme_code, scheme_name, nav, nav_date_clean, 'Duplicate ISIN'
FROM nav_raw
WHERE isin_payout_growth IN (
  SELECT isin_payout_growth
  FROM nav_raw
  WHERE isin_payout_growth NOT IN ('', '-')
  GROUP BY isin_payout_growth
  HAVING COUNT(*) > 1
);


-- ------------------------------------------------------------
-- 6. SUMMARY QUERIES: turn the checks into numbers
-- ------------------------------------------------------------

-- Total records checked
SELECT COUNT(*) AS records_checked FROM nav_raw;

-- Total issues logged (one record can fail more than one check)
SELECT COUNT(*) AS total_issues FROM data_issues;

-- Number of different records flagged
SELECT COUNT(DISTINCT scheme_code) AS records_flagged FROM data_issues;

-- Issues by reason, most common first
SELECT reason, COUNT(*) AS issue_count
FROM data_issues
GROUP BY reason
ORDER BY issue_count DESC;


-- ------------------------------------------------------------
-- 7. EXTRA QUERIES (practice: sorting, limiting, searching)
-- ------------------------------------------------------------

-- Top 10 highest NAVs
SELECT * FROM nav_raw ORDER BY nav DESC LIMIT 10;

-- Search funds by name
SELECT * FROM nav_raw WHERE scheme_name LIKE '%Axis%' LIMIT 10;
