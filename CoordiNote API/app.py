from flask import (
    Flask,
    request,
    jsonify,
    )
import psycopg2 # PostgreSQL adapter for Python
from psycopg2.extras import RealDictCursor # This allows us to get query results as dictionaries instead of tuples
from psycopg2.pool import SimpleConnectionPool # This allows us to create a pool of database connections that can be reused, improving performance
from psycopg2 import errors # This module contains exceptions that can be raised by psycopg2, we're using it to handle duplicates uni_name error 
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

# Reads Authorization header (accepts both raw token and "Bearer <token>"),
# looks it up in sessions table, returns (us_id, None) or (None, error_message)
def get_current_user():
    raw = request.headers.get("Authorization", "")
    token = raw.replace("Bearer ", "").strip()

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

# User registration route
@app.route("/users/register", methods=["POST"])
def register_user():
    data = request.get_json(silent=True)

    if not data:
        return jsonify({"error": "Invalid or missing JSON body"}), 400

    username = data.get("username", "").strip()
    password = data.get("password")
    repeat_password = data.get("repeat_password")

    if not username or not password or not repeat_password:
        return jsonify({"error": "All fields required"}), 400

    if password != repeat_password:
        return jsonify({"error": "Passwords do not match"}), 400

    # Hash password before storing in the database
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
        
        return jsonify({
        "message": "User created successfully",
        "us_id": us_id
        }), 201 # 201 Created status code indicates that the request has succeeded and a new resource has been created as a result. It's the appropriate response for successful POST requests that create new resources.

    except psycopg2.errors.UniqueViolation:
        conn.rollback()
        return jsonify({
            "error": "Username already exists"
        }), 400
    
    except Exception as e:
        conn.rollback()
        return jsonify({"error": str(e)
        }), 500

    finally:
        release_db_connection(conn)


# User login route
@app.route("/users/login", methods=["POST"])
def login_user():
    data = request.get_json(silent=True)
    if not data:
        return jsonify({"error": "Invalid or missing JSON"}), 400
    
    username = data.get("username", "").strip()
    password = data.get("password")
    if not username or not password:
        return jsonify({"error": "Username and password required"}), 400

    conn = get_db_connection()
    cur = conn.cursor()

# Query the database for a user with the provided username, ignoring case sensitivity. If a user is found, it retrieves the user's ID and hashed password. If no user is found, it returns a 404 error.
# If a user is found, it uses bcrypt to verify the provided password against the stored hashed password. If the verification is successful, it generates a unique token for the session, sets an expiration time of 72 hours, and stores this information in the sessions table.
# Finally, it returns a success message along with the generated token. If any errors occur during this process, appropriate error messages are returned with corresponding HTTP status codes.
    cur.execute("""
    SELECT us_id, us_name, pwd
        FROM users 
        WHERE LOWER(us_name) = LOWER(%s);
    """, (username,))
    user = cur.fetchone()
    release_db_connection(conn)

    if not user:
        return jsonify({"error": "User not found"}), 404
    
    # Verify the provided password against the hashed password stored in the database using bcrypt's verify function. If the verification is successful, it means the provided password is correct.
    if bcrypt.verify(password, user["pwd"]):
        token = str(uuid.uuid4()) # Generate token
        expires_at = datetime.utcnow() + timedelta(hours=72) # Set expiration (72 hours)

        conn = get_db_connection()
        cur = conn.cursor()

        try:
            cur.execute("""
                INSERT INTO sessions (us_id, token, expires_at)
                VALUES (%s, %s, %s)
            """, (user["us_id"], token, expires_at))

            conn.commit()

            return jsonify({
                "message": "Login successful",
                "token": token,
                "us_name": user["us_name"]
            }), 200
   
        except Exception as e:
            conn.rollback()
            return jsonify({"error": str(e)}), 500

        finally:
            release_db_connection(conn)
    else:
        return jsonify({"error": "Username and password do not match. Try again."}), 401

