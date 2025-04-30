from flask import Flask, request, jsonify
from pymongo import MongoClient, errors
import re
import requests
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

LOG_SERVICE_URL = "http://127.0.0.1:5003/add_log"
USER_SERVICE_BASE_URL = "http://127.0.0.1:5001"

# Helper to get user's name from /get_user/<user_id>
def get_user_name(user_id):
    try:
        response = requests.get(f"{USER_SERVICE_BASE_URL}/get_user/{user_id}")
        if response.status_code == 200:
            return response.json().get("name")
    except Exception as e:
        print(f"Error fetching user name: {e}")
    return None

# Connect to MongoDB
try:
    client = MongoClient("mongodb://localhost:27017/")
    db = client.vehicle_service
    collection = db.vehicles
except errors.ConnectionFailure:
    print("Could not connect to MongoDB")
    exit(1)

def is_valid_vehicle_number(vehicle_number):
    pattern1 = r"^[A-Z]{2}\d{2}[A-Z]{2,3}\d{1,4}$"
    pattern2 = r"^(2[1-9]|[3-9][0-9])BH\d{1,4}[A-Z]{2}$"
    return re.match(pattern1, vehicle_number) or re.match(pattern2, vehicle_number)

@app.route("/add_vehicle", methods=["POST"])
def add_vehicle():
    try:
        data = request.json
        user_id = data.get("user_id")
        vehicle_number = data.get("vehicle_number")

        if not user_id or not vehicle_number:
            return jsonify({"error": "Missing user_id or vehicle_number"}), 400

        if not is_valid_vehicle_number(vehicle_number):
            return jsonify({"error": "Invalid vehicle number format"}), 400

        existing_vehicle = collection.find_one({"vehicles.number": vehicle_number})
        if existing_vehicle:
            return jsonify({"error": "Vehicle number already exists"}), 409

        collection.update_one(
            {"user_id": user_id},
            {"$addToSet": {"vehicles": {"number": vehicle_number, "approved": "false"}}},
            upsert=True
        )
        return jsonify({"message": "Vehicle number added successfully. Approval required."})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/update_vehicle", methods=["PUT"])
