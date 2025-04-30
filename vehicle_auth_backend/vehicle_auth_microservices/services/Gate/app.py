from flask import Flask, jsonify
import requests

app = Flask(__name__)

# Global configuration
GATE_CONTROLLER_URL = "http://192.168.238.61/P"
LOGGING_SERVICE_URL = "http://127.0.0.1:5003/add_log"  # Replace if hosted elsewhere

@app.route('/emergency_open_gate', methods=['GET'])
def emergency_open_gate():
    try:
        # Step 1: Hit the gate IP (don't care about response)
        try:
            requests.get(GATE_CONTROLLER_URL, timeout=3)
        except:
            pass  # Even if it times out or fails, we still move forward (as per your instruction)

        # Step 2: Add emergency log
        try:
            log_response = requests.post(LOGGING_SERVICE_URL, json={"category": "emergency"})
            if log_response.status_code == 201:
                return jsonify({
                    "success": True,
                    "message": "Gate trigger sent."
                }), 200
            else:
                return jsonify({
                    "success": True,
                    "message": "Gate trigger sent. But failed to log emergency.",
                    "log_status": log_response.status_code
                }), 200
        except Exception as log_err:
            return jsonify({
                "success": True,
                "message": "Gate trigger sent. But error occurred while logging.",
                "log_error": str(log_err)
            }), 200

    except Exception as e:
        return jsonify({
            "success": False,
            "message": "Unexpected error during emergency gate operation.",
            "error": str(e)
        }), 500

@app.route('/open_gate', methods=['GET'])
def open_gate_direct():
    try:
        try:
            requests.get(GATE_CONTROLLER_URL, timeout=3)
        except:
            pass  # Ignore any failure, as per instruction

        return jsonify({
            "success": True,
            "message": "Gate trigger sent."
        }), 200

    except Exception as e:
        return jsonify({
            "success": False,
            "message": "Error while sending gate trigger.",
            "error": str(e)
        }), 500


if __name__ == '__main__':
    app.run(port=5005)