# SHOW ALL PUBLIC UNIVERSES route
@app.route("/universes/public", methods=["GET"])
def public_universes():
    conn = get_db_connection()
    cur = conn.cursor()

    try:
        cur.execute("""
            SELECT uni_name, descri
            FROM universes
            WHERE access = false;
        """)
        universes = cur.fetchall() # fetchall() retrieves all rows of a query result, returning them as a list of dictionaries (because we set cursor_factory=RealDictCursor when creating the connection pool). Each dictionary represents a row from the result set, with column names as keys and corresponding values as values. In this case, each dictionary will have keys "uni_name" and "descri" corresponding to the columns selected in the SQL query.
        return jsonify(universes) # jsonify() converts the list of dictionaries into a JSON response that can be sent back to the client. The resulting JSON will be an array of objects, where each object represents a public universe with its name and description.

    finally:
        release_db_connection(conn)

# GET: LIST universes the logged-in user belongs to
# POST: CREATE a new universe (creator is auto-joined)
@app.route("/universes", methods=["GET", "POST"])
def universes():
    us_id, error = get_current_user()
    if error:
        return jsonify({"error": error}), 401

    conn = get_db_connection()
    cur = conn.cursor()

    try:# Create universe
        if request.method == "POST":
            data = request.get_json(silent=True)
            if not data:
                return jsonify({"error": "Invalid JSON"}), 400

            uni_name = data.get("uni_name", "").strip()
            access = data.get("access", False)  # boolean: false = public and is default, true = private
            descri = data.get("descri")  # can be None

            if not uni_name:
                return jsonify({"error": "Universe name required"}), 400

            # Insert universe and get uni_id
            cur.execute("""
                INSERT INTO universes (uni_name, access, descri)
                VALUES (%s, %s, %s)
                RETURNING uni_id;
            """, (uni_name, access, descri))
            uni_id = cur.fetchone()["uni_id"]

            # ADD creator to the new universe (user_univ) automatically
            cur.execute("""
                INSERT INTO user_univ (us_id, uni_id)
                VALUES (%s, %s)
                ON CONFLICT DO NOTHING;
            """, (us_id, uni_id))

            conn.commit()
            return jsonify({
                "message": "Universe created"
            }), 201

        # GET only universes the user belongs to -> universe name, access type, description
        cur.execute("""
            SELECT u.uni_name, u.access, u.descri
            FROM universes u
            JOIN user_univ uu ON u.uni_id = uu.uni_id
            WHERE uu.us_id = %s;
        """, (us_id,))

        universes_list = cur.fetchall()
        return jsonify(universes_list)
        
    except psycopg2.errors.UniqueViolation:
        conn.rollback()
        return jsonify({
            "error": "Universe name already exists. Be more original."
        }), 400

    except Exception as e:
        conn.rollback()
        return jsonify({"error": str(e)}), 500

    finally:
        release_db_connection(conn)

# JOIN an existing UNIVERSE by name (uni_name)
@app.route("/universes/join", methods=["POST"])
def join_universe():
    us_id, error = get_current_user()
    if error:
        return jsonify({"error": error}), 401

    data = request.get_json(silent=True)
    if not data:
        return jsonify({"error": "Invalid JSON"}), 400

    uni_name = data.get("uni_name", "").strip()
    if not uni_name:
        return jsonify({"error": "uni_name required"}), 400

    conn = get_db_connection()
    cur = conn.cursor()

    try:
        # does the universe exist? resolve uni_name to uni_id
        cur.execute("""
            SELECT uni_id FROM universes
            WHERE LOWER(uni_name) = LOWER(%s);
        """, (uni_name,))
        universe = cur.fetchone()

        if not universe:
            return jsonify({"error": "Universe not found"}), 404

        # Insert membership
        cur.execute("""
            INSERT INTO user_univ (us_id, uni_id)
            VALUES (%s, %s)
            ON CONFLICT DO NOTHING;
        """, (us_id, universe["uni_id"]))
       
        conn.commit()
        return jsonify({"message": f"Joined {uni_name}"}), 200

    except Exception as e:
        conn.rollback()
        return jsonify({"error": str(e)}), 500

    finally:
        release_db_connection(conn)

