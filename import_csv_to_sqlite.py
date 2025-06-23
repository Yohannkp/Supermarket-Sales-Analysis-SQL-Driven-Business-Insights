import sqlite3
import pandas as pd
import os

# Chemins des fichiers CSV
csv_files = {
    'annex1': 'annex1.csv',
    'annex2': 'annex2.csv',
    'annex3': 'annex3.csv',
    'annex4': 'annex4.csv',
}

db_name = 'projet_data.db'

# Connexion à la base de données SQLite
conn = sqlite3.connect(db_name)
cursor = conn.cursor()

# Création des tables
cursor.execute('''
CREATE TABLE IF NOT EXISTS annex1 (
    Item_Code TEXT PRIMARY KEY,
    Item_Name TEXT,
    Category_Code TEXT,
    Category_Name TEXT
)
''')
cursor.execute('''
CREATE TABLE IF NOT EXISTS annex2 (
    Date TEXT,
    Time TEXT,
    Item_Code TEXT,
    Quantity_Sold REAL,
    Unit_Selling_Price REAL,
    Sale_or_Return TEXT,
    Discount TEXT
)
''')
cursor.execute('''
CREATE TABLE IF NOT EXISTS annex3 (
    Date TEXT,
    Item_Code TEXT,
    Wholesale_Price REAL
)
''')
cursor.execute('''
CREATE TABLE IF NOT EXISTS annex4 (
    Item_Code TEXT PRIMARY KEY,
    Item_Name TEXT,
    Loss_Rate REAL
)
''')

# Importation des CSV dans les tables
# annex1
annex1 = pd.read_csv(csv_files['annex1'])
annex1.columns = ['Item_Code', 'Item_Name', 'Category_Code', 'Category_Name']
annex1.to_sql('annex1', conn, if_exists='replace', index=False)

# annex2
annex2 = pd.read_csv(csv_files['annex2'])
annex2.columns = ['Date', 'Time', 'Item_Code', 'Quantity_Sold', 'Unit_Selling_Price', 'Sale_or_Return', 'Discount']
annex2.to_sql('annex2', conn, if_exists='replace', index=False)

# annex3
annex3 = pd.read_csv(csv_files['annex3'])
annex3.columns = ['Date', 'Item_Code', 'Wholesale_Price']
annex3.to_sql('annex3', conn, if_exists='replace', index=False)

# annex4
annex4 = pd.read_csv(csv_files['annex4'])
annex4.columns = ['Item_Code', 'Item_Name', 'Loss_Rate']
# Nettoyage du taux de perte (enlever % et espaces)
annex4['Loss_Rate'] = annex4['Loss_Rate'].astype(str).str.replace('%','').str.strip().astype(float)
annex4.to_sql('annex4', conn, if_exists='replace', index=False)

print(f"Base de données SQLite '{db_name}' créée et alimentée avec succès !")

conn.close()
