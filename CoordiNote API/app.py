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

        us_id = cur.fetchone()["us_id"]
        conn.commit()

    except Exception as e:
        conn.rollback()
        release_db_connection(conn)
        return jsonify({"error": str(e)}), 500

    release_db_connection(conn)

    return jsonify({
        "message": "User created successfully",
        "us_id": us_id
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

    us_id, error = get_current_user()
    if error:
        return jsonify({"error": error}), 401

    conn = get_db_connection()
    cur = conn.cursor()

    try:
        # Create universe
        if request.method == "POST":
            data = request.get_json(silent=True)
            if not data:
                return jsonify({"error": "Invalid JSON"}), 400

            name = data.get("name")
            access = data.get("access", False)  # boolean: false = public and is default, true = private

            if not name:
                return jsonify({"error": "Universe name required"}), 400

            # Insert universe and get uni_id
            cur.execute("""
                INSERT INTO universes (uni_name, access)
                VALUES (%s, %s)
                RETURNING uni_id;
            """, (name, access))
            uni_id = cur.fetchone()["uni_id"]

            # Add creator to user_univ
            cur.execute("""
                INSERT INTO user_univ (us_id, uni_id)
                VALUES (%s, %s)
                ON CONFLICT DO NOTHING;
            """, (us_id, uni_id))
            
            conn.commit()

            return jsonify({
                "message": "Universe created",
                "uni_id": uni_id
            }), 201

        # GET only universes the user belongs to
        cur.execute("""
            SELECT u.uni_id, u.uni_name, u.access
            FROM universes u
            JOIN user_univ uu ON u.uni_id = uu.uni_id
            WHERE uu.us_id = %s;
        """, (us_id,))

        universes_list = cur.fetchall()
        return jsonify(universes_list)

        cur.execute("""
            SELECT m.m_id, m.m_type, m.unl_rad, m.crt_time,
                m.view_once, m.m_txt, m.creator,
                m.uni_id, m.poll, m.location_id
            FROM messages m
            JOIN user_univ uu ON m.uni_id = uu.uni_id
            WHERE m.uni_id = %s
            AND uu.us_id = %s
        """, (uni_id, us_id))

        universes_list = cur.fetchall()
        return jsonify(universes_list)

    except Exception as e:
        conn.rollback()
        return jsonify({"error": str(e)}), 500

    finally:
        release_db_connection(conn)

# Join universe route
@app.route("/universes/<int:uni_id>/join", methods=["POST"])
def join_universe(uni_id):

    us_id, error = get_current_user()
    if error:
        return jsonify({"error": error}), 401

    conn = get_db_connection()
    cur = conn.cursor()

    try:
        # Check universe exists
        cur.execute("SELECT 1 FROM universes WHERE uni_id = %s;", (uni_id,))
        if not cur.fetchone():
            return jsonify({"error": "Universe not found"}), 404

        # Insert membership = add user to universe. If already a member, do nothing
        cur.execute("""
            INSERT INTO user_univ (us_id, uni_id)
            VALUES (%s, %s)
            ON CONFLICT DO NOTHING;
        """, (us_id, uni_id))

        conn.commit()

        return jsonify({"message": "Joined universe"}), 200

    except Exception as e:
        conn.rollback()
        return jsonify({"error": str(e)}), 500

    finally:
        release_db_connection(conn)

# Leave universe route
@app.route("/universes/<int:uni_id>/leave", methods=["POST"])
def leave_universe(uni_id):

    us_id, error = get_current_user()
    if error:
        return jsonify({"error": error}), 401

    conn = get_db_connection()
    cur = conn.cursor()

    try:
        cur.execute("""
            DELETE FROM user_univ
            WHERE us_id = %s AND uni_id = %s;
        """, (us_id, uni_id))

        conn.commit()

        return jsonify({"message": "Left universe"}), 200

    finally:
        release_db_connection(conn)

# Messages route: POST + GET
@app.route("/messages", methods=["GET", "POST"])
def messages():

    us_id, error = get_current_user()
    if error:
        return jsonify({"error": error}), 401

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
        uni_id = data.get("uni_id")
        poll = data.get("poll")
        location_id = data.get("location_id")

        if not m_type or unl_rad is None or view_once is None or not m_txt or not uni_id:
            release_db_connection(conn)
            return jsonify({"error": "Missing required fields"}), 400

        crt_time = datetime.utcnow()

        # Check membership in universe
        cur.execute("""
            SELECT 1 FROM user_univ
            WHERE us_id = %s AND uni_id = %s;
        """, (us_id, uni_id))

        if not cur.fetchone():
            return jsonify({"error": "You are not a member of this universe"}), 403

        try:
            cur.execute("""
                INSERT INTO messages (
                    m_type, unl_rad, crt_time, view_once, m_txt, creator, uni_id, poll, location_id
                ) VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s)
                RETURNING m_id;
            """, (m_type, unl_rad, crt_time, view_once, m_txt, us_id, uni_id, poll, location_id))

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
    # user comes from token

    if not uni_id:
        release_db_connection(conn)
        return jsonify({"error": "uni_id query parameter required"}), 400

    try:
        cur.execute("""
            SELECT m_id, m_type, unl_rad, crt_time, view_once, m_txt, creator, uni_id, poll, location_id
            FROM messages m
            JOIN user_univ uu ON m.uni_id = uu.uni_id
            WHERE m.uni_id = %s
            AND uu.us_id = %s
        """, (uni_id, us_id))
        messages_list = cur.fetchall()

        return jsonify(messages_list)

    finally:
        release_db_connection(conn)


# Mark message as opened per user (token required)
@app.route("/messages/<int:m_id>/open", methods=["POST"])
def open_message(m_id):

    # Get user from token
    us_id, error = get_current_user()
    if error:
        return jsonify({"error": error}), 401

    conn = get_db_connection()
    cur = conn.cursor()

    try:
        # GET message
        cur.execute("""
            SELECT m_id, m_txt, view_once, uni_id
            FROM messages
            WHERE m_id = %s
        """, (m_id,))
        message = cur.fetchone()

        if not message:
            return jsonify({"error": "Message not found"}), 404

        # Check user is member of the universe
        cur.execute("""
            SELECT 1 FROM user_univ
            WHERE us_id = %s AND uni_id = %s
        """, (us_id, message["uni_id"]))

        if not cur.fetchone():
            return jsonify({"error": "Not allowed"}), 403

        # If message is view-once
        if message["view_once"]:

            # Check if already seen
            cur.execute("""
                SELECT 1 FROM seen
                WHERE m_id = %s AND us_id = %s
            """, (m_id, us_id))
            already_seen = cur.fetchone()

            if already_seen:
                return jsonify({"status": "already viewed"}), 403

            # First time opening -> insert into seen
            cur.execute("""
                INSERT INTO seen (m_id, us_id)
                VALUES (%s, %s)
            """, (m_id, us_id))

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
    us_id, error = get_current_user()

    if error:
        return jsonify({"error": error}), 401

    return jsonify({
        "message": "Access granted",
        "us_id": us_id
    })


# Questions/poll route - Beko


# Run server

if __name__ == "__main__":
    app.run(debug=True)