# Leave universe by uni_name
@app.route("/universes/leave", methods=["POST"])
def leave_universe():
    us_id, error = get_current_user()
    if error:
        return jsonify({"error": error}), 401

    data = request.get_json(silent=True)
    if not data:
        return jsonify({"error": "Invalid JSON"}), 400

    uni_name = data.get("uni_name", "").strip()
    if not uni_name:
        return jsonify({"error": "uni_name required"}), 400

    conn = get_db_connection()
    cur = conn.cursor()

    try:
        cur.execute("""
            SELECT uni_id FROM universes
            WHERE uni_name = %s;
        """, (uni_name,))
        universe = cur.fetchone()

        if not universe:
            return jsonify({"error": "Universe not found"}), 404

        cur.execute("""
            DELETE FROM user_univ
            WHERE us_id = %s AND uni_id = %s;
        """, (us_id, universe["uni_id"]))

        conn.commit()
        return jsonify({"message": f"Left {uni_name}"}), 200

    except Exception as e:
            conn.rollback()
            return jsonify({"error": str(e)}), 500

    finally:
        release_db_connection(conn)


# MESSAGES: POST + GET rout
# POST /messages
# Handles both "text" and "poll" m_types.
@app.route("/messages", methods=["GET", "POST"])
def messages():
    us_id, error = get_current_user()
    if error:
        return jsonify({"error": error}), 401

    conn = get_db_connection()
    cur  = conn.cursor()

    # POST: create a new message
    if request.method == "POST":
        data = request.get_json(silent=True)
        if not data:
            return jsonify({"error": "Invalid or missing JSON"}), 400

        m_type = data.get("m_type") # "text" or "poll"
        uni_name = data.get("uni_name", "").strip() # universe name is provided by client for better UX, we will resolve it to uni_id and check membership in the backend
        unl_rad = data.get("unl_rad")
        view_once = data.get("view_once", False)
        latitude = data.get("latitude")
        longitude = data.get("longitude")
        m_txt = data.get("m_txt") # required for text messages
        poll = data.get("poll") # required for polls
        
        # Validation and rules for message creation
        if m_type not in ("text", "poll"):
            release_db_connection(conn)
            return jsonify({"error": "m_type must be 'text' or 'poll'"}), 400

        if not uni_name or unl_rad is None or latitude is None or longitude is None:
            release_db_connection(conn)
            return jsonify({"error": "uni_name, unl_rad, latitude, longitude are required"}), 400

        if m_type == "text" and not m_txt:
            release_db_connection(conn)
            return jsonify({"error": "m_txt is required for text messages"}), 400

        if m_type == "poll":
            if not poll or not poll.get("p_txt"):
                release_db_connection(conn)
                return jsonify({"error": "poll.p_txt is required for polls"}), 400
            poll_options = poll.get("poll_options", [])
            if len(poll_options) < 2:
                release_db_connection(conn)
                return jsonify({"error": "Poll must have at least 2 options"}), 400

        try:
            # Check universe membership + resolve uni_name to uni_id
            cur.execute("""
                SELECT u.uni_id FROM universes u
                JOIN user_univ uu ON u.uni_id = uu.uni_id
                WHERE LOWER(u.uni_name) = LOWER(%s) AND uu.us_id = %s;
            """, (uni_name, us_id))
            universe = cur.fetchone()

            if not universe:
                return jsonify({"error": "Universe not found or you are not a member"}), 403

            uni_id = universe["uni_id"]

            # Insert location into locations table and get location_id
            # We store locations in a separate table to allow for more complex geometries in the future (e.g. areas, lines) and to keep the messages table cleaner.
            # For now, we only support point geometries, so we use ST_MakePoint with longitude and latitude, and set the SRID to 4326 (WGS 84).
            cur.execute("""
                INSERT INTO locations (geom)
                VALUES (ST_SetSRID(ST_MakePoint(%s, %s), 4326))
                RETURNING location_id;
            """, (longitude, latitude))
            location_id = cur.fetchone()["location_id"]

            # Insert message
            # For polls, m_txt stores p_txt so the row is always readable
            display_txt = m_txt if m_type == "text" else poll["p_txt"]

            cur.execute("""
                INSERT INTO messages (m_type, unl_rad, crt_time, view_once, m_txt, creator, uni_id, location_id)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                RETURNING m_id;
            """, (m_type, unl_rad, datetime.utcnow(), view_once, display_txt, us_id, uni_id, location_id))
            m_id = cur.fetchone()["m_id"]

            # Insert poll options if poll, option_id is auto-generated by DB sequence
            if m_type == "poll":
                for option_text in poll["poll_options"]:
                    cur.execute("""
                        INSERT INTO poll_options (m_id, option_text)
                        VALUES (%s, %s);
                    """, (m_id, option_text))

            conn.commit()
            return jsonify({"message": "Message created", "m_id": m_id}), 201

        except Exception as e:
            conn.rollback()
            return jsonify({"error": str(e)}), 500

        finally:
            release_db_connection(conn)

    # GET messages for a universe
    uni_name = request.args.get("uni_name")

    if not uni_name:
        release_db_connection(conn)
        return jsonify({"error": "uni_name query parameter required"}), 400
    try:
        # Resolve uni_name to uni_id and check membership
        cur.execute("""
            SELECT u.uni_id FROM universes u
            JOIN user_univ uu ON u.uni_id = uu.uni_id
            WHERE LOWER(u.uni_name) = LOWER(%s) AND uu.us_id = %s;
        """, (uni_name, us_id))
        universe = cur.fetchone()

        if not universe:
            return jsonify({"error": "Universe not found or you are not a member"}), 403
        
        cur.execute("""
            SELECT m.m_id, m.m_type, m.unl_rad, m.crt_time, m.view_once,
                   m.m_txt, m.location_id,
                   u.us_name AS creator_name
            FROM messages m
            JOIN users u ON m.creator = u.us_id
            WHERE m.uni_id = %s;
        """, (universe["uni_id"],))

        messages_list = cur.fetchall()
        return jsonify(list(messages_list))

    except Exception as e:
        return jsonify({"error": str(e)}), 500

    finally:
        release_db_connection(conn)


