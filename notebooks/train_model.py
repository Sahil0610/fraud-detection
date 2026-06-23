import pandas as pd
import urllib
from sqlalchemy import create_engine
from sklearn.model_selection import train_test_split
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import (
    accuracy_score, precision_score, recall_score, 
    f1_score, confusion_matrix, classification_report
)
from sklearn.ensemble import RandomForestClassifier

DRIVER = '{ODBC Driver 17 for SQL Server}'
SERVER_NAME = 'DESKTOP-JMUSLO6'
DB_NAME = 'FraudDetection'

connection_string = f'DRIVER={DRIVER};SERVER={SERVER_NAME};DATABASE={DB_NAME};Trusted_Connection=yes;'

params = urllib.parse.quote_plus(connection_string)

engine = create_engine(f'mssql+pyodbc:///?odbc_connect={params}',fast_executemany=True)

print("Pulling data from SQL Server...")

query = """
    SELECT t.transaction_id,
    t.step,
    t.type,
    t.amount,
    t.old_balance_orig,
    t.new_balance_orig,
    t.old_balance_dest,
    t.new_balance_dest,
    fl.is_fraud
    FROM transactions t
    JOIN fraud_labels fl ON t.transaction_id = fl.transaction_id
"""

df = pd.read_sql_query(query, engine)
print(f"Pulled {len(df):,} rows")
print(df['is_fraud'].value_counts())

# ============================================================
# Feature Engineering
# ============================================================

print("\nEngineering features...")

# Hour of day (0-23) — we found 3-4 AM has 22% fraud rate
df['hour_of_day'] = (df['step'] - 1) % 24

# Night flag — 1 to 5 AM window
df['is_night'] = df['hour_of_day'].between(1,5).astype(int)

# Full drain — old balance fully emptied, matches our Query 4 finding
df['is_full_drain'] = (
    (df['old_balance_orig'] > 0) &
    (df['new_balance_orig'] == 0) &
    (df['amount'] == df['old_balance_orig'])
).astype(int)

# Balance changes — captures "draining" behavior even if not a full drain
df['balance_diff_orig'] = df['old_balance_orig'] - df['new_balance_orig']
df['balance_diff_dest'] = df['old_balance_dest'] - df['new_balance_dest']

# Error flags — mismatch between expected and actual balance change
# (legit transactions should have orig_balance go down by exactly `amount`)
df['error_balance_orig'] = df['new_balance_orig'] + df['amount'] - df['old_balance_orig']
df['error_balance_dest'] = df['old_balance_dest'] + df['amount'] - df['new_balance_dest']

# One-hot encode transaction type

df = pd.get_dummies(df, columns=['type'], prefix='type')

print("\nFeature columns created:")
print(df.columns.tolist())
print("\nSample of engineered features:")
print(df[['hour_of_day', 'is_night', 'is_full_drain', 'balance_diff_orig']].head())

# ============================================================
# Prepare features (X) and target (y)
# ============================================================

print("\nPreparing X and y...")

X =  df.drop(columns = ['transaction_id', 'is_fraud'])
y = df['is_fraud']

print(f"Feature columns used for training ({len(X.columns)}):")
print(X.columns.tolist())
print(f"\nTarget distribution:\n{y.value_counts()}")
print(f"\nFraud percentage: {y.mean() * 100:.3f}%")

# ============================================================
# Train/Test Split
# ============================================================

print("\nSplitting data into train/test sets...")

X_train, X_test, y_train, y_test = train_test_split(
    X, y,
    test_size=0.2,
    random_state=42,
    stratify=y
)

print(f"Training set: {len(X_train):,} rows")
print(f"Test set: {len(X_test):,} rows")
print(f"Fraud in train: {y_train.sum():,} ({y_train.mean()*100:.3f}%)")
print(f"Fraud in test: {y_test.sum():,} ({y_test.mean()*100:.3f}%)")

# ============================================================
# Train Baseline Model — Logistic Regression
# ============================================================
print("\nTraining Logistic Regression model...")

model = LogisticRegression(
    class_weight='balanced',  # tells the model fraud mistakes cost more
    max_iter=1000,           # give it enough iterations to converge
    random_state=42
)

model.fit(X_train, y_train) 
print("Model training complete.")

# ============================================================
# Evaluate the Model
# ============================================================
print("\nEvaluating model on test set...")

y_pred = model.predict(X_test)

# THE TRAP — look at this number first
accuracy = accuracy_score(y_test, y_pred)
print(f"\nAccuracy: {accuracy:.4f}  ({accuracy*100:.2f}%)")

# THE TRUTH — these matter much more for fraud detection
precision = precision_score(y_test, y_pred)
recall = recall_score(y_test, y_pred)
f1 = f1_score(y_test, y_pred)

print(f"Precision: {precision:.4f}  ({precision*100:.2f}%)")
print(f"Recall:    {recall:.4f}  ({recall*100:.2f}%)")
print(f"F1 Score:  {f1:.4f}")

# Confusion matrix — shows exactly what the model got right/wrong
cm = confusion_matrix(y_test, y_pred)
print(f"\nConfusion Matrix:")
print(f"                  Predicted Legit   Predicted Fraud")
print(f"Actual Legit      {cm[0][0]:>15,}   {cm[0][1]:>15,}")
print(f"Actual Fraud      {cm[1][0]:>15,}   {cm[1][1]:>15,}")

