
import os
from pathlib import Path
import psycopg

CSV_PATH = Path("metro_stations.csv")  # gerekirse yolunu değiştir
CATEGORY = "metro"

# Lisbon bbox (rough) for validation
LON_MIN, LON_MAX = -10.5, -7.5
LAT_MIN, LAT_MAX = 37.0, 41.0

def require_env(name: str) -> str:
    v = os.environ.get(name)
    if not v:
        raise SystemExit(f"Missing env var: {name}")
    return v

def main() -> None:
    db_url = require_env("DATABASE_URL")

    if not CSV_PATH.exists():
        raise SystemExit(f"CSV not found: {CSV_PATH.resolve()}")

    with psycopg.connect(db_url) as conn:
        with conn.cursor() as cur:
            # 1) Ensure staging table exists
            cur.execute("""
                CREATE TABLE IF NOT EXISTS public.temp_import (
                  a text,
                  b text,
                  c text
                );
            """)

            # 2) Ensure target table has expected columns (assumes locations already exists)
            # Idempotency: avoid duplicates
            cur.execute("""
                CREATE UNIQUE INDEX IF NOT EXISTS locations_cat_name_uniq
                ON public.locations (category, name);
            """)
            cur.execute("""
                CREATE INDEX IF NOT EXISTS locations_geom_gix
                ON public.locations USING GIST (geom);
            """)

            # 3) Clean staging
            cur.execute("TRUNCATE TABLE public.temp_import;")

            # 4) COPY CSV -> temp_import
            copy_sql = """
                COPY public.temp_import (a,b,c)
                FROM STDIN
                WITH (FORMAT csv, DELIMITER ';', HEADER true, ENCODING 'UTF8');
            """
            with cur.copy(copy_sql) as copy:
                with CSV_PATH.open("r", encoding="utf-8") as f:
                    for line in f:
                        copy.write(line)

            # 5) Load into locations with transform:
            # Your discovered rule: values are scaled, EPSG:3857, divide by 1e8, transform to 4326
            # Also filter out clearly broken rows by bbox after transform.
            cur.execute(f"""
                WITH src AS (
                  SELECT
                    trim(c) AS name,
                    (a::float8)/1e8 AS x,
                    (b::float8)/1e8 AS y
                  FROM public.temp_import
                  WHERE c IS NOT NULL AND trim(c) <> ''
                ),
                geoms AS (
                  SELECT
                    name,
                    ST_Transform(
                      ST_SetSRID(ST_MakePoint(x, y), 3857),
                      4326
                    ) AS geom
                  FROM src
                )
                INSERT INTO public.locations (name, category, geom)
                SELECT
                  name,
                  %s AS category,
                  geom
                FROM geoms
                WHERE ST_X(geom) BETWEEN {LON_MIN} AND {LON_MAX}
                  AND ST_Y(geom) BETWEEN {LAT_MIN} AND {LAT_MAX}
                ON CONFLICT (category, name)
                DO UPDATE SET geom = EXCLUDED.geom;
            """, (CATEGORY,))

            # 6) Quality checks
            cur.execute("""
                SELECT
                  count(*) AS n,
                  min(ST_X(geom)) AS min_lon,
                  max(ST_X(geom)) AS max_lon,
                  min(ST_Y(geom)) AS min_lat,
                  max(ST_Y(geom)) AS max_lat,
                  min(ST_SRID(geom)) AS srid_min,
                  max(ST_SRID(geom)) AS srid_max
                FROM public.locations
                WHERE category = %s;
            """, (CATEGORY,))
            row = cur.fetchone()
            print(f"[OK] category={CATEGORY} -> n={row[0]}")
            print(f"     lon:[{row[1]}, {row[2]}]  lat:[{row[3]}, {row[4]}]  srid:[{row[5]}, {row[6]}]")

        conn.commit()

if __name__ == "__main__":
    main()