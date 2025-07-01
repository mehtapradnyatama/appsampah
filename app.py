from flask import Flask, render_template, request, redirect, url_for, flash, jsonify, session
from werkzeug.utils import secure_filename
import os
import torch
import torch.nn as nn
import torch.nn.functional as F
from torchvision import models, transforms
from PIL import Image
import json
import numpy as np
from datetime import datetime
import requests
import hashlib
import uuid
import logging

# Supabase configuration
SUPABASE_URL = "https://uqscjoiogogdwbwexeev.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVxc2Nqb2lvZ29nZHdid2V4ZWV2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEzNTM1OTcsImV4cCI6MjA2NjkyOTU5N30.XSg8vbc4AdsCR-0d6e5bmmV7VbYPaBnPEE9os7we2ek"

app = Flask(__name__)
app.secret_key = 'your-secret-key-here'

# Configuration
UPLOAD_FOLDER = 'static/uploads'
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg'}
MAX_CONTENT_LENGTH = 16 * 1024 * 1024  # 16MB max file size

app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
app.config['MAX_CONTENT_LENGTH'] = MAX_CONTENT_LENGTH

# Ensure upload directory exists
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs('model', exist_ok=True)

# Logging configuration
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Global variables for model
model = None
class_labels = None
transform = None

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

def load_model():
    """Load the trained model"""
    global model, class_labels, transform
    
    try:
        # Load model configuration
        config_path = 'appsampah\model\model_config.json'
        if os.path.exists(config_path):
            with open(config_path, 'r') as f:
                config = json.load(f)
            
            class_labels = config['class_labels']
            image_size = config['image_size']
            logger.info(f"Loaded config: {len(class_labels)} classes, image size: {image_size}")
        else:
            # Default configuration if config file doesn't exist
            class_labels = {0: 'cardboard', 1: 'glass', 2: 'metal', 3: 'paper', 4: 'plastic'}
            image_size = (224, 224)
            logger.warning("Config file not found, using default configuration")
        
        # Try to load full model first (recommended)
        full_model_path = 'appsampah\model\model_mobilenetv2_full.pth'
        weights_path = 'appsampah\model\model_mobilenetv2_weights.pth'
        
        if os.path.exists(full_model_path):
            # Load full model (architecture + weights)
            model = torch.load(full_model_path, map_location='cpu')
            model.eval()
            logger.info("Full model loaded successfully from model_mobilenetv2_full.pth")
            
        elif os.path.exists(weights_path):
            # Fallback: load weights only (need to create architecture)
            logger.info("Full model not found, trying to load weights only...")
            
            # Create model architecture
            model = models.mobilenet_v2(weights='IMAGENET1K_V1')
            
            # Freeze base model parameters
            for param in model.parameters():
                param.requires_grad = False
            
            # Replace classifier
            in_features = model.classifier[1].in_features
            model.classifier = nn.Sequential(
                nn.Dropout(0.2),
                nn.Linear(in_features, 256),
                nn.ReLU(),
                nn.BatchNorm1d(256),
                nn.Dropout(0.3),
                nn.Linear(256, 128),
                nn.ReLU(),
                nn.Dropout(0.2),
                nn.Linear(128, len(class_labels))
            )
            
            # Load weights
            model.load_state_dict(torch.load(weights_path, map_location='cpu'))
            model.eval()
            logger.info("Model weights loaded successfully from model_mobilenetv2_weights.pth")
            
        else:
            logger.error("Neither full model nor weights file found. Please ensure model files are in the 'model' directory.")
            logger.error(f"Looking for: {full_model_path} or {weights_path}")
            return False
        
        # Define transform
        transform = transforms.Compose([
            transforms.Resize(image_size),
            transforms.ToTensor(),
            transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
        ])
        
        logger.info(f"Model loaded successfully with {len(class_labels)} classes: {list(class_labels.values())}")
        return True
        
    except Exception as e:
        logger.error(f"Error loading model: {str(e)}")
        logger.error(f"Make sure model files exist in the 'model' directory:")
        logger.error(f"- model_mobilenetv2_full.pth (recommended)")
        logger.error(f"- model_mobilenetv2_weights.pth (fallback)")
        logger.error(f"- model_config.json")
        return False