# Nearby messages route
# Returns all messages visible in the current map viewpoint.
# All messages in the bounding box are returned — locked ones included,
# but the frontend decides what to reveal based on distance vs unl_rad.
# creator_name is included so the frontend can show who dropped each message.
@app.route("/messages/nearby", methods=["GET"])
def nearby_messages():
    us_id, error = get_current_user() # Get user from token
    if error:
        return jsonify({"error": error}), 401
    
    # Get query parameters
    min_lat  = request.args.get("min_lat")
    max_lat  = request.args.get("max_lat")
    min_lon  = request.args.get("min_lon")
    max_lon  = request.args.get("max_lon")
    uni_name = request.args.get("uni_name")  # optional filter to only get messages from a specific universe

    if not all([min_lat, max_lat, min_lon, max_lon]):
        return jsonify({"error": "min_lat, max_lat, min_lon, max_lon are required"}), 400

    conn = get_db_connection()
    cur = conn.cursor()

    try: # Resolve uni_name to uni_id and check membership if uni_name provided
        cur.execute("""
            SELECT
                m.m_id, m.m_type, m.unl_rad, m.crt_time, m.view_once, m.m_txt,
                u.us_name    AS creator_name,
                un.uni_name,
                ST_Y(l.geom) AS latitude,
                ST_X(l.geom) AS longitude
            FROM messages m
            JOIN locations l  ON m.location_id = l.location_id
            JOIN users u      ON m.creator = u.us_id
            JOIN universes un ON m.uni_id = un.uni_id
            JOIN user_univ uu ON m.uni_id = uu.uni_id AND uu.us_id = %s
            WHERE ST_Within(
                l.geom,
                ST_MakeEnvelope(%s, %s, %s, %s, 4326)
            );
        """, (us_id, min_lon, min_lat, max_lon, max_lat))

        return jsonify(list(cur.fetchall()))

    except Exception as e:
        return jsonify({"error": str(e)}), 500

    finally:
        release_db_connection(conn)

