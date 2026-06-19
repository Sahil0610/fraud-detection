-- ================================================
-- File    : 05_high_risk_accounts.sql
-- Author  : Sahil Shahbuddin
-- Date    : 2026
-- Purpose : sender accounts are repeat fraud offenders
-- ================================================

USE FraudDetection;
GO

SELECT * FROM accounts;
SELECT * FROM transactions;
SELECT * FROM fraud_labels;
SELECT * FROM fraud_alerts;


SELECT t.account_orig_id AS [Account_Id]
, COUNT(*) AS [Total_Transactions]
, SUM(fl.is_fraud) AS [Total_Fraud_Committed]
, ROUND(SUM(t.amount),2) AS [Total_Amount_Moved]
, ROUND(SUM(CASE WHEN fl.is_fraud = 1 THEN t.amount END), 2)  AS [Total_Fraud_Amount]
, ROUND(SUM(CASE WHEN fl.is_fraud = 1 THEN t.amount END) / NULLIF(SUM(t.amount), 0) * 100, 2) AS [Fraud_Percentage]
, CASE 
	WHEN SUM(fl.is_fraud) >= 2 THEN 'Critical'
	WHEN SUM(fl.is_fraud) = 1 THEN 'High'
	WHEN SUM(fl.is_fraud) = 0 THEN 'Low'
	END AS [Risk_Level]
FROM transactions t
JOIN fraud_labels fl ON t.transaction_id = fl.transaction_id
GROUP BY t.account_orig_id
HAVING SUM(fl.is_fraud) >= 1

/*
-- FINDINGS:
-- All fraud accounts show exactly 1 transaction
-- with 100% fraud rate — classic hit and run pattern
-- No repeat offenders found in dataset
-- Largest single fraud: $10,000,000 (C1251439451)
-- This pattern suggests organized fraud operation
-- using fresh account identities per attack
*/