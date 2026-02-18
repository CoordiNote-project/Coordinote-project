
import pandas as pd
import psycopg2

DB_CONFIG = {
    "database": "coordinote_share",
    "user": "postgres",
    "password": "postgres",
    "host": "localhost",
    "port": "5432"
}

def load_csv(file_path, category):
    conn = psycopg2.connect(**DB_CONFIG)
    cur = conn.cursor()

    df = pd.read_csv(file_path, sep=";", decimal=",")

    for _, row in df.iterrows():
        lon = float(row["a"]) 
        lat = float(row["b"]) 

        name = row["c"]

        cur.execute("""
            INSERT INTO locations (l_name, category, geom)
            VALUES (%s, %s,
                ST_SetSRID(ST_MakePoint(%s, %s), 4326)
            );
        """, (name, category, lon, lat))

    conn.commit()
    cur.close()
    conn.close()


load_csv("metro_Stations.csv", "metro")
load_csv("Teatros.csv", "theatre")
load_csv("Patrimonio_Statues.csv", "statue")

print("ETL completed.")
