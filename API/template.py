from flask import ( # This is a common way to import multiple functions from a module in Python, it allows us to use the functions directly without prefixing them with "flask."
    Flask, # Flask is the main class for creating a Flask application
    request,
    jsonify,
    )
import psycopg2
from psycopg2.extras import RealDictCursor
from psycopg2.pool import SimpleConnectionPool
from utils import format_geojson

DB_CONFIG = {
    "database": "taxidb",
    "user": "postgres",
    "password": "postgres",
    "host": "localhost",
    "port": "5432"}

# Notice, normally this is set with environment variables on the server
# machine do avoid exposing the credentials. Something like
# import os
# DB_CONFIG = {}
# DB_CONFIG['database'] = os.environ.get('DATABASE')
# DB_CONFIG['username'] = os.environ.get('USERNAME')
# ...

# Create pooling to the database maximum 10 connections
# This allows to economize database connections
db_pool = SimpleConnectionPool(
    minconn=1,
    maxconn= 10,
    database=DB_CONFIG["database"],
    user=DB_CONFIG["user"],
    password=DB_CONFIG["password"],
    host=DB_CONFIG["host"],
    port=DB_CONFIG["port"],
    cursor_factory=RealDictCursor
)

# Create a flask application
app = Flask(__name__)

# Database connection function
# that makes use of pooling
def get_db_connection():
    return db_pool.getconn()

# Function to release the connection and
# make it available in the pooling
def release_db_connection(conn):
    db_pool.putconn(conn)

# GET "all" rides from pa.rides
# We are limiting it to 50 to be faster to retrieve
@app.route('/rides3', methods=['GET'])
def get_rides():
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("""SELECT * FROM pa.rides LIMIT 50""")
        rides = cursor.fetchall()
    finally:
        cursor.close()
        release_db_connection(conn)
    return jsonify(rides)

# GET all rides from pa.rides_geojson getting a GeoJSON column
@app.route('/rides2', methods=['GET']) # This is a different route than the previous one, it shows how to get a GeoJSON column from the database and return it in the response
def get_rides2():
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(
            """SELECT id,
	           pickup_datetime, 
	           dropoff_datetime,
	           passenger_count,
	           st_asGeoJSON(st_makeline(pickup, dropoff))::json as geom
               FROM pa.rides Limit 50; """)
        rides = cursor.fetchall()
    except Exception as e:
        return jsonify({"error": 'Failed to fetch rides'}), 500
    finally:
        cursor.close()
        release_db_connection(conn)
    return jsonify(rides)

# GET all rides from pa.rides_geojson using a prepared view (00_create_rides_geojson_view)formatted as a proper GeoJSON
@app.route('/rides', methods=['GET'])
def get_rides3():
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("""SELECT * FROM pa.rides_geojson LIMIT 50""")
        rides = cursor.fetchall()
    except Exception as e:
        return jsonify({"error": 'Failed to fetch rides'}), 500
    finally:
        cursor.close()
        release_db_connection(conn)
    # Format the all result as a GeoJSON
    rides = format_geojson(rides)
    return jsonify(rides)

# GET a single ride by id from pa.rides_geojson
@app.route('/rides/<id>', methods=['GET'])
def get_ride(id):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("SELECT * FROM pa.rides_geojson WHERE id = %s", (id,))
        ride = cursor.fetchall()
    except Exception as e:
        return jsonify({"error": f'Failed to fetch ride {id}'}), 500
    finally:
        cursor.close()
        release_db_connection(conn)
    if not ride:
        return jsonify({"message": f"Ride {id} not found"}), 404
    
    # Format results as GeoJSON
    ride = format_geojson(ride)
    return jsonify(ride)

# POST a new ride to sa.rides
@app.route('/rides', methods=['POST'])
def create_ride():
    body = request.get_json()
    conn = get_db_connection()
    cursor = conn.cursor()
    query = """
        INSERT INTO sa.rides (
            pickup_datetime, dropoff_datetime, pickup_latitude, pickup_longitude,
            dropoff_latitude, dropoff_longitude, passenger_count, rate_code,
            payment_type, tip_amount, total_amount
        )
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        RETURNING id
    """
    values = (
        body["pickup_datetime"], body["dropoff_datetime"], body["pickup_latitude"], 
        body["pickup_longitude"], body["dropoff_latitude"], body["dropoff_longitude"], 
        body["passenger_count"], body["rate_code"], body["payment_type"], 
        body["tip_amount"], body["total_amount"]
    )
    try:
        cursor.execute(query, values)
        # This gets the id of the created ride because of the "RETURNING id" in the insert query
        created_id = cursor.fetchone()["id"]
        conn.commit()
    except Exception as e:
        return jsonify({"error": 'Failed to post new ride'}), 500
    finally:
        cursor.close()
        release_db_connection(conn)
    return jsonify({"message": f"New {created_id} ride created"}), 201

# PUT method to update a ride in pa.rides by id
@app.route('/rides/<id>', methods=['PUT'])
def update_ride(id):
    body = request.get_json()

    ALLOWED_UPDATE_FIELDS = [
        "pickup_datetime",
        "dropoff_datetime",
        "passenger_count",
        "rate_code",
        "payment_type",
        "tip_amount",
        "total_amount"
    ]
    
    conn = get_db_connection()
    cursor = conn.cursor()
    # Build the update query dynamically
    try:
        for key, value in body.items():
            # Make sure there's no code injection using the fields
            if key not in ALLOWED_UPDATE_FIELDS:
                return jsonify({"error": f"Invalid field: {key}"}), 400
            query = "UPDATE pa.rides SET " + key + " = %s WHERE id = %s"
            cursor.execute(query, (value, id,))
        conn.commit()
    except Exception as e:
        return jsonify({"error": f'Failed to update ride {id}'}), 500
    finally:
        cursor.close()
        release_db_connection(conn)

    return jsonify({"message": f"Ride {id} updated successfully"})

# DELETE a ride by id from sa.rides
@app.route('/rides/<id>', methods=['DELETE'])
def delete_ride(id):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("DELETE FROM pa.rides WHERE id = %s", (id,))
        conn.commit()
    except Exception as e:
        return jsonify({"error": f"Failed to delete ride {id}"}), 500
    finally:
        cursor.close()
        release_db_connection(conn)
    return jsonify({"message": f"Ride {id} was deleted successfully"})

# EXERCISE
# CREATE A GET route to get monthly statistics
# Tips: Check ETL Query results for a query that gives you that

if __name__ == '__main__':
    app.run(debug=True)
