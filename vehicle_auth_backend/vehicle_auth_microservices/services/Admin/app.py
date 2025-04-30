from flask import Flask, request, jsonify
from flask_bcrypt import Bcrypt
from flask_jwt_extended import JWTManager, create_access_token, jwt_required
from flask_mail import Mail, Message
from pymongo import MongoClient
import datetime, os
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

# MongoDB Configuration
client = MongoClient("mongodb://localhost:27017/")
db = client["admin_service"]
admin_collection = db["admin"]

# Flask Configurations
app.config["JWT_SECRET_KEY"] = "supersecretkey"
app.config["MAIL_SERVER"] = "smtp.gmail.com"
app.config["MAIL_PORT"] = 587
app.config["MAIL_USE_TLS"] = True
app.config["MAIL_USERNAME"] = os.getenv("EMAIL_USER")
app.config["MAIL_PASSWORD"] = os.getenv("EMAIL_PASS")

bcrypt = Bcrypt(app)
jwt = JWTManager(app)
mail = Mail(app)

# Ensure admin exists
def ensure_admin():
    if admin_collection.count_documents({}) == 0:
        hashed_pw = bcrypt.generate_password_hash("admin123").decode('utf-8')
        admin_collection.insert_one({"username": "admin", "password": hashed_pw, "email": "admin@example.com"})
ensure_admin()

# Admin Login
@app.route("/login", methods=["POST"])
def login():
    data = request.json
    admin = admin_collection.find_one({"username": data.get("username")})
    if admin and bcrypt.check_password_hash(admin["password"], data.get("password")):
        access_token = create_access_token(identity=admin["username"], expires_delta=datetime.timedelta(hours=1))
        return jsonify({"access_token": access_token}), 200
    return jsonify({"msg": "Invalid credentials"}), 401

# Forgot Password
@app.route("/forgot_password", methods=["POST"])
def forgot_password():
    data = request.json
    admin = admin_collection.find_one({"email": data.get("email")})
    if admin:
        new_password = "newpassword123"
        hashed_pw = bcrypt.generate_password_hash(new_password).decode('utf-8')
        admin_collection.update_one({"email": data.get("email")}, {"$set": {"password": hashed_pw}})
        
        msg = Message("Password Reset", sender=app.config["MAIL_USERNAME"], recipients=[data.get("email")])
        msg.body = f"Your new password is: {new_password}"
        mail.send(msg)
        return jsonify({"msg": "New password sent to email"}), 200
    return jsonify({"msg": "Email not found"}), 404

if __name__ == "__main__":
    app.run(debug=True, port=5004)
