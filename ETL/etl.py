import pandas as pd

categories = {
    "metro_stations": "metro_stations.csv",
    "parques_de_merendas_picnic_parks": "Parques_de_Merendas_Picnic_Parks.csv",
    "patrimonio_statues": "Patrimonio_Statues.csv",
    "teatros": "Teatros.csv"
}

dataframes = {}

# Load files
for category, file in categories.items():
    try:
        df = pd.read_csv(file, sep=";", header=None)
        df = df.iloc[:, :3]
        df.columns = ["a", "b", "c"]
        df = df.dropna()

        dataframes[category] = df

    except Exception as e:
        print(f"Error loading {file}: {e}")

if not dataframes:
    print("No data files loaded.")
    exit()

print("\nWelcome!")
print("Please select the address category where you would like to leave a message:\n")

for cat in dataframes.keys():
    print("-", cat)

selected_category = input("\nType the category name: ").strip().lower()

if selected_category in dataframes:

    df = dataframes[selected_category]

    print(f"\nLocations available in '{selected_category}':\n")

    for _, row in df.iterrows():
        print(f"- {row['c']} (X: {row['a']}, Y: {row['b']})")

else:
    print("Invalid category selected.")

    
# etl_load_metro.py
import os
import pandas as pd
import psycopg

CSV_PATH = "metro_stations.csv"
CATEGORY = "metro"

DB_URL = os.environ.get("postgresql://postgres:postgres@localhost:5432/coordinote")  # ör: postgresql://user:pass@localhost:5432/coordinote
if not DB_URL:
    raise SystemExit("Set DATABASE_URL env var.")

def main() -> None:
    df = pd.read_csv(CSV_PATH, sep=";", header=None).iloc[:, :3]
    df.columns = ["a", "b", "c"]
    df = df.dropna()

    # basic cleanup
    df["c"] = df["c"].astype(str).str.strip()
    df = df[df["c"] != ""]

    with psycopg.connect(DB_URL) as conn:
        with conn.cursor() as cur:
            # Optional but recommended uniqueness to make ETL idempotent:
            cur.execute("""
                CREATE UNIQUE INDEX IF NOT EXISTS locations_cat_name_uniq
                ON locations (category, name);
            """)

            # Insert/upsert each row
            sql = """
                INSERT INTO locations (l_name, category, geom)
                VALUES (
                  %(name)s,
                  %(category)s,
                  ST_Transform(
                    ST_SetSRID(ST_MakePoint(%(x)s, %(y)s), 3857),
                    4326
                  )
                )
                ON CONFLICT (category, name)
                DO UPDATE SET geom = EXCLUDED.geom;
            """

            rows = []
            for _, r in df.iterrows():
                # scale rule you discovered: /1e8
                x = float(r["a"]) / 1e8
                y = float(r["b"]) / 1e8
                rows.append({"name": r["c"], "category": CATEGORY, "x": x, "y": y})

            cur.executemany(sql, rows)

        conn.commit()

    print(f"Loaded/updated {len(df)} locations into category='{CATEGORY}'.")

if __name__ == "__main__":
    main()