print(f"\nFull Classification Report:")
print(classification_report(y_test, y_pred, target_names=['Legit', 'Fraud']))

# ============================================================
# Train Random Forest Model
# ============================================================
print("\nTraining Random Forest model...")

rf_model = RandomForestClassifier(
    n_estimators = 100,        # number of trees in the forest
    class_weight = 'balanced', # same imbalance fix as before
    max_depth = 10,            # limits how complex each tree can get
    random_state = 42,
    n_jobs = -1                 # use all CPU cores to speed up training
)

rf_model.fit(X_train, y_train)
print("Random Forest trained!")

# ============================================================
# Evaluate Random Forest
# ============================================================
print("\nEvaluating Random Forest on test set...")

y_pred_rf = rf_model.predict(X_test)
accuracy_rf = accuracy_score(y_test, y_pred_rf)
precision_rf = precision_score(y_test, y_pred_rf)
recall_rf = recall_score(y_test, y_pred_rf)
f1_rf = f1_score(y_test, y_pred_rf)

print(f"\nAccuracy:  {accuracy_rf:.4f}  ({accuracy_rf*100:.2f}%)")
print(f"Precision: {precision_rf:.4f}  ({precision_rf*100:.2f}%)")
print(f"Recall:    {recall_rf:.4f}  ({recall_rf*100:.2f}%)")
print(f"F1 Score:  {f1_rf:.4f}")

cm_rf = confusion_matrix(y_test, y_pred_rf)
print(f"\nConfusion Matrix:")
print(f"                  Predicted Legit   Predicted Fraud")
print(f"Actual Legit      {cm_rf[0][0]:>15,}   {cm_rf[0][1]:>15,}")
print(f"Actual Fraud      {cm_rf[1][0]:>15,}   {cm_rf[1][1]:>15,}")

# ============================================================
# Feature Importance — which features is the model relying on?
# ============================================================
print("\nFeature Importances (Random Forest):")

importances = pd.DataFrame({
    'feature': X_train.columns,
    'importance': rf_model.feature_importances_
}).sort_values('importance', ascending=False)

print(importances.to_string(index=False))

# ============================================================
# Model B — Realistic Random Forest (no is_full_drain)
# ============================================================
print("\nTraining Realistic Random Forest (without is_full_drain)...")

# Drop the near-perfect predictor
X_train_realistic = X_train.drop(columns=['is_full_drain'])
X_test_realistic  = X_test.drop(columns=['is_full_drain'])

rf_realistic = RandomForestClassifier(
    n_estimators=100,
    class_weight='balanced',
    max_depth=10,
    random_state=42,
    n_jobs=-1
)

rf_realistic.fit(X_train_realistic, y_train)
print("Realistic model trained!")

# Evaluate
y_pred_realistic = rf_realistic.predict(X_test_realistic)

accuracy_r  = accuracy_score(y_test, y_pred_realistic)
precision_r = precision_score(y_test, y_pred_realistic)
recall_r    = recall_score(y_test, y_pred_realistic)
f1_r        = f1_score(y_test, y_pred_realistic)

print(f"\nAccuracy:  {accuracy_r:.4f}  ({accuracy_r*100:.2f}%)")
print(f"Precision: {precision_r:.4f}  ({precision_r*100:.2f}%)")
print(f"Recall:    {recall_r:.4f}  ({recall_r*100:.2f}%)")
print(f"F1 Score:  {f1_r:.4f}")

cm_r = confusion_matrix(y_test, y_pred_realistic)
print(f"\nConfusion Matrix:")
print(f"                  Predicted Legit   Predicted Fraud")
print(f"Actual Legit      {cm_r[0][0]:>15,}   {cm_r[0][1]:>15,}")
print(f"Actual Fraud      {cm_r[1][0]:>15,}   {cm_r[1][1]:>15,}")

# ============================================================
# Side by Side Comparison — All 3 Models
# ============================================================
print("\n" + "="*65)
print("MODEL COMPARISON SUMMARY")
print("="*65)
print(f"{'Metric':<25} {'Logistic Reg':>13} {'RF Full':>13} {'RF Realistic':>13}")
print("-"*65)
print(f"{'Accuracy':<25} {accuracy*100:>12.2f}% {accuracy_rf*100:>12.2f}% {accuracy_r*100:>12.2f}%")
print(f"{'Precision':<25} {precision*100:>12.2f}% {precision_rf*100:>12.2f}% {precision_r*100:>12.2f}%")
print(f"{'Recall':<25} {recall*100:>12.2f}% {recall_rf*100:>12.2f}% {recall_r*100:>12.2f}%")
print(f"{'F1 Score':<25} {f1:>13.4f} {f1_rf:>13.4f} {f1_r:>13.4f}")
print("="*65)   

import joblib

# ============================================================
# Save Models
# ============================================================
print("\nSaving models...")
joblib.dump(model, '../models/logistic_regression.pkl')
joblib.dump(rf_model, '../models/random_forest_full.pkl')
joblib.dump(rf_realistic,'../models/random_forest_realistic.pkl')
print("All 3 models saved to /models/")

# ============================================================
# Feature Importance — Realistic Model
# ============================================================
print("\nFeature Importances (Realistic Random Forest):")

importances_r = pd.DataFrame({
    'feature'   : X_train_realistic.columns,
    'importance': rf_realistic.feature_importances_
}).sort_values('importance', ascending=False)

print(importances_r.to_string(index=False))