# 💳 Credit Card Fraud Detection

A job-ready end-to-end data project covering data engineering,
SQL analytics, and machine learning.

## Tech Stack
- Python (pandas, sqlalchemy, pyodbc)
- SQL Server (SSMS)
- Machine Learning (coming soon)

## Project Structure
fraud-detection/
├── data/          # Raw data (not uploaded - see Data Source)
├── notebooks/     # Python scripts
├── sql/           # SQL queries
├── models/        # ML models (coming soon)
└── README.md

## Data Source
PaySim synthetic financial dataset
- 6.3 million transactions
- Source: https://www.kaggle.com/datasets/ealaxi/paysim1

## Steps Completed
- [x] Data exploration
- [x] Database schema design
- [x] Data loading into SQL Server
- [ ] SQL analytics & fraud queries
- [ ] ML fraud detection model
- [ ] Dashboard

## How to Run
1. Download dataset and place in `/data/transactions.csv`
2. Update `SERVER_NAME` in scripts with your SQL Server name
3. Run `notebooks/load_data.py`