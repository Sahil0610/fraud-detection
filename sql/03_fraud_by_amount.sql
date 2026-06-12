-- ================================================
-- File    : 03_fraud_by_amount.sql
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

SELECT 
CASE  
	WHEN t.amount < 10000 THEN '0 - 10K'
    WHEN t.amount < 100000 THEN '10K - 100K'
    WHEN t.amount < 500000 THEN '100K - 500K'
    WHEN t.amount < 1000000 THEN '500K - 1M'
    ELSE 'Above 1M'
END AS [Amount_Range]
, COUNT(t.transaction_id) AS [Total_transaction]
, COUNT(CASE WHEN fl.is_fraud = 1 THEN 1 END) AS [Total_Fraud]
, ROUND(CAST(SUM(fl.is_fraud) AS FLOAT) / COUNT(t.transaction_id) * 100, 2) AS [Fraud_Rate_Percentage]
, ROUND(SUM(CASE WHEN fl.is_fraud = 1 THEN t.amount END),2) AS [Total_Fraud_Amount]
FROM transactions t 
JOIN fraud_labels fl ON t.transaction_id = fl.transaction_id
GROUP BY CASE  
	WHEN t.amount < 10000 THEN '0 - 10K'
    WHEN t.amount < 100000 THEN '10K - 100K'
    WHEN t.amount < 500000 THEN '100K - 500K'
    WHEN t.amount < 1000000 THEN '500K - 1M'
    ELSE 'Above 1M'
END
ORDER BY MIN(t.amount)

/*
Analysis showed fraud rate increases dramatically with transaction amount — 
transactions above 1M had the highest fraud concentration, 
suggesting fraudsters deliberately target high-value transfers.
*/