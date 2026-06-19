-- ================================================
-- File    : 07_fraud_summary.sql
-- Author  : Sahil Shahbuddin
-- Date    : 2026
-- Purpose :  complete executive-level fraud overview in a single query
-- ================================================

USE FraudDetection;
GO

SELECT * FROM accounts;
SELECT * FROM transactions;
SELECT * FROM fraud_labels;
SELECT * FROM fraud_alerts;

SELECT 'Total Transactions' AS [Metric]
, CAST(COUNT(*) AS VARCHAR(50)) AS [Value]
, 'Overview' AS [Category]
FROM transactions

UNION ALL

SELECT 'Total Fraud Cases' AS [Metric]
, FORMAT(SUM(fl.is_fraud), 'N0') AS [Value]
, 'Overview' AS [Category]
FROM transactions t
JOIN fraud_labels fl ON t.transaction_id = fl.transaction_id

UNION ALL

SELECT 'Overall Fraud Percentage' AS [Metric]
, CAST(ROUND(CAST(SUM(fl.is_fraud) AS FLOAT) / COUNT(*) * 100, 2) AS VARCHAR(50)) + '%' AS [Value]
, 'Overview' AS [Category]
FROM transactions t
JOIN fraud_labels fl ON t.transaction_id = fl.transaction_id

UNION ALL

SELECT 'Total Amount Moved' AS [Metric]
, '$' + FORMAT(ROUND(SUM(t.amount), 2), 'N0') AS [Value]
, 'Overview' AS [Category]
FROM transactions t 

UNION ALL 

SELECT 'Total Fraud Amount Lost' AS [Metric]
, '$' + FORMAT(ROUND(SUM(CASE WHEN fl.is_fraud = 1 THEN t.amount END), 0), 'N0')AS [Value]
, 'Financial Impact' AS [Category]
FROM transactions t
JOIN fraud_labels fl ON t.transaction_id = fl.transaction_id

UNION ALL 

SELECT 'Avg Fraud Transaction' AS [Metric]
, '$' + FORMAT(ROUND(AVG(CASE WHEN fl.is_fraud = 1 THEN t.amount END), 0), 'N0') AS [Value]
, 'Financial Impact' AS [Category]
FROM transactions t
JOIN fraud_labels fl ON t.transaction_id = fl.transaction_id

UNION ALL 

SELECT 'Max Single Fraud' AS [Metric]
, '$' + FORMAT(MAX(CASE WHEN fl.is_fraud = 1 THEN t.amount END), 'N0') AS [Value]
, 'Financial Impact' AS [Category]
FROM transactions t
JOIN fraud_labels fl ON t.transaction_id = fl.transaction_id

UNION ALL 

SELECT 'Fraud in TRANSFER' AS [Metric]
, FORMAT(COUNT(CASE WHEN fl.is_fraud = 1 THEN 1 END), 'N0') AS [Value]
, 'By Type' AS [Category]
FROM transactions t
JOIN fraud_labels fl ON t.transaction_id = fl.transaction_id
WHERE t.type = 'TRANSFER'

UNION ALL 

SELECT 'Fraud in CASH_OUT' AS [Metric]
, FORMAT(COUNT(CASE WHEN fl.is_fraud = 1 THEN 1 END), 'N0') AS [Value]
, 'By Type' AS [Category]
FROM transactions t
JOIN fraud_labels fl ON t.transaction_id = fl.transaction_id
WHERE t.type = 'CASH_OUT'

UNION ALL 

SELECT 'Peak Fraud Hour' AS [Metric]
, STRING_AGG(X.Hour_of_Day, ' & ') AS [Value]
, 'Time Pattern' AS [Category]
FROM (
	SELECT ((t.step - 1) % 24) AS [Hour_of_Day]
	FROM transactions t
	JOIN fraud_labels fl ON t.transaction_id = fl.transaction_id
	GROUP BY (t.step - 1) % 24
	HAVING ROUND(CAST(SUM(fl.is_fraud) AS FLOAT) / COUNT(*) * 100, 2) > 20
	) X

UNION ALL 

SELECT 'Safest Hour' AS [Metric]
, CAST(X.Hour_of_Day AS VARCHAR(50)) + ':00 (lowest fraud rate)' AS [Value]
, 'Time Pattern' AS [Category]
FROM (
	SELECT TOP 1 ((t.step - 1) % 24) AS [Hour_of_Day]
	, ROUND(CAST(SUM(fl.is_fraud) AS FLOAT) / COUNT(*) * 100, 2) AS [Fraud_Percentage]
	FROM transactions t
	JOIN fraud_labels fl ON t.transaction_id = fl.transaction_id
	GROUP BY (t.step - 1) % 24
	ORDER BY ROUND(CAST(SUM(fl.is_fraud) AS FLOAT) / COUNT(*) * 100, 2) ASC
	) X

UNION ALL 

SELECT 'Full Drain Frauds' AS [Metric]
, FORMAT(COUNT(t.transaction_id), 'N0') AS [Value]
, 'Detection Rule' AS [Category]
FROM transactions t 
JOIN fraud_labels fl ON t.transaction_id = fl.transaction_id
WHERE t.old_balance_orig > 0
AND t.new_balance_orig = 0
AND t.amount = t.old_balance_orig

UNION ALL 

SELECT 'Hit & Run Accounts' AS [Metric]
, FORMAT(COUNT(X.account_orig_id), 'N0') AS [Value]
, 'Detection Rule' AS [Category]
FROM (SELECT t.account_orig_id
	FROM transactions t
	JOIN fraud_labels fl ON t.transaction_id = fl.transaction_id
	GROUP BY t.account_orig_id
	HAVING SUM(fl.is_fraud) >= 1
	AND COUNT(*) = 1) X