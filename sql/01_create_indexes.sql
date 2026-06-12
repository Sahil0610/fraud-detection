USE FraudDetection;
GO

SELECT * FROM accounts;
SELECT * FROM transactions;
SELECT * FROM fraud_labels;
SELECT * FROM fraud_alerts;

-- Speed up Fraud lookups
CREATE INDEX idx_fraud_labels
ON fraud_labels(is_fraud);

-- Speed up joins between transactions and fraud_labels
CREATE INDEX idx_txn_id
ON fraud_labels(transaction_id);

-- Speed up filtering by type
CREATE INDEX idx_txn_type
ON transactions(type);

-- Speed up sender/receiver lookups
CREATE INDEX idx_txn_orig 
ON transactions(account_orig_id);

CREATE INDEX idx_txn_dest 
ON transactions(account_dest_id);

-- Speed up amount-based queries
CREATE INDEX idx_txn_amount 
ON transactions(amount);

-- Speed up time-based queries
CREATE INDEX idx_txn_step 
ON transactions(step);

PRINT 'All indexes created successfully';
GO