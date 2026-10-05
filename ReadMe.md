# Loan Default Risk Analysis & Dashboard

## Business Question

**Which customer segments have the highest loan default risk, and which live applications should the credit team manually review?**

## Project Overview

This project analyzes a synthetic loan application dataset to identify patterns associated with loan defaults and build a data-driven manual review framework for credit risk teams.

The analysis covers customer income, employment, loan characteristics, geography, CIBIL score, documentation status, and current DPD status.

The project follows an end-to-end analytics workflow:

**Raw Data → SQL Data Cleaning → Risk Analysis → Feature Engineering → Power BI Dashboard → Manual Review Queue**

> **Dataset:** This is a synthetic dataset created for portfolio and learning purposes. It is modeled on realistic loan portfolio attributes such as income, employment, geography, loan type, CIBIL score, and repayment behavior. It does not contain real customer or company data.

---

## Tech Stack

- **MySQL** — Data cleaning, transformation, feature engineering, and risk analysis
- **Power BI** — Data modeling, DAX measures, visualization, and dashboard development
- **SQL** — Aggregation, segmentation, window functions, CTEs, joins, and conditional logic

---

## Data Cleaning & Preparation

The raw dataset contained several data-quality issues that were identified and handled using SQL.

Key cleaning steps included:

- Standardizing mixed date formats
- Removing leading/trailing spaces
- Standardizing inconsistent text casing
- Converting text-based numeric fields into appropriate numeric data types
- Cleaning currency-formatted income values
- Removing invalid or non-positive loan amounts
- Removing applications with zero tenure
- Validating CIBIL scores against the expected 300–900 range
- Handling missing values
- Standardizing loan and employment categories
- Identifying duplicate application records
- Reviewing repeated application IDs with conflicting field values
- Removing invalid records from the analytical dataset

---

## Analysis Performed

The SQL analysis was used to investigate:

- Overall portfolio default rate
- Default rate by income bracket
- Default rate by loan type
- Default rate by employment type
- Default rate by employment tenure
- Default rate by city tier and state
- High-risk customer segments
- Risk ranking of income segments within loan types
- Applications requiring manual review
- Default rate by disbursement month

---

## Key Findings

The analysis identified the following patterns in the portfolio:

- **Overall portfolio default rate:** 18.27% (475 defaults out of approximately 2,600 applications)
- **Income:** Low-income customers showed a higher default rate than high-income customers.
- **Employment:** Self-employed customers showed a higher default rate than salaried customers.
- **Geography:** Tier 3 cities showed substantially higher default rates than Tier 1 cities.
- **Segment risk:** Certain combinations of loan type, employment type, income bracket, and city tier showed significantly higher historical default rates.
- **Manual review:** 301 currently active applications were identified for potential manual review based on historical segment risk and application-level risk signals.

---

## Manual Review Framework

A live application is flagged for manual review when all of the following conditions are met:

### 1. The application is currently active

The application has:

current_dpd_bucket = 0 (Current)

### 2. The application belongs to a historically high-risk segment

The combination of:

- Loan type
- Employment type
- Income bracket
- City tier

must have a historical default rate of:

**≥ 20%**

Only segments with at least 10 applications are considered to avoid drawing conclusions from very small samples.

### 3. The application has at least one additional risk signal

An application is flagged when at least one of the following is present:

- Documentation is incomplete
- CIBIL score is below 650
- CIBIL score is missing (are marked as 0)
- Loan amount is greater than ₹200,000

Missing CIBIL is treated as a risk signal rather than being ignored because the absence of credit-history information itself may require additional verification.

---

## Dashboard

### Overview

https://github.com/meharpreet10/loan-default-risk-dashboard/blob/main/Portfolio%20Overview.png

### Segment Risk Analysis


### Manual Review Queue


---

## Key Skills Demonstrated

**SQL:**  
Data cleaning • CASE statements • Aggregations • GROUP BY • HAVING • CTEs • JOINs • Window functions • Risk segmentation

**Power BI:**  
Data modeling • DAX • Calculated columns • Measures • KPI design • Interactive dashboards • Cohort analysis

**Business Analytics:**  
Credit risk analysis • Customer segmentation • Risk identification • Manual review prioritization • Data-quality validation
