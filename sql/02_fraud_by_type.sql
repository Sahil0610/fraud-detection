-- ================================================
-- File    : 02_fraud_by_type.sql
-- Author  : Sahil Shahbuddin
-- Date    : 2026
-- Purpose : Fraud distribution by transaction type
-- ================================================

USE FraudDetection;
GO

SELECT * FROM accounts;
SELECT * FROM transactions;
SELECT * FROM fraud_labels;
SELECT * FROM fraud_alerts;

SELECT t.type AS [Transaction_Type]
, COUNT(t.transaction_id) AS [Total_Transactions]
, SUM(fl.is_fraud) AS [Total_Fraud]
, ROUND(CAST(SUM(fl.is_fraud) AS FLOAT) / COUNT(t.transaction_id) * 100, 2) AS [Fraud_Rate_Percentage]
, ROUND(AVG(CASE WHEN fl.is_fraud = 1 THEN t.amount END),2) AS [Avg_Fraud_Amount]
, MAX(CASE WHEN fl.is_fraud = 1 THEN t.amount END) AS [Max_Fraud_Amount]
FROM transactions t 
JOIN fraud_labels fl ON t.transaction_id = fl.transaction_id
GROUP BY t.type
ORDER BY Fraud_Rate_Percentage DESC

/*
I discovered that 100% of fraud in this dataset occurs in only 2 out of 5 transaction types, 
which allowed us to build highly targeted detection rules.
*/
