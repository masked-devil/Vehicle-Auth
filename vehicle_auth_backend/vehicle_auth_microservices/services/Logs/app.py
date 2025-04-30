from flask import Flask, request, jsonify
from flask_pymongo import PyMongo
from datetime import datetime, timedelta, timezone
from bson.json_util import dumps
import requests
import os
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

app = Flask(__name__)

# MongoDB Configuration
app.config["MONGO_URI"] = os.getenv("MONGO_URI", "mongodb://localhost:27017/log_service")
mongo = PyMongo(app)
log_collection = mongo.db.logs

# Replace with actual backend URL
USER_SERVICE_BASE_URL = os.getenv("USER_SERVICE_URL", "http://127.0.0.1:5001")

VALID_CATEGORIES = {"owner", "guest", "delivery", "emergency", "other"}

# Helper to get user's name from /get_user/<user_id>
def get_user_name(user_id):
    try:
        response = requests.get(f"{USER_SERVICE_BASE_URL}/get_user/{user_id}")
        if response.status_code == 200:
            return response.json().get("name")
    except Exception as e:
        print(f"Error fetching user name: {e}")
    return None

# Route to add a new log
@app.route('/add_log', methods=['POST'])
def add_log():
    data = request.get_json()

    if not data:
        return jsonify({"error": "No JSON data received"}), 400

    category = data.get('category')
    user_id = data.get('user_id')

    # Validate category
    if not category:
        return jsonify({"error": "Category is required"}), 400
    if category not in VALID_CATEGORIES:
        return jsonify({"error": f"Invalid category. Must be one of {list(VALID_CATEGORIES)}"}), 400

    # Validate user_id presence where required
    if category in {"owner", "guest", "delivery"} and not user_id:
        return jsonify({"error": f"user_id is required for category '{category}'"}), 400

    ist = timezone(timedelta(hours=5, minutes=30))
    now = datetime.utcnow()
    date_str = now.strftime("%d-%m-%Y")
    time_str = now.strftime("%H:%M:%S")

    owner_name_associated = None
    message = ""

    if category == "owner":
        owner_name_associated = get_user_name(user_id)
        if not owner_name_associated:
            return jsonify({"error": "User name not found for given user_id"}), 404
        message = f"Gate Opened for Owner {owner_name_associated} at {time_str} on {date_str}"

    elif category in {"guest", "delivery","other"}:
        owner_name_associated = get_user_name(user_id)
        if not owner_name_associated:
            return jsonify({"error": "Owner name not found for guest/delivery's associated user_id"}), 404
        message = f"Gate Opened for {category.capitalize()} by Owner {owner_name_associated} at {time_str} on {date_str}"

    elif category == "emergency":
        message = f"Gate Opened for Emergency at {time_str} on {date_str}"

    else:  # other
        message = f"Gate Opened for Other by Owner {owner_name_associated} at {time_str} on {date_str}"

    log_entry = {
        "category": category,
        "user_id": user_id if user_id else None,
        "date": date_str,
        "time": time_str,
        "owner_name_associated": owner_name_associated,
        "message": message
    }

    log_collection.insert_one(log_entry)
    return jsonify({"message": "Log added successfully", "log": log_entry}), 201

# Route to fetch all logs
@app.route('/get_logs', methods=['GET'])
def get_all_logs():
    logs = list(log_collection.find())
    if not logs:
        return jsonify({"message": "No logs found."}), 404
    return dumps(logs), 200

# Route to fetch logs for a specific user
@app.route('/get_logs/<user_id>', methods=['GET'])
def get_logs_by_user(user_id):
    if not user_id:
        return jsonify({"error": "user_id is required in the URL"}), 400

    logs = list(log_collection.find({"user_id": user_id}))
    if not logs:
        return jsonify({"message": f"No logs found for user_id: {user_id}"}), 404
    return dumps(logs), 200

# Global error handler
@app.errorhandler(Exception)
def handle_exception(e):
    return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True, port=5003)