def update_vehicle():
    try:
        data = request.json
        user_id = data.get("user_id")
        old_vehicle_number = data.get("old_vehicle_number")
        new_vehicle_number = data.get("new_vehicle_number")

        if not user_id or not old_vehicle_number or not new_vehicle_number:
            return jsonify({"error": "Missing required fields"}), 400

        if not is_valid_vehicle_number(new_vehicle_number):
            return jsonify({"error": "Invalid new vehicle number format"}), 400

        existing_vehicle = collection.find_one({"vehicles.number": new_vehicle_number})
        if existing_vehicle:
            return jsonify({"error": "New vehicle number already exists"}), 409

        result = collection.update_one(
            {"user_id": user_id, "vehicles.number": old_vehicle_number},
            {"$set": {"vehicles.$[elem].number": new_vehicle_number, "vehicles.$[elem].approved": "false"}},
            array_filters=[{"elem.number": old_vehicle_number}]
        )

        if result.modified_count == 0:
            return jsonify({"error": "Vehicle not found or update failed"}), 404

        return jsonify({"message": "Vehicle updated successfully. Approval required again."})
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/delete_vehicle", methods=["DELETE"])
def delete_vehicle():
    try:
        data = request.json
        user_id = data.get("user_id")
        vehicle_number = data.get("vehicle_number")

        if not user_id or not vehicle_number:
            return jsonify({"error": "Missing user_id or vehicle_number"}), 400

        result = collection.update_one(
            {"user_id": user_id},
            {"$pull": {"vehicles": {"number": vehicle_number}}}
        )

        if result.modified_count == 0:
            return jsonify({"error": "Vehicle number not found or deletion failed"}), 404

        return jsonify({"message": "Vehicle number deleted successfully."})
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/verify_vehicle", methods=["GET"])
def verify_vehicle():
    try:
        vehicle_number = request.args.get("vehicle_number")
        if not vehicle_number:
            return jsonify({"error": "Missing vehicle_number"}), 400

        if not is_valid_vehicle_number(vehicle_number):
            return jsonify({"error": "Invalid vehicle number format"}), 400

        vehicle = collection.find_one(
            {"vehicles": {"$elemMatch": {"number": vehicle_number}}},
            {"user_id": 1, "vehicles.$": 1}
        )

        if not vehicle:
            return jsonify({"exists": False})

        vehicle_data = vehicle["vehicles"][0]
        approval_status = vehicle_data["approved"]

        if approval_status == "false":
            return jsonify({"exists": True, "approved": "false", "error": "Vehicle not approved"}), 403
        elif approval_status == "denied":
            return jsonify({"exists": True, "approved": "denied", "error": "Vehicle approval denied"}), 403

        #Log the entry as "owner"
        # Inside /verify_vehicle after vehicle is approved
        try:
            log_response = requests.post(LOG_SERVICE_URL, json={
                "category": "owner",
                "user_id": vehicle["user_id"]
            })
            log_response.raise_for_status()
        except requests.exceptions.RequestException as log_err:
            return jsonify({"error": "Vehicle verified but failed to log entry", "details": str(log_err)}), 500


        return jsonify({
            "exists": True,
            "user_id": vehicle["user_id"],
            "approved": "true"
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/get_user_vehicles", methods=["GET"])
def get_user_vehicles():
    try:
        user_id = request.args.get("user_id")
        if not user_id:
            return jsonify({"error": "Missing user_id"}), 400

        user = collection.find_one({"user_id": user_id}, {"vehicles": 1, "_id": 0})
        if not user:
            return jsonify({"error": "User not found"}), 404

        approved_vehicles = [v for v in user["vehicles"] if v["approved"] == "true"]
        pending_vehicles = [v for v in user["vehicles"] if v["approved"] == "false"]
        denied_vehicles = [v for v in user["vehicles"] if v["approved"] == "denied"]

        return jsonify({
            "approved_vehicles": approved_vehicles,
            "pending_vehicles": pending_vehicles,
            "denied_vehicles": denied_vehicles
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/get_all_vehicles", methods=["GET"])
def get_all_vehicles():
    try:
        vehicles = collection.find({}, {"user_id": 1, "vehicles": 1, "_id": 0})
        approved_vehicles = []
        denied_vehicles = []
        pending_vehicles = []
        # owner_name_associated=None
        

        for record in vehicles:
            user_id = record.get("user_id")  # Extract user_id
            owner_name_associated = get_user_name(user_id)
            for vehicle in record.get("vehicles", []):
                vehicle_info = {
                    "user_id": user_id,  # Include user_id
                    "vehicle_number": vehicle["number"],
                    "approved": vehicle["approved"],
                    "owner_name_associated":owner_name_associated
                }
                if vehicle["approved"] == "true":
                    approved_vehicles.append(vehicle_info)
                elif vehicle["approved"] == "denied":
                    denied_vehicles.append(vehicle_info)
                else:
                    pending_vehicles.append(vehicle_info)

        return jsonify({
            "approved_vehicles": approved_vehicles,
            "denied_vehicles": denied_vehicles,
            "pending_vehicles": pending_vehicles
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/approve_vehicle", methods=["PUT"])
def approve_vehicle():
    try:
        data = request.json
        user_id = data.get("user_id")
        vehicle_number = data.get("vehicle_number")

        if not user_id or not vehicle_number:
            return jsonify({"error": "Missing user_id or vehicle_number"}), 400

        result = collection.update_one(
            {"user_id": user_id},
            {"$set": {"vehicles.$[elem].approved": "true"}},
            array_filters=[{"elem.number": vehicle_number}]
        )

        if result.modified_count == 0:
            return jsonify({"error": "Vehicle not found or already approved"}), 404

        return jsonify({"message": "Vehicle approved successfully"})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/deny_vehicle", methods=["PUT"])
def deny_vehicle():
    try:
        data = request.json
        user_id = data.get("user_id")
        vehicle_number = data.get("vehicle_number")

        if not user_id or not vehicle_number:
            return jsonify({"error": "Missing user_id or vehicle_number"}), 400

        result = collection.update_one(
            {"user_id": user_id},
            {"$set": {"vehicles.$[elem].approved": "denied"}},
            array_filters=[{"elem.number": vehicle_number}]
        )

        if result.modified_count == 0:
            return jsonify({"error": "Vehicle not found or already denied"}), 404

        return jsonify({"message": "Vehicle denied successfully"})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    app.run(debug=True, port=5000)
