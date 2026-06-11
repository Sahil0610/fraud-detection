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
# Step 6 — Prepare & insert transactions table
# -------------------------------------------------------

transaction_df = df[['step', 'type', 'amount', 'nameOrig'
                    , 'nameDest', 'oldbalanceOrg', 'newbalanceOrig'
                    , 'oldbalanceDest', 'newbalanceDest']].rename(columns={
                        'nameOrig': 'account_orig_id',
                        'nameDest': 'account_dest_id',
                        'oldbalanceOrg': 'old_balance_orig',
                        'newbalanceOrig': 'new_balance_orig',
                        'oldbalanceDest': 'old_balance_dest',
                        'newbalanceDest': 'new_balance_dest'
                    })

print(f"Loading {len(transaction_df):,} transactions in chunks of {CHUNK_SIZE:,}...")

transaction_df.to_sql(
    'transactions',
    engine,
    if_exists = 'append',
    index= false,
    chunksize = CHUNK_SIZE
)

print("Transactions loaded successfully!")