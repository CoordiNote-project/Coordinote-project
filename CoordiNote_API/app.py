from flask import (
    Flask,
    request,
    jsonify,
    )
import psycopg2 # PostgreSQL adapter for Python
from psycopg2.extras import RealDictCursor # This allows us to get query results as dictionaries instead of tuples
from psycopg2.pool import SimpleConnectionPool # This allows us to create a pool of database connections that can be reused, improving performance
from passlib.hash import bcrypt # This is a library for hashing passwords securely, we will use it to hash user passwords before storing them in the database
# from utils import format_geojson
import uuid # for generating unique identifiers, we will use it to generate unique IDs for users and notes
from datetime import datetime, timedelta # for working with dates and times, we will use it to set expiration times for authentication tokens


# Database configuration

DB_CONFIG = {
    "database": "CoordiNote_API", # The name of the database we will connect to --> CHANGE IT!!!
    "user": "postgres",
    "password": "postgres",
    "host": "localhost",
    "port": "5432"
}


# Create connection pool

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

# ---------------------------------
# Create Flask app
# ---------------------------------

app = Flask(__name__)

# ---------------------------------
# Helper functions
# ---------------------------------

def get_db_connection():
    return db_pool.getconn()

def release_db_connection(conn):
    db_pool.putconn(conn)

# ---------------------------------
# Test route
# ---------------------------------

@app.route("/")
def home():
    return jsonify({"message": "Coordinote API is running"})

# ---------------------------------
# Run server
# ---------------------------------

if __name__ == "__main__":
    app.run(debug=True)
