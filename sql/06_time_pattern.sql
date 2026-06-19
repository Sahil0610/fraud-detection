-- ================================================
-- File    : 06_time_pattern.sql
-- Author  : Sahil Shahbuddin
-- Date    : 2026
-- Purpose : At what hours does fraud peak — and does fraud follow the same time pattern as legitimate transactions?
-- ================================================

USE FraudDetection;
GO

SELECT * FROM accounts;
SELECT * FROM transactions;
SELECT * FROM fraud_labels;
SELECT * FROM fraud_alerts;

SELECT ((t.step - 1) % 24) AS [Hour_of_Day]
, COUNT(*) AS [Total_Transactions]
, SUM(fl.is_fraud) AS [Total_Fraud_Committed]
, (COUNT(*) - SUM(fl.is_fraud)) AS [Legitimate_Transaction]
, ROUND(CAST(SUM(fl.is_fraud) AS FLOAT) / COUNT(*) * 100, 2)  AS [Fraud_Rate_Percentage]
, ROUND(AVG(CASE WHEN fl.is_fraud = 1 THEN t.amount END), 2) AS [Avg_Fraud_Amount]
, CASE 
	WHEN ROUND(SUM(CASE WHEN fl.is_fraud = 1 THEN t.amount END) / NULLIF(SUM(t.amount), 0) * 100, 2) >= 0.5 THEN 'High Risk Hour'
	WHEN ROUND(SUM(CASE WHEN fl.is_fraud = 1 THEN t.amount END) / NULLIF(SUM(t.amount), 0) * 100, 2) >= 0.1 THEN 'Medium Risk Hour'
	WHEN ROUND(SUM(CASE WHEN fl.is_fraud = 1 THEN t.amount END) / NULLIF(SUM(t.amount), 0) * 100, 2) < 0.1 THEN 'Low Risk Hour'
	END AS [Peak_Label]
FROM transactions t
JOIN fraud_labels fl ON t.transaction_id = fl.transaction_id
GROUP BY (t.step - 1) % 24
--HAVING ROUND(CAST(SUM(fl.is_fraud) AS FLOAT) / COUNT(*) * 100, 2) > 20
ORDER BY (t.step - 1) % 24 ASC

/*
Time pattern analysis revealed a dramatic fraud concentration between 2–5 AM, 
with fraud rates peaking at 22% — nearly 300 times higher than peak business hours. 
Despite low transaction volumes, fraudsters systematically target these hours when monitoring is minimal and 
victims are asleep. This suggests a rule-based alert: flag any TRANSFER or CASH_OUT between 1–5 AM for immediate review.
*/

-- ================================================
-- KEY FINDINGS:
-- Peak fraud hours: 3 AM (22.08%) and 4 AM (22.30%)
-- Dead zone: 2-5 AM averages ~18% fraud rate
-- Safest hours: 10-11 AM and 2-6 PM (~0.06-0.08%)
-- Business hours (9AM-6PM): < 0.1% fraud rate
-- Volume paradox: fraudsters prefer low-volume hours
-- Recommended rule: flag all TRANSFER/CASH_OUT 1AM-5AM
-- ================================================