def predict_image(image_path):
    """Predict the class of an image"""
    global model, class_labels, transform
    
    if model is None or transform is None:
        logger.error("Model or transform is not loaded, cannot predict.")
        # FIX 1: Pastikan untuk selalu mengembalikan 3 nilai
        return None, None, None
    
    try:
        # Load and preprocess image
        image = Image.open(image_path).convert('RGB')
        image_tensor = transform(image).unsqueeze(0)
        
        # Make prediction
        with torch.no_grad():
            outputs = model(image_tensor)
            probabilities = F.softmax(outputs, dim=1)
            confidence, predicted = torch.max(probabilities, 1)
            
            # FIX 2: Konversi predicted.item() (integer) ke string sebelum mengakses dictionary
            predicted_class = class_labels[str(predicted.item())]
            confidence_score = confidence.item() * 100
            
            # Get all class probabilities
            all_probs = probabilities[0].numpy()
            
            # FIX 2: Konversi i (integer) ke string sebelum mengakses dictionary
            class_probs = {class_labels[str(i)]: float(all_probs[i] * 100) for i in range(len(class_labels))}
            
            return predicted_class, confidence_score, class_probs
            
    except Exception as e:
        logger.error(f"Error predicting image: {str(e)}")
        # Pastikan exception juga mengembalikan 3 nilai
        return None, None, None

def supabase_request(method, endpoint, data=None, headers=None, params=None):
    """Make requests to Supabase"""
    url = f"{SUPABASE_URL}/rest/v1/{endpoint}"
    
    default_headers = {
        'apikey': SUPABASE_KEY,
        'Authorization': f'Bearer {SUPABASE_KEY}',
        'Content-Type': 'application/json'
    }
    
    if headers:
        default_headers.update(headers)
    
    try:
        if method == 'GET':
            response = requests.get(url, headers=default_headers, params=params)
        elif method == 'POST':
            # Tambahkan Prefer header agar Supabase mengembalikan data
            default_headers['Prefer'] = 'return=representation'
            response = requests.post(url, json=data, headers=default_headers)
        elif method == 'PUT':
            response = requests.put(url, json=data, headers=default_headers)
        elif method == 'DELETE':
            response = requests.delete(url, headers=default_headers)
        
        return response
    except Exception as e:
        logger.error(f"Supabase request error: {str(e)}")
        return None

def hash_password(password):
    """Hash password using SHA-256"""
    return hashlib.sha256(password.encode()).hexdigest()

def create_user_table():
    """Create users table if it doesn't exist"""
    try:
        # This would typically be done via Supabase dashboard or SQL
        # For now, we'll assume the table exists
        pass
    except Exception as e:
        logger.error(f"Error creating user table: {str(e)}")

def create_classification_table():
    """Create classifications table if it doesn't exist"""
    try:
        # This would typically be done via Supabase dashboard or SQL
        # For now, we'll assume the table exists
        pass
    except Exception as e:
        logger.error(f"Error creating classification table: {str(e)}")

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/register', methods=['GET', 'POST'])
def register():
    if request.method == 'POST':
        username = request.form.get('username')
        email = request.form.get('email')
        password = request.form.get('password')
        confirm_password = request.form.get('confirm_password')

        # Validation
        if not all([username, email, password, confirm_password]):
            flash('All fields are required', 'error')
            return render_template('register.html')

        if password != confirm_password:
            flash('Passwords do not match', 'error')
            return render_template('register.html')

        if len(password) < 6:
            flash('Password must be at least 6 characters long', 'error')
            return render_template('register.html')

        # Check if user already exists
        response = supabase_request('GET', f'users', params={'email': f'eq.{email}'})
        if response and response.status_code == 200:
            if response.json():
                flash('Email already registered', 'error')
                return render_template('register.html')

        # Create new user
        user_data = {
            'id': str(uuid.uuid4()),
            'username': username,
            'email': email,
            'password_hash': hash_password(password),
            'created_at': datetime.now().isoformat()
        }

        response = supabase_request('POST', 'users', user_data)
        # Tambahkan log detail
        if response:
            logger.error(f"Register response status: {response.status_code}, body: {response.text}")
        if response and response.status_code in [200, 201]:
            flash('Registration successful! Please login.', 'success')
            return redirect(url_for('login'))
        else:
            flash('Registration failed. Please try again.', 'error')

    return render_template('register.html')

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        email = request.form.get('email')
        password = request.form.get('password')
        
        if not all([email, password]):
            flash('Email and password are required', 'error')
            return render_template('login.html')
        
        # Verify user credentials
        response = supabase_request('GET', 'users', params={'email': f'eq.{email}'})
        if response and response.status_code == 200:
            users = response.json()
            if users and hash_password(password) == users[0]['password_hash']:
                session['user_id'] = users[0]['id']
                session['username'] = users[0]['username']
                session['email'] = users[0]['email']
                flash('Login successful!', 'success')
                return redirect(url_for('classify'))
        
        flash('Invalid email or password', 'error')
    
    return render_template('login.html')

