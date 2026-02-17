import pandas as pd
import psycopg2

DATABASE_URL = "postgresql://postgres:1234@localhost:5432/coordinote"

df = pd.read_csv("metro_Stations.csv", sep=";")

conn = psycopg2.connect(DATABASE_URL)
cur = conn.cursor()

for index, row in df.iterrows():
    cur.execute("""
        INSERT INTO locations (l_name, category, geom)
        VALUES (%s, %s, ST_SetSRID(ST_MakePoint(%s, %s), 4326))
    """, (
        row["c"],        # isim
        "metro",
        float(row["a"]) / 10000000,  # longitude correction
        float(row["b"]) / 10000000   # latitude correction
    ))

conn.commit()
cur.close()
conn.close()

print("The process has been completed.")
