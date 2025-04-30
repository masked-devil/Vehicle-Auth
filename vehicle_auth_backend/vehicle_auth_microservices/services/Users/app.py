from flask import Flask, request, jsonify
from flask_bcrypt import Bcrypt
from flask_jwt_extended import JWTManager, create_access_token, jwt_required, get_jwt_identity
from flask_mail import Mail, Message
from pymongo import MongoClient
import datetime
import os
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

# Configuration
app.config['JWT_SECRET_KEY'] = 'your_secret_key'
app.config['MONGO_URI'] = 'mongodb://localhost:27017/userdb'
app.config['MAIL_SERVER'] = 'smtp.gmail.com'
app.config['MAIL_PORT'] = 587
app.config['MAIL_USE_TLS'] = True
app.config['MAIL_USERNAME'] = 'email@gmail.com'
app.config['MAIL_PASSWORD'] = 'password'

# Initialize Extensions
bcrypt = Bcrypt(app)
jwt = JWTManager(app)
mail = Mail(app)
client = MongoClient(app.config['MONGO_URI'])
db = client.userdb
users = db.users

# Signup Route
@app.route('/signup', methods=['POST'])
def signup():
    data = request.json
    if users.find_one({'email': data['email']}):
        return jsonify({'message': 'User already exists'}), 400
    
    if users.find_one({'flat_floor': data['flat_floor'], 'flat_number': data['flat_number']}):
        return jsonify({'message': 'A user already exists for this flat and floor'}), 400
    
    if users.find_one({'userid': data['userid']}):
        return jsonify({'message': 'User ID already exists'}), 400
    
    hashed_password = bcrypt.generate_password_hash(data['password']).decode('utf-8')
    user_data = {
        'name': data['name'],
        'email': data['email'],
        'password': hashed_password,
        'userid': data['userid'],
        'wing': data['wing'],
        'flat_floor': data['flat_floor'],
        'flat_number': data['flat_number'],
        'approved': "false"  # Default to not approved by admin
    }
    users.insert_one(user_data)
    return jsonify({'message': 'User registered successfully, pending admin approval'}), 201

# Admin Approval Route
@app.route('/approve_user', methods=['POST'])
def approve_user():
    data = request.json
    user = users.find_one({'userid': data['userid']})
    if not user:
        return jsonify({'message': 'User not found'}), 404
    
    if data['approved'] not in ["true", "false", "denied"]:
        return jsonify({'message': 'Invalid approval status'}), 400
    
    users.update_one({'userid': data['userid']}, {"$set": {"approved": data['approved']}})
    return jsonify({'message': f'User approval status updated to {data["approved"]}'}), 200

# Get All Users Route Categorized
@app.route('/get_users', methods=['GET'])
def get_users():
    approved_users = list(users.find({'approved': "true"}, {'_id': 0, 'password': 0}))
    pending_users = list(users.find({'approved': "false"}, {'_id': 0, 'password': 0}))
    denied_users = list(users.find({'approved': "denied"}, {'_id': 0, 'password': 0}))
    return jsonify({
        'approved_users': approved_users,
        'pending_users': pending_users,
        'denied_users': denied_users
    }), 200

# Get User by ID Route
@app.route('/get_user/<userid>', methods=['GET'])
def get_user(userid):
    user = users.find_one({'userid': userid}, {'_id': 0, 'password': 0})
    if not user:
        return jsonify({'message': 'User not found'}), 404
    return jsonify(user), 200

# Delete User Route
@app.route('/delete_user/<userid>', methods=['DELETE'])
@jwt_required()
def delete_user(userid):
    result = users.delete_one({'userid': userid})
    if result.deleted_count == 0:
        return jsonify({'message': 'User not found or already deleted'}), 404
    return jsonify({'message': 'User deleted successfully'}), 200

# Login Route
@app.route('/login', methods=['POST'])
def login():
    data = request.json
    user = users.find_one({'email': data['email']})
    if user and bcrypt.check_password_hash(user['password'], data['password']):
        if user.get('approved') == "false":
            return jsonify({'message': 'Account not approved by admin'}), 403
        elif user.get('approved') == "denied":
            return jsonify({'message': 'Account access denied by admin'}), 403
        access_token = create_access_token(identity=user['email'], expires_delta=datetime.timedelta(days=7))
        return jsonify({'access_token': access_token, 'userid': user['userid']}), 200
    return jsonify({'message': 'Invalid credentials'}), 401

# Forgot Password Route
@app.route('/forgot_password', methods=['POST'])
def forgot_password():
    data = request.json
    user = users.find_one({'email': data['email']})
    if user:
        reset_token = create_access_token(identity=user['email'], expires_delta=datetime.timedelta(minutes=15))
        msg = Message('Password Reset Request', sender=app.config['MAIL_USERNAME'], recipients=[user['email']])
        msg.body = f'Use this token to reset your password: {reset_token}'
        mail.send(msg)
        return jsonify({'message': 'Reset email sent'}), 200
    return jsonify({'message': 'User not found'}), 404

if __name__ == '__main__':
    app.run(debug=True, port=5001)
