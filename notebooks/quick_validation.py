from sqlalchemy import create_engine, false,text
import urllib

DRIVER = '{ODBC Driver 17 for SQL Server}'
SERVER_NAME = 'DESKTOP-JMUSLO6'
CSV_PATH = r'C:\Users\hp 840 g8\Desktop\Personal\Learning\Data Analyst Project\FraudDetection\data\transactions.csv'

DB_NAME = 'FraudDetection'
CHUNK_SIZE = 50000

connection_string = f'DRIVER={DRIVER};SERVER={SERVER_NAME};DATABASE={DB_NAME};Trusted_Connection=yes;'
    
# -------------------------------------------------------
# Step 2 — Build SQLAlchemy engine
# -------------------------------------------------------
params = urllib.parse.quote_plus(connection_string)

engine = create_engine(f'mssql+pyodbc:///?odbc_connect={params}',fast_executemany=True)

# -------------------------------------------------------
# Step 8 — Quick validation
# -------------------------------------------------------
print("\n--- VALIDATION ---")
with engine.connect() as conn_sql:
    for table in ['accounts', 'transactions', 'fraud_labels']:
        count = conn_sql.execute(text(f"SELECT COUNT(*) FROM {table}")).scalar()
        print(f"{table:20s}: {count:>10,} rows")

print("\nAll done! Data loaded successfully.")