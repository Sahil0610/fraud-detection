import pandas as pd

#Load data
fraudData = pd.read_csv(r'C:\Users\hp 840 g8\Desktop\Personal\Learning\Data Analyst Project\FraudDetection\data\transactions.csv')

#Basic Exploration
print("Shape:", fraudData.shape)
print("\nColumns:", fraudData.columns.tolist())
print("\nData Types:\n", fraudData.dtypes)
print("\nFirst 5 rows:\n", fraudData.head())
print("\nFraud distribution:\n", fraudData['isFraud'].value_counts())
print("\nNull values:\n", fraudData.isnull().sum())
print("\nTransaction types:\n", fraudData['type'].value_counts())