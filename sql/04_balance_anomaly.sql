-- ================================================
-- File    : 04_balance_anomaly.sql
-- Author  : Sahil Shahbuddin
-- Date    : 2026
-- Purpose : Detect accounts completely drained to zero in a single transaction
-- ================================================

USE FraudDetection;
GO

SELECT * FROM accounts;
SELECT * FROM transactions;
SELECT * FROM fraud_labels;
SELECT * FROM fraud_alerts;

-- PART A: Individual drained transactions

SELECT t.transaction_id AS [Transaction_ID]
, t.type AS [Transaction_Type]
, t.amount AS [Transaction_Amount]
, t.old_balance_orig AS [Old_Balance]
, t.new_balance_orig AS [New_Balance]
, fl.is_fraud AS [Is_Fraud]
, CASE WHEN new_balance_orig = 0 THEN 'Full Drain' END AS [Drain_Type]
FROM transactions t 
JOIN fraud_labels fl ON t.transaction_id = fl.transaction_id
WHERE t.old_balance_orig > 0
AND t.new_balance_orig = 0
AND t.amount = t.old_balance_orig
AND t.type IN ('TRANSFER', 'CASH_OUT')
ORDER BY t.amount DESC

---------------------------------------------------------------

-- PART B: Summary — what % of drains are fraud?

WITH DrainedAccounts AS (
SELECT t.transaction_id AS [Transaction_ID]
, t.type AS [Transaction_Type]
, t.amount AS [Transaction_Amount]
, t.old_balance_orig AS [Old_Balance]
, t.new_balance_orig AS [New_Balance]
, fl.is_fraud AS [Is_Fraud]
, CASE WHEN new_balance_orig = 0 THEN 'Full Drain' END AS [Drain_Type]
FROM transactions t 
JOIN fraud_labels fl ON t.transaction_id = fl.transaction_id
WHERE t.old_balance_orig > 0
AND t.new_balance_orig = 0
AND t.amount = t.old_balance_orig
AND t.type IN ('TRANSFER', 'CASH_OUT') )

SELECT Is_Fraud
, COUNT(*) AS [Total_Drains]
, ROUND(CAST(COUNT(*) AS FLOAT)/SUM(COUNT(*)) OVER() * 100 , 2) AS [Percentage]
FROM DrainedAccounts
GROUP BY Is_Fraud


/*
Using balance anomaly detection I identified that account full-drain transactions — 
where the entire balance is withdrawn in a single transaction — 
had a 100% fraud rate across 6.3 million transactions. 
This single rule alone would have caught 8,008 fraudulent transactions with zero false positives, 
making it the strongest signal in the dataset.
*/