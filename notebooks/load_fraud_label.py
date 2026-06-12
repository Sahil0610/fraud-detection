import pandas as pd
import pyodbc
from sqlalchemy import create_engine, false,text
from tqdm import tqdm
import urllib

DRIVER = '{ODBC Driver 17 for SQL Server}'
SERVER_NAME = 'DESKTOP-JMUSLO6'
CSV_PATH = r'C:\Users\hp 840 g8\Desktop\Personal\Learning\Data Analyst Project\FraudDetection\data\transactions.csv'

DB_NAME = 'FraudDetection'
CHUNK_SIZE = 50000

connection_string = f'DRIVER={DRIVER};SERVER={SERVER_NAME};DATABASE={DB_NAME};Trusted_Connection=yes;'

# -------------------------------------------------------
# Step 1 — Test connection
# -------------------------------------------------------

try:
    print("Testing database connection...")
    conn = pyodbc.connect(connection_string)

    print("Connection successful!")
    conn.close()

except Exception as e:
    print("Connection failed:", e)
    print(f"Error details: {e}")
    exit()
    
# -------------------------------------------------------
# Step 2 — Build SQLAlchemy engine
# -------------------------------------------------------
params = urllib.parse.quote_plus(connection_string)

engine = create_engine(f'mssql+pyodbc:///?odbc_connect={params}',fast_executemany=True)

# -------------------------------------------------------
# Step 3 — Load CSV
# -------------------------------------------------------

print("\n Reading CSV file...")
df = pd.read_csv(CSV_PATH)
print(f"CSV loaded successfully! Total rows: {len(df)}, {len(df.columns)} columns")

print(df.head())


# -------------------------------------------------------
# Step 7 — Insert fraud_labels table
# -------------------------------------------------------

print("\nLoading fraud labels...")

# We need transaction_id from the DB (auto-generated IDENTITY column)

with engine.connect() as conn:
    db_tnxs = pd.read_sql(text("SELECT transaction_id, account_orig_id, amount, step FROM transactions"), conn)

# Match back to original df to get fraud flags

df_merged = db_tnxs.merge(df[['step', 'amount','nameOrig','isFraud','isFlaggedFraud']].rename(
    columns={
        'nameOrig': 'account_orig_id'}),
        on=['step', 'amount', 'account_orig_id'], 
        how='left')

fraud_label_df = df_merged[['transaction_id','isFraud','isFlaggedFraud']].rename(
    columns={
        'isFraud': 'is_fraud',
        'isFlaggedFraud': 'is_flagged_fraud'
    }).drop_duplicates(subset=['transaction_id'])

fraud_label_df.to_sql(
        'fraud_labels',
        engine,
        if_exists = 'append',
        index= false,
        chunksize = CHUNK_SIZE
)

print(f"Fraud labels loaded: {len(fraud_label_df):,} rows")