-- Create Project Database
CREATE DATABASE FraudDetection;
GO

-- Switch it to FraudDetection
USE FraudDetection;
GO

-- =============================================
-- TABLE 1: Accounts (all senders & receivers)
-- =============================================

CREATE TABLE accounts (
	account_id VARCHAR(20) PRIMARY KEY,
	account_type VARCHAR(15) NOT NULL,
	first_seen DATETIME DEFAULT GETDATE(),
	total_sent FLOAT DEFAULT 0,
	total_received FLOAT DEFAULT 0
);

-- =============================================
-- TABLE 2: Transactions (core fact table)
-- =============================================

CREATE TABLE transactions (
	transaction_id INT PRIMARY KEY IDENTITY(1,1),
	step INT NOT NULL,
	type VARCHAR(15) NOT NULL,
	amount FLOAT NOT NULL,
	account_orig_id VARCHAR(20) NOT NULL,
	account_dest_id VARCHAR(20) NOT NULL,
	old_balance_orig FLOAT NOT NULL,
	new_balance_orig FLOAT NOT NULL,
	old_balance_dest FLOAT NOT NULL,
	new_balance_dest FLOAT NOT NULL,
	transaction_time DATETIME DEFAULT GETDATE()

	FOREIGN KEY (account_orig_id) REFERENCES accounts(account_id),
	FOREIGN KEY (account_dest_id) REFERENCES accounts(account_id)
);

-- =============================================
-- TABLE 3: Fraud Labels (ground truth)
-- =============================================

CREATE TABLE fraud_labels (
	label_id INT PRIMARY KEY IDENTITY(1,1),
	transaction_id INT NOT NULL,
	is_fraud INT NOT NULL DEFAULT 0,
	is_flagged_fraud INT NOT NULL DEFAULT 0,
	labeled_at DATETIME DEFAULT GETDATE(),

	FOREIGN KEY(transaction_id) REFERENCES transactions(transaction_id)
);

-- =============================================
-- TABLE 4: Fraud Alerts (system output)
-- =============================================

CREATE TABLE fraud_alerts(
	alert_id INT PRIMARY KEY IDENTITY(1,1),
	transaction_id INT NOT NULL,
	alerty_type VARCHAR(50),
	risk_score FLOAT,
	status VARCHAR(20) DEFAULT 'OPEN',
	created_at DATETIME DEFAULT GETDATE(),

	FOREIGN KEY(transaction_id) REFERENCES transactions(transaction_id)
);

-- Confrim all tables are successfully created
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_CATALOG = 'FraudDetection'

-- Server Name for Loading Data into SQL 
SELECT @@SERVERNAME;
SELECT @@VERSION;

SELECT * FROM accounts;
SELECT * FROM transactions;