@app.route('/logout')
def logout():
    session.clear()
    flash('You have been logged out', 'info')
    return redirect(url_for('index'))

@app.route('/classify', methods=['GET', 'POST'])
def classify():
    if 'user_id' not in session:
        flash('Please login to access this page', 'error')
        return redirect(url_for('login'))
    
    if request.method == 'POST':
        if 'file' not in request.files:
            flash('No file selected', 'error')
            return render_template('classify.html')
        
        file = request.files['file']
        if file.filename == '':
            flash('No file selected', 'error')
            return render_template('classify.html')
        
        if file and allowed_file(file.filename):
            filename = secure_filename(file.filename)
            # Add timestamp to filename to avoid conflicts
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S_')
            filename = timestamp + filename
            file_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
            file.save(file_path)
            
            # Make prediction
            predicted_class, confidence, class_probs = predict_image(file_path)
            
            if predicted_class:
                # Save classification to database
                classification_data = {
                    'id': str(uuid.uuid4()),
                    'user_id': session['user_id'],
                    'image_path': filename,
                    'predicted_class': predicted_class,
                    'confidence': confidence,
                    'class_probabilities': json.dumps(class_probs),
                    'created_at': datetime.now().isoformat()
                }
                
                supabase_request('POST', 'classifications', classification_data)
                
                return render_template('classify.html', 
                                     result=True,
                                     predicted_class=predicted_class,
                                     confidence=confidence,
                                     class_probs=class_probs,
                                     image_path=filename)
            else:
                flash('Error processing image. Please try again.', 'error')
        else:
            flash('Invalid file type. Please upload PNG, JPG, or JPEG files.', 'error')
    
    return render_template('classify.html')

@app.route('/dashboard')
def dashboard():
    if 'user_id' not in session:
        flash('Please login to access this page', 'error')
        return redirect(url_for('login'))
    
    # Get user's classification history
    response = supabase_request('GET', f'classifications?user_id=eq.{session["user_id"]}&order=created_at.desc')
    classifications = []
    
    if response and response.status_code == 200:
        classifications = response.json()
    
    # Calculate statistics
    total_classifications = len(classifications)
    class_counts = {}
    for classification in classifications:
        class_name = classification['predicted_class']
        class_counts[class_name] = class_counts.get(class_name, 0) + 1
    
    return render_template('dashboard.html', 
                         classifications=classifications,
                         total_classifications=total_classifications,
                         class_counts=class_counts)

@app.route('/about')
def about():
    return render_template('about.html')

@app.route('/api/stats')
def api_stats():
    """API endpoint for getting user statistics"""
    if 'user_id' not in session:
        return jsonify({'error': 'Not authenticated'}), 401
    
    response = supabase_request('GET', f'classifications?user_id=eq.{session["user_id"]}')
    if response and response.status_code == 200:
        classifications = response.json()
        
        stats = {
            'total_classifications': len(classifications),
            'class_distribution': {},
            'recent_classifications': len([c for c in classifications 
                                         if datetime.fromisoformat(c['created_at'].replace('Z', '+00:00')).date() == datetime.now().date()])
        }
        
        for classification in classifications:
            class_name = classification['predicted_class']
            stats['class_distribution'][class_name] = stats['class_distribution'].get(class_name, 0) + 1
        
        return jsonify(stats)
    
    return jsonify({'error': 'Failed to fetch statistics'}), 500

if __name__ == '__main__':
    # Create necessary directories
    os.makedirs(UPLOAD_FOLDER, exist_ok=True)
    os.makedirs('model', exist_ok=True)
    
    # Load model on startup
    if not load_model():
        logger.warning("Model could not be loaded. Some features may not work.")
        logger.warning("Please ensure the following files exist in the 'model' directory:")
        logger.warning("- model_mobilenetv2_full.pth (recommended) OR model_mobilenetv2_weights.pth")
        logger.warning("- model_config.json")
    
    # Create tables if they don't exist
    create_user_table()
    create_classification_table()
    
    app.run(debug=True, host='0.0.0.0', port=5000)