-- Which customer segments have the highest loan default probability, 
-- and which live applications should the credit team manually review?

CREATE DATABASE loan_default_risk_raw;

USE loan_default_risk_raw;

CREATE TABLE loan_applications_raw (
    application_id VARCHAR(20),
    customer_id VARCHAR(20),
    application_date VARCHAR(30),
    disbursement_date VARCHAR(30),
    loan_type VARCHAR(50),
    loan_amount VARCHAR(20),
    tenure_months VARCHAR(10),
    interest_rate_pct VARCHAR(10),
    monthly_income VARCHAR(30),
    employment_type VARCHAR(30),
    employment_years VARCHAR(10),
    cibil_score VARCHAR(10),
    city VARCHAR(50),
    state VARCHAR(50),
    city_tier VARCHAR(20),
    existing_loans_count VARCHAR(10),
    documentation_complete VARCHAR(5),
    current_dpd_bucket VARCHAR(20),
    default_flag VARCHAR(5)
);

SELECT COUNT(*) FROM loan_applications_raw;

DESCRIBE loan_applications_raw;

-- data cleaning
CREATE VIEW loan_applications_cleaned AS
SELECT DISTINCT 
TRIM(application_id) AS application_id,
TRIM(customer_id) AS customer_id,
CASE 
WHEN TRIM(application_date) LIKE '% % %' 
THEN STR_TO_DATE(TRIM(application_date), '%d %b %Y')

WHEN TRIM(application_date) LIKE '%/%/%' 
THEN STR_TO_DATE(TRIM(application_date), '%d/%m/%Y') 

WHEN TRIM(application_date) LIKE '%-%-%' 
AND LEFT(TRIM(application_date), 4) BETWEEN 2000 AND 2999
THEN STR_TO_DATE(TRIM(application_date), '%Y-%m-%d')

WHEN TRIM(application_date) LIKE '%-%-%' 
THEN STR_TO_DATE(TRIM(application_date), '%d-%m-%Y')

ELSE NULL
END AS application_date,
CASE 
WHEN TRIM(disbursement_date) LIKE '% % %' 
THEN STR_TO_DATE(TRIM(disbursement_date), '%d %b %Y')

WHEN TRIM(disbursement_date) LIKE '%/%/%' 
THEN STR_TO_DATE(TRIM(disbursement_date), '%d/%m/%Y') 

WHEN TRIM(disbursement_date) LIKE '%-%-%' 
AND LEFT(TRIM(disbursement_date), 4) BETWEEN 2000 AND 2999
THEN STR_TO_DATE(TRIM(disbursement_date), '%Y-%m-%d')

WHEN TRIM(disbursement_date) LIKE '%-%-%' 
THEN STR_TO_DATE(TRIM(disbursement_date), '%d-%m-%Y')

ELSE NULL
END AS disbursement_date,
UPPER(TRIM(loan_type)) AS loan_type,
CAST(TRIM(loan_amount) AS DECIMAL(10,2)) AS loan_amount,
CAST(TRIM(tenure_months) AS UNSIGNED) AS tenure_months,
CAST(TRIM(interest_rate_pct) AS DECIMAL(5,2)) AS interest_rate_pct,
CAST(REPLACE(REPLACE(TRIM(monthly_income), ',','') ,'INR', '') AS DECIMAL(10,2)) AS monthly_income,
UPPER(TRIM(employment_type)) AS employment_type,
CAST(TRIM(employment_years) AS DECIMAL(3,1)) AS employment_years,
CAST(TRIM(cibil_score) AS UNSIGNED) AS cibil_score,
UPPER(TRIM(city)) AS city, 
UPPER(TRIM(state)) AS state, 
TRIM(city_tier) AS city_tier,
CAST(TRIM(existing_loans_count) AS UNSIGNED) AS existing_loans_count,
TRIM(documentation_complete) AS documentation_complete,
TRIM(current_dpd_bucket) AS current_dpd_bucket,
CAST(TRIM(default_flag) AS UNSIGNED) AS default_flag
FROM loan_applications_raw
WHERE loan_amount IS NOT NULL
AND CAST(TRIM(loan_amount) AS DECIMAL(10,2)) > 0 
AND (cibil_score = '' OR CAST(TRIM(cibil_score) AS UNSIGNED) BETWEEN 300 AND 900)
AND application_id IS NOT NULL
AND application_id <> ''
AND CAST(TRIM(tenure_months) AS UNSIGNED) > 0;

-- added income bracket
CREATE VIEW loan_applications_improved AS
SELECT *,
CASE
WHEN monthly_income = '' THEN 'unknow'
WHEN monthly_income <= 25000 THEN 'low'
WHEN monthly_income <= 50000 THEN 'low-mid'
WHEN monthly_income <= 75000 THEN 'mid-high'
WHEN monthly_income <= 100000 THEN 'high'
ELSE 'super-high'
END AS income_bracket
FROM loan_applications_cleaned;