# DELETE message route --> should this be done in the database??
@app.route("/messages/<int:m_id>", methods=["DELETE"])
def delete_message(m_id):

    # Get current user from token
    us_id, error = get_current_user()
    if error:
        return jsonify({"error": error}), 401

    conn = get_db_connection()
    cur = conn.cursor()

    try:
        # Fetch message info
        cur.execute("""
            SELECT creator, crt_time
            FROM messages
            WHERE m_id = %s;
        """, (m_id,))

        message = cur.fetchone()

        if not message:
            return jsonify({"error": "Message not found"}), 404

        # Check ownership
        if message["creator"] != us_id:
            return jsonify({"error": "You can only delete your own messages"}), 403

        # Check 30-minute time limit --> SHOULD WE CHANGE THAT TO LESS?
        from datetime import datetime, timedelta # can I skip this if it's already imported at the top?

        created_at = message["crt_time"]
        time_limit = created_at + timedelta(minutes=30)

        if datetime.utcnow() > time_limit:
            return jsonify({
                "error": "Delete time window expired (30 minutes)"
            }), 403

        # Delete message
        cur.execute("""
            DELETE FROM messages
            WHERE m_id = %s;
        """, (m_id,))

        conn.commit()

        return jsonify({
            "message": "Message deleted successfully"
        }), 200

    except Exception as e:
        conn.rollback()
        return jsonify({"error": str(e)}), 500

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

#  POLLS – POST /poll/vote
#  User votes on a poll option.
#  One vote per user per poll enforced by DB constraint:
#    UNIQUE (us_id, m_id) on poll_votes
@app.route("/poll/vote", methods=["POST"])
def vote_poll():

    us_id, error = get_current_user()
    if error:
        return jsonify({"error": error}), 401

    data = request.get_json(silent=True)
    if not data:
        return jsonify({"error": "Invalid JSON"}), 400

    option_id = data.get("option_id")
    if not option_id:
        return jsonify({"error": "option_id is required"}), 400

    conn = get_db_connection()
    cur  = conn.cursor()

    try:
        # Verify option exists and get its m_id
        cur.execute("""
            SELECT m_id FROM poll_options
            WHERE option_id = %s;
        """, (option_id,))
        result = cur.fetchone()
        if not result:
            return jsonify({"error": "Option not found"}), 404

        m_id = result["m_id"]

        # Check universe membership
        cur.execute("""
            SELECT uni_id FROM messages WHERE m_id = %s;
        """, (m_id,))
        msg = cur.fetchone()
        if not msg:
            return jsonify({"error": "Poll message not found"}), 404

        cur.execute("""
            SELECT 1 FROM user_univ
            WHERE us_id = %s AND uni_id = %s;
        """, (us_id, msg["uni_id"]))
        if not cur.fetchone():
            return jsonify({"error": "You are not a member of this universe"}), 403

        # Check if already voted (also caught by DB constraint, but gives a clearer message)
        cur.execute("""
            SELECT 1 FROM poll_votes
            WHERE us_id = %s AND m_id = %s;
        """, (us_id, m_id))
        if cur.fetchone():
            return jsonify({"error": "You have already voted in this poll"}), 409

        # Insert vote
        cur.execute("""
            INSERT INTO poll_votes (option_id, us_id, m_id)
            VALUES (%s, %s, %s);
        """, (option_id, us_id, m_id))

        conn.commit()
        return jsonify({"message": "Vote recorded"}), 201

    except Exception as e:
        conn.rollback()
        return jsonify({"error": str(e)}), 500

    finally:
        release_db_connection(conn)


