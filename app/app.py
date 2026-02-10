import os
from flask import Flask, jsonify, request
import psycopg2
from psycopg2.pool import SimpleConnectionPool
from datetime import datetime
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize Flask app
app = Flask(__name__)

# Database connection pool
conn_pool = None

def get_db_connection():
    """Get a database connection from the pool"""
    try:
        conn = conn_pool.getconn()
        conn.autocommit = True
        return conn
    except Exception as e:
        logger.error(f"Database connection error: {e}")
        raise

def return_db_connection(conn):
    """Return a connection to the pool"""
    conn_pool.putconn(conn)

@app.before_request
def initialize_db_pool():
    """Initialize database connection pool on first request"""
    global conn_pool
    if conn_pool is None:
        try:
            db_host = os.getenv('DB_HOST', 'localhost')
            db_port = os.getenv('DB_PORT', '5432')
            db_name = os.getenv('DB_NAME', 'appdb')
            db_user = os.getenv('DB_USER', 'postgres')
            db_password = os.getenv('DB_PASSWORD', 'postgres')
            
            conn_pool = SimpleConnectionPool(
                1, 5,  # min 1, max 5 connections
                host=db_host,
                port=int(db_port),
                database=db_name,
                user=db_user,
                password=db_password,
                connect_timeout=5
            )
            logger.info(f"Connected to database at {db_host}:{db_port}/{db_name}")
        except Exception as e:
            logger.error(f"Failed to initialize connection pool: {e}")

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute('SELECT 1')
        cursor.close()
        return_db_connection(conn)
        return jsonify({"status": "healthy", "timestamp": datetime.utcnow().isoformat()}), 200
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        return jsonify({"status": "unhealthy", "error": str(e)}), 503

@app.route('/api/users', methods=['GET'])
def get_users():
    """Get all users"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute('SELECT id, email, created_at FROM users ORDER BY created_at DESC LIMIT 100')
        rows = cursor.fetchall()
        cursor.close()
        return_db_connection(conn)
        
        users = [{"id": row[0], "email": row[1], "created_at": row[2].isoformat()} for row in rows]
        return jsonify({"users": users}), 200
    except Exception as e:
        logger.error(f"Error fetching users: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/api/users', methods=['POST'])
def create_user():
    """Create a new user"""
    try:
        data = request.get_json()
        email = data.get('email')
        
        if not email:
            return jsonify({"error": "Email is required"}), 400
        
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Create table if it doesn't exist
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS users (
                id SERIAL PRIMARY KEY,
                email VARCHAR(255) UNIQUE NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        
        cursor.execute('INSERT INTO users (email) VALUES (%s) RETURNING id, email, created_at', (email,))
        row = cursor.fetchone()
        conn.commit()
        cursor.close()
        return_db_connection(conn)
        
        return jsonify({
            "id": row[0],
            "email": row[1],
            "created_at": row[2].isoformat()
        }), 201
    except psycopg2.IntegrityError:
        return jsonify({"error": "User with this email already exists"}), 409
    except Exception as e:
        logger.error(f"Error creating user: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/api/tasks', methods=['GET'])
def get_tasks():
    """Get all tasks"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute('SELECT id, title, completed, user_id, created_at FROM tasks ORDER BY created_at DESC LIMIT 100')
        rows = cursor.fetchall()
        cursor.close()
        return_db_connection(conn)
        
        tasks = [{"id": row[0], "title": row[1], "completed": row[2], "user_id": row[3], "created_at": row[4].isoformat()} for row in rows]
        return jsonify({"tasks": tasks}), 200
    except Exception as e:
        logger.error(f"Error fetching tasks: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/api/tasks', methods=['POST'])
def create_task():
    """Create a new task"""
    try:
        data = request.get_json()
        title = data.get('title')
        user_id = data.get('user_id')
        
        if not title or not user_id:
            return jsonify({"error": "Title and user_id are required"}), 400
        
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Create table if it doesn't exist
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS tasks (
                id SERIAL PRIMARY KEY,
                title VARCHAR(255) NOT NULL,
                completed BOOLEAN DEFAULT FALSE,
                user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        
        cursor.execute(
            'INSERT INTO tasks (title, user_id) VALUES (%s, %s) RETURNING id, title, completed, user_id, created_at',
            (title, user_id)
        )
        row = cursor.fetchone()
        conn.commit()
        cursor.close()
        return_db_connection(conn)
        
        return jsonify({
            "id": row[0],
            "title": row[1],
            "completed": row[2],
            "user_id": row[3],
            "created_at": row[4].isoformat()
        }), 201
    except Exception as e:
        logger.error(f"Error creating task: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/api/info', methods=['GET'])
def info():
    """Get application info"""
    return jsonify({
        "app": "Invincible Cloud",
        "version": "1.0.0",
        "db_host": os.getenv('DB_HOST', 'unknown'),
        "environment": os.getenv('ENVIRONMENT', 'unknown')
    }), 200

@app.teardown_appcontext
def close_connection(exception):
    """Close database pool on app shutdown"""
    global conn_pool
    if conn_pool is not None:
        conn_pool.closeall()

if __name__ == '__main__':
    # Run Flask app
    app.run(
        host='0.0.0.0',
        port=int(os.getenv('PORT', 8000)),
        debug=os.getenv('DEBUG', 'False') == 'True'
    )