-- Overall portfolio default rate
SELECT sum(default_flag) AS total_defaults,
COUNT(*) AS total_applications,
ROUND(((sum(default_flag)/COUNT(*)) *100),2) AS default_rate
FROM loan_applications_improved;

-- Default rate by income bracket
SELECT sum(default_flag) AS total_defaults,
COUNT(*) AS total_applications,
ROUND(((sum(default_flag)/COUNT(*)) *100),2) AS default_rate,
income_bracket
FROM loan_applications_improved
GROUP BY income_bracket
ORDER BY default_rate DESC; 

-- Default rate by loan type
SELECT sum(default_flag) AS total_defaults,
COUNT(*) AS total_applications,
ROUND(((sum(default_flag)/COUNT(*)) *100),2) AS default_rate,
loan_type
FROM loan_applications_improved
GROUP BY loan_type
ORDER BY default_rate DESC; 

-- Default rate by employment type and employment tenure band
SELECT employment_type,
CASE
WHEN employment_years < 2 THEN 'less_than_2'
WHEN employment_years < 5 THEN 'less_than_5'
WHEN employment_years < 10 THEN 'less_than_10'
ELSE 'more_than_10'
END AS employment_tenure_band,
sum(default_flag) AS total_defaults,
COUNT(*) AS total_applications,
ROUND(((sum(default_flag)/COUNT(*)) *100),2) AS default_rate
FROM loan_applications_improved
GROUP BY employment_type, employment_tenure_band
ORDER BY  default_rate DESC; 

-- Default rate by geography
SELECT city_tier,
state,
sum(default_flag) AS total_defaults,
COUNT(*) AS total_applications,
ROUND(((sum(default_flag)/COUNT(*)) *100),2) AS default_rate
FROM loan_applications_improved
GROUP BY city_tier, state
ORDER BY default_rate desc; 

-- High-risk customer segments
SELECT 
loan_type,
employment_type,
city_tier,
income_bracket,
sum(default_flag) AS total_defaults,
COUNT(*) AS total_applications,
ROUND(((sum(default_flag)/COUNT(*)) *100),2) AS default_rate
FROM loan_applications_improved
GROUP BY loan_type, employment_type, city_tier, income_bracket
HAVING COUNT(*) > 10
ORDER BY default_rate DESC;

-- Rank income segments by default rate within each loan type
 SELECT loan_type,
 income_bracket,
 default_flag_sum,
 total_application,
 default_rate,
 RANK() OVER (PARTITION BY loan_type ORDER BY default_rate DESC) AS risk_rank_within_loan_type
FROM
 (SELECT loan_type,
 income_bracket,
 SUM(default_flag) AS default_flag_sum,
 COUNT(*) AS total_application,
 ROUND(((SUM(default_flag)/COUNT(*))*100),2) AS default_rate
 FROM loan_applications_improved
 GROUP BY loan_type,income_bracket
 HAVING COUNT(*) > 10) AS default_rate_pct;
 
 -- Applications requiring manual review
WITH risk_segment AS (
SELECT loan_type,
employment_type,
income_bracket,
city_tier,
COUNT(*) AS total_applications,
ROUND((100* (SUM(default_flag)/COUNT(*))),2) AS default_rate_pct
FROM loan_applications_improved
GROUP BY loan_type, employment_type, income_bracket, city_tier
HAVING COUNT(*) >=10 
)
SELECT i.application_id, i.customer_id, i.loan_type, i.loan_amount, i.employment_type, i.cibil_score,
i.city_tier, i.documentation_complete, i.income_bracket, r.default_rate_pct AS segment_default_rate_pct,
CASE 
WHEN i.documentation_complete = 'N' THEN 1 ELSE 0
END
+ CASE 
WHEN i.loan_amount >200000 THEN 1 ELSE 0 
END
+ CASE 
WHEN i.cibil_score < 650 THEN 1 ELSE 0 
END AS red_flag_count
FROM loan_applications_improved i
JOIN risk_segment r
ON r.loan_type = i.loan_type
AND r.employment_type = i.employment_type
AND r.income_bracket = i.income_bracket
AND r.city_tier = i.city_tier
WHERE  i.current_dpd_bucket = '0 (Current)'
AND r.default_rate_pct >= 20
AND ( i.documentation_complete = 'N'
	OR i.loan_amount >200000
    OR i.cibil_score < 650)
ORDER BY r.default_rate_pct DESC, red_flag_count DESC;

-- Default rate by disbursement month
SELECT date_format(disbursement_date, '%Y-%m') AS disbursement_month,
COUNT(*) AS total_application,
ROUND(((SUM(default_flag)/COUNT(*))*100), 2) AS default_rate_pct
FROM loan_applications_improved
WHERE disbursement_date IS NOT NULL
GROUP BY disbursement_month
ORDER BY disbursement_month;