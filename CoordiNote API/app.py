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

def get_current_user():
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
    data = request.get_json(silent=True)
    if not data:
        return jsonify({"error": "Invalid or missing JSON"}), 400
    
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
    
    if bcrypt.verify(password, user["pwd"]): # Verify the provided password against the hashed password stored in the database using bcrypt's verify function. If the verification is successful, it means the provided password is correct.
        # Generate token
        token = str(uuid.uuid4())

        # Set expiration (72 hours)
        expires_at = datetime.utcnow() + timedelta(hours=72)

        conn = get_db_connection()
        cur = conn.cursor()

        try:
            cur.execute("""
                INSERT INTO sessions (us_id, token, expires_at)
                VALUES (%s, %s, %s)
            """, (user["us_id"], token, expires_at))

            conn.commit()

        except Exception as e:
            conn.rollback()
            release_db_connection(conn)
            return jsonify({"error": str(e)}), 500

        release_db_connection(conn)

        return jsonify({
            "message": "Login successful",
            "token": token
        })
    else:
        return jsonify({"error": "Username and password do not match. Try again."}), 401

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

# Messages route: POST + GET
@app.route("/messages", methods=["GET", "POST"])
def messages():
    conn = get_db_connection()
    cur = conn.cursor()

    if request.method == "POST":
        data = request.get_json(silent=True)
        if not data:
            return jsonify({"error": "Invalid or missing JSON"}), 400
        m_type = data.get("m_type")  # "text" or "poll"
        unl_rad = data.get("unl_rad")
        view_once = data.get("view_once")  # true/false
        m_txt = data.get("m_txt")
        creator = data.get("creator")
        uni_id = data.get("uni_id")
        q_multi = data.get("q_multi")
        location_id = data.get("location_id")

        if not m_type or unl_rad is None or view_once is None or not m_txt or not creator or not uni_id:
            release_db_connection(conn)
            return jsonify({"error": "Missing required fields"}), 400

        crt_time = datetime.utcnow()

        try:
            cur.execute("""
                INSERT INTO messages (
                    m_type, unl_rad, crt_time, view_once, m_txt, creator, uni_id, q_multi, location_id
                ) VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s)
                RETURNING m_id;
            """, (m_type, unl_rad, crt_time, view_once, m_txt, creator, uni_id, q_multi, location_id))

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
    user_id = request.args.get("user_id")  # optional

    if not uni_id:
        release_db_connection(conn)
        return jsonify({"error": "uni_id query parameter required"}), 400

    try:
        cur.execute("""
            SELECT m_id, m_type, unl_rad, crt_time, view_once, m_txt, creator, uni_id, q_multi, location_id
            FROM messages
            WHERE uni_id = %s
        """, (uni_id,))
        messages_list = cur.fetchall()

        return jsonify(messages_list)

    finally:
        release_db_connection(conn)


# Mark message as seen --> WE NEED TO IMPROVE THIS PART - USER WILL NOT INSERT THE DATA, IT NEEDS TO BE AUTOMATICALLY INSERTED WHEN THE USER OPENS THE MESSAGE, WE CAN USE A NEW ENDPOINT FOR THIS OR WE CAN USE THE SAME ENDPOINT FOR GETTING THE MESSAGES AND MARKING THEM AS SEEN
#@app.route("/messages/seen", methods=["POST"])
#def mark_message_seen():
#    data = request.get_json(silent=True)

#    if not data:
#        return jsonify({"error": "Invalid or missing JSON"}), 400
    
#    m_id = data.get("m_id")
#    us_id = data.get("us_id")

#    if not m_id or not us_id:
#        return jsonify({"error": "m_id and us_id required"}), 400

#    conn = get_db_connection()
#    cur = conn.cursor()

#    try:
        # insert into seen table
#        cur.execute("""
#            INSERT INTO seen (m_id, us_id)
#            VALUES (%s, %s)
#            ON CONFLICT (m_id, us_id) DO NOTHING;
#        """, (m_id, us_id))
        
#        conn.commit()
#        return jsonify({"message": "Message marked as seen"}), 200

#    except Exception as e:
#        conn.rollback()
#        return jsonify({"error": str(e)}), 500

#    finally:
#        release_db_connection(conn)

# Mark message as opened per user
@app.route("/messages/<int:m_id>/open", methods=["POST"])
def open_message(m_id):
    data = request.get_json(silent=True)

    if not data:
        return jsonify({"error": "Invalid JSON"}), 400

    user_id = data.get("user_id")

    if not user_id:
        return jsonify({"error": "user_id required"}), 400

    conn = get_db_connection()
    cur = conn.cursor()

    try:
        # Get message
        cur.execute("""
            SELECT m_id, m_txt, view_once
            FROM messages
            WHERE m_id = %s
        """, (m_id,))
        message = cur.fetchone()

        if not message:
            return jsonify({"error": "Message not found"}), 404

        # If view_once = TRUE
        if message["view_once"]:

            cur.execute("""
                SELECT 1 FROM seen
                WHERE m_id = %s AND us_id = %s
            """, (m_id, user_id))

            already_seen = cur.fetchone()

            if already_seen:
                return jsonify({"status": "already viewed"}), 403

            # First time opening → insert
            cur.execute("""
                INSERT INTO seen (m_id, us_id)
                VALUES (%s, %s)
            """, (m_id, user_id))

            conn.commit()

        # Return message content
        return jsonify({
            "status": "opened",
            "message": message["m_txt"]
        }), 200

    except Exception as e:
        conn.rollback()
        return jsonify({"error": str(e)}), 500

    finally:
        release_db_connection(conn)


# Nearby messages route
@app.route("/messages/nearby", methods=["GET"])
def nearby_messages():
    lat = request.args.get("lat")
    lon = request.args.get("lon")
    uni_id = request.args.get("uni_id")

    if not lat or not lon or not uni_id:
        return jsonify({"error": "lat, lon and uni_id required"}), 400

    conn = get_db_connection()
    cur = conn.cursor()

    try:
        cur.execute("""
            SELECT m.m_id, m.m_txt, m.unl_rad, l.location_id
            FROM messages m
            JOIN locations l ON m.location_id = l.location_id
            WHERE m.uni_id = %s
            AND ST_DWithin(
                l.geom::geography,
                ST_SetSRID(ST_MakePoint(%s, %s), 4326)::geography,
                m.unl_rad
            );
        """, (uni_id, lon, lat))
        messages_list = cur.fetchall()
        return jsonify(messages_list)

    finally:
        release_db_connection(conn)

# Protected test route
@app.route("/protected-test")
def protected_test():
    user_id, error = get_current_user()

    if error:
        return jsonify({"error": error}), 401

    return jsonify({
        "message": "Access granted",
        "user_id": user_id
    })


# Questions/poll route - Beko


# Run server

if __name__ == "__main__":
    app.run(debug=True)
