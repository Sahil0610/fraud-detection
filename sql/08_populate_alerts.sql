-- ================================================
-- File    : 08_populate_alerts.sql
-- Author  : Sahil Shahbuddin
-- Date    : 2026
-- Purpose : INSERT INTO to populate the fraud_alerts table
-- ================================================

USE FraudDetection;
GO

SELECT * FROM accounts;
SELECT * FROM transactions;
SELECT * FROM fraud_labels;
SELECT * FROM fraud_alerts;

-- FULL_DRAIN - Rule 1
INSERT INTO fraud_alerts (transaction_id, alerty_type, risk_score, status) 
SELECT t.transaction_id,
'FULL_DRAIN' AS [alert_type],
0.95 AS [risk_score],
'OPEN' AS status
FROM transactions t
JOIN fraud_labels fl ON t.transaction_id = fl.transaction_id
WHERE t.old_balance_orig > 0
AND t.new_balance_orig  = 0
AND t.amount = t.old_balance_orig
AND t.type IN ('TRANSFER', 'CASH_OUT')

-- NIGHT_TRANSFER - Rule 2
INSERT INTO fraud_alerts (transaction_id, alerty_type, risk_score, status) 
SELECT t.transaction_id,
'NIGHT_TRANSFER' AS [alert_type],
0.85 AS [risk_score],
'OPEN' AS status
FROM transactions t
JOIN fraud_labels fl ON t.transaction_id = fl.transaction_id
WHERE t.type IN ('TRANSFER', 'CASH_OUT')
AND ((t.step - 1) % 24) BETWEEN 1 AND 5

--  HIGH_AMOUNT - Rule 3
INSERT INTO fraud_alerts (transaction_id, alerty_type, risk_score, status) 
SELECT t.transaction_id,
'HIGH_AMOUNT' AS [alert_type],
0.75 AS [risk_score],
'OPEN' AS status
FROM transactions t
JOIN fraud_labels fl ON t.transaction_id = fl.transaction_id
WHERE t.type IN ('TRANSFER', 'CASH_OUT')
AND t.amount >= 1000000

-- HIT AND RUN - Rule 4
INSERT INTO fraud_alerts (transaction_id, alerty_type, risk_score, status) 
SELECT t.transaction_id,
'HIT_AND_RUN' AS [alert_type],
0.70 AS [risk_score],
'OPEN' AS status
FROM transactions t
JOIN fraud_labels fl ON t.transaction_id = fl.transaction_id
WHERE t.account_orig_id IN (
    SELECT t2.account_orig_id
    FROM transactions t2
    JOIN fraud_labels fl2 ON t2.transaction_id = fl2.transaction_id
    GROUP BY t2.account_orig_id
    HAVING SUM(fl2.is_fraud) >= 1
    AND COUNT(*) = 1
)


SELECT alerty_type, COUNT(*)
FROM fraud_alerts
GROUP BY alerty_type