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
from utils import format_geojson

# Database configuration

DB_CONFIG = {
    "database": "coordinote_db", # The name of the database we will connect to (specific for me, Marie - we need to update this)
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

# Create Flask app
app = Flask(__name__)


# Helper functions
def get_db_connection():
    return db_pool.getconn()
# To release a db connection back to the pool after it's been used. It takes a connection object as an argument and calls the putconn method of the connection pool to return the connection to the pool for reuse.
def release_db_connection(conn):
    db_pool.putconn(conn)


# Test route
@app.route("/")
def home():
    return jsonify({"message": "Coordinote API is running!"})

# Test database connection route
@app.route("/test-db")
def test_db():
    conn = get_db_connection()
    cur = conn.cursor()
    
    cur.execute("SELECT NOW();")
    result = cur.fetchone()
    
    release_db_connection(conn)
    
    return jsonify(result)

# User registration route
@app.route("/users/register", methods=["POST"])
def register_user():
    data = request.get_json()

    username = data.get("username")
    password = data.get("password")

    if not username or not password:
        return jsonify({"error": "Username and password required"}), 400

    # Hash password BEFORE database logic
    hashed_password = bcrypt.hash(password)

    conn = get_db_connection()
    cur = conn.cursor()

    try:
        cur.execute("""
            INSERT INTO users (us_id, us_name, pwd)
            VALUES (DEFAULT, %s, %s)
            RETURNING us_id;
        """, (username, hashed_password))

        user_id = cur.fetchone()["us_id"]
        conn.commit()

    except Exception as e:
        conn.rollback()
        release_db_connection(conn)
        return jsonify({"error": str(e)}), 500

    release_db_connection(conn)

    return jsonify({
        "message": "User created successfully",
        "user_id": user_id
    })

# User login route
@app.route("/users/login", methods=["POST"])
def login_user():
    data = request.get_json()
    username = data.get("username")
    password = data.get("password")

    if not username or not password:
        return jsonify({"error": "Username and password required"}), 400

    conn = get_db_connection()
    cur = conn.cursor()

    cur.execute("SELECT us_id, pwd FROM users WHERE us_name = %s;", (username,))
    user = cur.fetchone()
    release_db_connection(conn)

    if not user:
        return jsonify({"error": "User not found"}), 404

    if bcrypt.verify(password, user["pwd"]):
        return jsonify({"message": "Login successful", "user_id": user["us_id"]})
    else:
        return jsonify({"error": "Incorrect password"}), 401

# Create universes route
@app.route("/universes", methods=["GET", "POST"])
def universes():
    conn = get_db_connection()
    cur = conn.cursor()

    if request.method == "POST":
        name = request.json.get("name")
        cur.execute("INSERT INTO universe (uni_id, uni_name) VALUES (DEFAULT, %s) RETURNING uni_id;", (name,))
        uni_id = cur.fetchone()["uni_id"]
        conn.commit()
        release_db_connection(conn)
        return jsonify({"message": "Universe created", "uni_id": uni_id}), 201

    # GET universes
    cur.execute("SELECT uni_id, uni_name FROM universe;")
    universes_list = cur.fetchall()
    release_db_connection(conn)
    return jsonify(universes_list)

# Messages route
@app.route("/messages", methods=["GET", "POST"])
def messages():
    conn = get_db_connection()
    cur = conn.cursor()

    if request.method == "POST":
        data = request.get_json()

        m_type = data.get("m_type")  # "simple" or "question"
        unl_rad = data.get("unl_rad")  # in meters
        view_once = data.get("view_once")  # how many times a user can view
        m_txt = data.get("m_txt")  # message content
        creator = data.get("creator")  # us_id of the user creating the message
        uni_id = data.get("uni_id")  # universe ID
        q_multi = data.get("q_multi")  # question ID if type="question", optional
        location_id = data.get("location_id")  # optional, POI or coordinates

        # Validate required fields
        if not all([m_type, unl_rad, view_once, m_txt, creator, uni_id]):
            release_db_connection(conn)
            return jsonify({"error": "Missing required fields"}), 400

        crt_time = datetime.utcnow()  # current UTC timestamp
        status = False  # message initially unopened

        try:
            cur.execute("""
                INSERT INTO messages (
                    m_type, unl_rad, crt_time, view_once, status, m_txt, creator, uni_id, q_multi, location_id
                )
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                RETURNING m_id;
            """, (m_type, unl_rad, crt_time, view_once, status, m_txt, creator, uni_id, q_multi, location_id))

            m_id = cur.fetchone()["m_id"]
            conn.commit()
            return jsonify({"message": "Message created", "m_id": m_id}), 201

        except Exception as e:
            conn.rollback()
            return jsonify({"error": str(e)}), 500

        finally:
            release_db_connection(conn)

    # GET messages
    uni_id = request.args.get("uni_id")
    user_id = request.args.get("user_id")  # optional, for view_once logic

    if not uni_id:
        release_db_connection(conn)
        return jsonify({"error": "uni_id query parameter required"}), 400

    try:
        cur.execute("""
            SELECT m_id, m_type, unl_rad, crt_time, view_once, status, m_txt, creator, uni_id, q_multi, location_id
            FROM messages
            WHERE uni_id = %s
        """, (uni_id,))

        messages_list = cur.fetchall()

        # Apply view_once filtering if user_id provided
        if user_id:
            for msg in messages_list:
                cur.execute("""
                    SELECT COUNT(*) as seen_count
                    FROM mSeen
                    WHERE m_id = %s AND us_id = %s
                """, (msg["m_id"], user_id))
                seen_count = cur.fetchone()["seen_count"]

                if seen_count >= msg["view_once"]:
                    msg["m_txt"] = "[Message view limit reached]"

        return jsonify(messages_list)

    finally:
        release_db_connection(conn)


# Questions route


# Run server

if __name__ == "__main__":
    app.run(debug=True)
