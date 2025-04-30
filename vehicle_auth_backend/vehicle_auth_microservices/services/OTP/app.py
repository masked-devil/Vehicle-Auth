from zoneinfo import ZoneInfo
from flask import Flask, request, jsonify
from pymongo import MongoClient, errors
from datetime import datetime, timedelta, timezone
import random
import os
import requests
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

# Initialize Flask app
app = Flask(__name__)

GATE_SERVICE_URL = "http://127.0.0.1:5005/open_gate"

# MongoDB Setup with error handling
MONGO_URI = os.getenv("MONGO_URI", "mongodb://localhost:27017/")
try:
    client = MongoClient(MONGO_URI, serverSelectionTimeoutMS=5000)
    db = client["otp_service"]
    collection = db["otps"]
    client.server_info()  # Trigger exception if MongoDB is unreachable
except errors.ServerSelectionTimeoutError:
    exit(1)

# OTP Expiry Time (30 minutes)
EXPIRY_TIME = 30

# Log service URL
LOG_SERVICE_URL = os.getenv("LOG_SERVICE_URL", "http://localhost:5003/add_log")

def generate_otp():
    return str(random.randint(100000, 999999))  # 6-digit OTP

@app.route("/generate-otp", methods=["POST"])
def generate_new_otp():
    try:
        data = request.json
        user_id = data.get("user_id")
        category = data.get("category")

        if not user_id or not category:
            return jsonify({"error": "user_id and category are required"}), 400

        otp = generate_otp()
        # ist = timezone(timedelta(hours=5, minutes=30))
        now = now = datetime.utcnow()
        expiry_time = now + timedelta(minutes=EXPIRY_TIME)

        # Store OTP with category in MongoDB
        collection.update_one(
            {"user_id": user_id},
            {
                "$set": {
                    "otp": otp,
                    "expires_at": expiry_time,
                    "category": category
                }
            },
            upsert=True
        )

        return jsonify({"message": "OTP generated successfully", "otp": otp})
    except Exception:
        return jsonify({"error": "Internal server error"}), 500

@app.route("/verify-otp", methods=["POST"])
def verify_otp():
    try:
        data = request.json
        otp = data.get("otp")
        # ist = timezone(timedelta(hours=5, minutes=30))
        now = now = datetime.utcnow()
        
        print(otp)

        if not otp:
            return jsonify({"error": "otp is required"}), 400

        record = collection.find_one({"otp": otp})

        if not record:
            return jsonify({"error": "OTP not found"}), 400

        if now > record["expires_at"]:
            return jsonify({"error": "OTP expired"}), 400

        user_id = record.get("user_id")
        category = record.get("category")

        # Delete OTP after verification
        collection.delete_one({"_id": record["_id"]})

        gate_response = requests.get(GATE_SERVICE_URL)  # adjust port or URL if needed
        
        if gate_response.status_code != 200:
            return jsonify({"error": "Failed to open gate"}), 500


        # Send log to external service
        try:
            requests.post(LOG_SERVICE_URL, json={"user_id": user_id, "category": category})
        except requests.RequestException:
            pass

        return jsonify({"message": "OTP verified successfully", "user_id": user_id, "category": category})

    except Exception:
        return jsonify({"error": "Internal server error"}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5002)