# POLLS – GET /poll/<m_id>
# Returns p_txt + all poll_options / option_text.
#  Used to display the poll BEFORE the user has voted.
#  If user already voted, tells them to fetch results instead.

@app.route("/poll/<int:m_id>", methods=["GET"])
def get_poll(m_id):

    us_id, error = get_current_user()
    if error:
        return jsonify({"error": error}), 401

    conn = get_db_connection()
    cur  = conn.cursor()

    try:
        cur.execute("""
            SELECT m_id, m_txt AS p_txt, crt_time, uni_id
            FROM messages
            WHERE m_id = %s AND m_type = 'poll';
        """, (m_id,))
        message = cur.fetchone()

        if not message:
            return jsonify({"error": "Poll not found"}), 404

        # Check membership
        cur.execute("""
            SELECT 1 FROM user_univ
            WHERE us_id = %s AND uni_id = %s;
        """, (us_id, message["uni_id"]))
        if not cur.fetchone():
            return jsonify({"error": "Not allowed"}), 403

        # If already voted, block and point to results endpoint
        cur.execute("""
            SELECT 1 FROM poll_votes
            WHERE us_id = %s AND m_id = %s;
        """, (us_id, m_id))
        if cur.fetchone():
            return jsonify({
                "error": "Already voted. Fetch results at GET /poll/<m_id>/results"
            }), 403

        # Get options without vote counts
        cur.execute("""
            SELECT option_id, option_text
            FROM poll_options
            WHERE m_id = %s
            ORDER BY option_id;
        """, (m_id,))
        options = cur.fetchall()

        return jsonify({
            "m_id":         message["m_id"],
            "p_txt":     message["p_txt"],
            "crt_time":     str(message["crt_time"]),
            "poll_options": list(options)
        }), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500

    finally:
        release_db_connection(conn)


# POLLS  –  GET /poll/<m_id>/results
# Returns vote counts per option + total.
# Only accessible AFTER the current user has voted.

@app.route("/poll/<int:m_id>/results", methods=["GET"])
def poll_results(m_id):

    us_id, error = get_current_user()
    if error:
        return jsonify({"error": error}), 401

    conn = get_db_connection()
    cur  = conn.cursor()

    try:
        # Check poll exists
        cur.execute("""
            SELECT uni_id FROM messages
            WHERE m_id = %s AND m_type = 'poll';
        """, (m_id,))
        msg = cur.fetchone()
        if not msg:
            return jsonify({"error": "Poll not found"}), 404

        # Check membership
        cur.execute("""
            SELECT 1 FROM user_univ
            WHERE us_id = %s AND uni_id = %s;
        """, (us_id, msg["uni_id"]))
        if not cur.fetchone():
            return jsonify({"error": "Not allowed"}), 403

        # Block if user hasn't voted yet
        cur.execute("""
            SELECT 1 FROM poll_votes
            WHERE us_id = %s AND m_id = %s;
        """, (us_id, m_id))
        if not cur.fetchone():
            return jsonify({"error": "Vote first to see results"}), 403

        # Results with vote counts (LEFT JOIN keeps options with 0 votes)
        cur.execute("""
            SELECT
                po.option_id,
                po.option_text,
                COUNT(pv.vote_id) AS vote_count
            FROM poll_options po
            LEFT JOIN poll_votes pv ON po.option_id = pv.option_id
            WHERE po.m_id = %s
            GROUP BY po.option_id, po.option_text
            ORDER BY po.option_id;
        """, (m_id,))
        results = cur.fetchall()

        total = sum(r["vote_count"] for r in results)

        return jsonify({
            "m_id":        m_id,
            "total_votes": total,
            "results":     list(results)
        }), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500

    finally:
        release_db_connection(conn)

# Run server

if __name__ == "__main__":
    app.run(debug=True)
