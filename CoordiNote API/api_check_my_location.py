from flask import Flask, request, jsonify
import psycopg2 
from psycopg2.extras import RealDictCursor 
from psycopg2.pool import SimpleConnectionPool 
from passlib.hash import bcrypt 
import uuid 
from datetime import datetime, timedelta 
import json 

# DATABASE CONFIGURATION

DB_CONFIG = {
    "database": "coordinote_share", 
    "user": "postgres",
    "password": "postgres",      
    "host": "localhost",
    "port": "5432"
}

# Create a connection pool to handle multiple simultaneous requests efficiently
db_pool = SimpleConnectionPool(
    minconn=1,
    maxconn=10,
    database=DB_CONFIG["database"],
    user=DB_CONFIG["user"],
    password=DB_CONFIG["password"],
    host=DB_CONFIG["host"],
    port=DB_CONFIG["port"],
    cursor_factory=RealDictCursor
)

# Initialize the Flask application
app = Flask(__name__)

# -------------------------------------------------------------------
# HELPER FUNCTIONS

def get_db_connection():
    """Fetches a database connection from the connection pool."""
    return db_pool.getconn()

def release_db_connection(conn):
    """Returns the database connection back to the pool."""
    db_pool.putconn(conn)

def get_current_user():
    """Extracts the token from the header and validates the user session."""
    token = request.headers.get("Authorization")
    if not token:
        return None, "Missing token"

    conn = get_db_connection()
    cur = conn.cursor()
    try:
        cur.execute("""
            SELECT us_id, expires_at
            FROM sessions
            WHERE token = %s
        """, (token,))
        session = cur.fetchone()

        if not session:
            return None, "Invalid token"
        if session["expires_at"] < datetime.utcnow():
            return None, "Token expired"

        return session["us_id"], None
    finally:
        release_db_connection(conn)

# -------------------------------------------------------------------
# ROUTES / ENDPOINTS


# Home / Health Check Route
@app.route("/")
def home():
    return jsonify({"message": "Coordinote API is running securely!"})

# User Registration Route
@app.route("/users/register", methods=["POST"])
def register_user():
    data = request.get_json(silent=True)
    if not data:
        return jsonify({"error": "Invalid or missing JSON body"}), 400

    username = data.get("username")
    password = data.get("password")
    repeat_password = data.get("repeat_password")

    if not username or not password or not repeat_password:
        return jsonify({"error": "All fields required"}), 400
    if password != repeat_password:
        return jsonify({"error": "Passwords do not match"}), 400

    # Hash the password securely using bcrypt
    hashed_password = bcrypt.hash(password)
    
    conn = get_db_connection()
    cur = conn.cursor()

    try:
        cur.execute("""
            INSERT INTO users (us_id, us_name, pwd)
            VALUES (DEFAULT, %s, %s)
            RETURNING us_id;
        """, (username, hashed_password))
        us_id = cur.fetchone()["us_id"]
        conn.commit()
    except Exception as e:
        conn.rollback()
        return jsonify({"error": str(e)}), 500
    finally:
        release_db_connection(conn)

    return jsonify({"message": "User created successfully", "us_id": us_id}), 201


# -------------------------------------------------------------------
# LOCATIONS ROUTE (Provides GeoJSON for the Frontend Map)

@app.route("/locations", methods=["GET"])
def get_locations():
    """
    Fetches Points of Interest (POIs) from the database and returns them 
    in a standard GeoJSON FeatureCollection format for frontend map libraries.
    """
    conn = get_db_connection()
    cur = conn.cursor()

    try:
        # Optional: Frontend can filter by category (e.g., ?category=metro)
        category_filter = request.args.get("category")

        if category_filter:
            cur.execute("""
                SELECT location_id, l_name, category, ST_AsGeoJSON(geom) as geometry
                FROM locations
                WHERE category = %s;
            """, (category_filter,))
        else:
            cur.execute("""
                SELECT location_id, l_name, category, ST_AsGeoJSON(geom) as geometry
                FROM locations;
            """)
            
        locations = cur.fetchall()
        
        # Build the GeoJSON structure
        features = []
        for loc in locations:
            feature = {
                "type": "Feature",
                "geometry": json.loads(loc["geometry"]), # Parse the PostGIS string into a JSON object
                "properties": {
                    "location_id": loc["location_id"],
                    "name": loc["l_name"],
                    "category": loc["category"]
                }
            }
            features.append(feature)
            
        return jsonify({
            "type": "FeatureCollection",
            "features": features
        }), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        release_db_connection(conn)


# -------------------------------------------------------------------
# NEARBY MESSAGES ROUTE (Spatial Proximity & Security Logic)

@app.route("/messages/nearby", methods=["GET"])
def nearby_messages():
    """
    Retrieves messages within a search radius.
    Checks user's distance against the message's specific unlock radius (unl_rad).
    If the user is too far, the message content is hidden for security.
    """
    lat = request.args.get("lat")
    lon = request.args.get("lon")
    uni_id = request.args.get("uni_id")
    
    # Default search radius for map visibility is 1000 meters
    search_radius = request.args.get("radius", 1000)

    if not lat or not lon or not uni_id:
        return jsonify({"error": "lat, lon and uni_id are required parameters"}), 400

    conn = get_db_connection()
    cur = conn.cursor()

    try:
        cur.execute("""
            SELECT 
                m.m_id, 
                m.m_type, 
                m.unl_rad,
                m.view_once,
                l.location_id,
                l.l_name as location_name,
                
                -- Calculate the exact distance in meters using PostGIS
                ST_Distance(
                    m.geom::geography, 
                    ST_SetSRID(ST_MakePoint(%s, %s), 4326)::geography
                ) as distance_meters,
                
                -- Determine if the user is close enough to unlock the message
                CASE 
                    WHEN ST_Distance(m.geom::geography, ST_SetSRID(ST_MakePoint(%s, %s), 4326)::geography) <= m.unl_rad 
                    THEN true 
                    ELSE false 
                END as can_open,

                -- SECURITY SHIELD: Hide actual content if the user is outside the unlock radius
                CASE 
                    WHEN ST_Distance(m.geom::geography, ST_SetSRID(ST_MakePoint(%s, %s), 4326)::geography) <= m.unl_rad 
                    THEN m.m_txt 
                    ELSE 'This message is locked. Get closer to read it!' 
                END as m_txt

            FROM messages m
            JOIN locations l ON m.location_id = l.location_id
            WHERE m.uni_id = %s
            -- Only fetch messages within the general search radar (e.g., 1000m)
            AND ST_DWithin(
                m.geom::geography,
                ST_SetSRID(ST_MakePoint(%s, %s), 4326)::geography,
                %s
            );
        """, (lon, lat, lon, lat, lon, lat, uni_id, lon, lat, search_radius))
        
        messages_list = cur.fetchall()
        return jsonify(messages_list), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        release_db_connection(conn)

# -------------------------------------------------------------------
# SERVER EXECUTION

if __name__ == "__main__":
    app.run(debug=True)