import time
import requests
import pandas as pd
import geopandas as gpd
from shapely.geometry import Point
from sqlalchemy import create_engine, text
from geoalchemy2 import Geometry

# -------------------------------------------------------
# CONFIGURATION
# -------------------------------------------------------

DB_USER = "postgres"      
DB_PASSWORD = "postgres"  # Remember to update your PostgreSQL password here
DB_HOST = "localhost"
DB_PORT = "5432"
DB_NAME = "coordinote_share"
TABLE_NAME = "locations"

TRUNCATE_BEFORE_LOAD = True

# Define the categories and their specific OpenStreetMap queries
# You can easily add more categories here in the future!
TARGETS = {
    "metro": 'nwr["railway"="station"]["station"="subway"](area.searchArea);',
    "bus_stop": 'node["highway"="bus_stop"](area.searchArea);'
}

# -------------------------------------------------------
# EXTRACT + TRANSFORM 
# -------------------------------------------------------

def fetch_osm_data(category, target_query):
    print(f"\nFetching '{category}' locations via OpenStreetMap...")

    overpass_url = "http://overpass-api.de/api/interpreter"
    full_query = f"""
    [out:json];
    area[name="Lisboa"]->.searchArea;
    {target_query}
    out center;
    """

    max_retries = 3
    data_json = None
    
    for attempt in range(max_retries):
        try:
            response = requests.get(overpass_url, params={'data': full_query}, timeout=90)
            response.raise_for_status() 
            data_json = response.json()
            break
        except requests.exceptions.RequestException as e:
            print(f"Warning: API connection failed (Attempt {attempt + 1}/{max_retries}) - Error: {e}")
            if attempt < max_retries - 1:
                print("Waiting 5 seconds before retrying...")
                time.sleep(5)
            else:
                raise Exception(f"Failed to fetch {category} data.")

    if not data_json:
        return gpd.GeoDataFrame() # Return empty if nothing found

    records = []
    for element in data_json.get('elements', []):
        tags = element.get('tags', {})
        
        # Bus stops often don't have a 'name' but have a 'ref' (reference number)
        # We try to get 'name', if not available, we try 'ref', if neither, we label it 'Unnamed'
        name = tags.get('name', tags.get('ref', f'Unnamed {category}'))
        
        if 'center' in element:
            lat = element['center']['lat']
            lon = element['center']['lon']
        else:
            lat = element.get('lat')
            lon = element.get('lon')
            
        if lon and lat:
            records.append({'l_name': name, 'category': category, 'geom': Point(lon, lat)})

    if not records:
        print(f"No records found for {category}.")
        return gpd.GeoDataFrame()

    gdf = gpd.GeoDataFrame(records, geometry="geom", crs="EPSG:4326")
    print(f"Successfully processed {len(gdf)} records for '{category}'.")
    return gdf

def extract_transform():
    all_dataframes = []
    
    # Loop through each target category and fetch its data
    for category, query in TARGETS.items():
        gdf = fetch_osm_data(category, query)
        if not gdf.empty:
            all_dataframes.append(gdf)
            
    if not all_dataframes:
        raise Exception("No data could be retrieved for any category.")
        
    # Combine (concatenate) all the different categories into one massive table
    final_gdf = pd.concat(all_dataframes, ignore_index=True)
    
    print(f"\nTotal combined records to load: {len(final_gdf)}")
    return final_gdf

# -------------------------------------------------------
# LOAD
# -------------------------------------------------------

def load_to_postgis(gdf):
    print("\nConnecting to the database...")
    engine = create_engine(
        f"postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
    )

    try:
        with engine.begin() as connection:
            if TRUNCATE_BEFORE_LOAD:
                # Dynamically get the list of categories we are updating
                categories_to_delete = tuple(TARGETS.keys())
                print(f"Removing old records for {categories_to_delete} from the database...")
                
                # Delete only the categories we are currently updating
                delete_query = f"DELETE FROM {TABLE_NAME} WHERE category IN {categories_to_delete};"
                connection.execute(text(delete_query))

            print("Loading new data into PostGIS...")
            
            gdf.to_postgis(
                name=TABLE_NAME,
                con=connection,
                if_exists="append",
                index=False,
                dtype={'geom': Geometry('POINT', srid=4326)}
            )
        print("SUCCESS! Data has been successfully loaded into your SQL table!")
    except Exception as e:
        print(f"Error occurred while loading to database: {e}")

# -------------------------------------------------------
# MAIN ETL
# -------------------------------------------------------

def run_etl():
    try:
        gdf = extract_transform()
        load_to_postgis(gdf)
    except Exception as e:
        print(f"ETL Process Error: {e}")

if __name__ == "__main__":
    run_etl()