# 🌍 EcoClassify - AI-Powered Waste Classification

<div align="center">
  <img src="static/images/logo.png" alt="EcoClassify Logo" width="200" height="200">
  
  [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
  [![Python 3.11+](https://img.shields.io/badge/python-3.11+-blue.svg)](https://www.python.org/downloads/)
  [![Flask](https://img.shields.io/badge/Flask-2.3.3-green.svg)](https://flask.palletsprojects.com/)
  [![PyTorch](https://img.shields.io/badge/PyTorch-2.0.1-red.svg)](https://pytorch.org/)
  
  **An intelligent web application that uses deep learning to classify waste materials and promote sustainable recycling practices.**
</div>

## 🎯 Features

### 🤖 AI-Powered Classification
- **93.67% Accuracy** using MobileNetV2 architecture
- **Real-time Processing** with instant results
- **5 Waste Categories**: Cardboard, Glass, Metal, Paper, Plastic
- **Confidence Scoring** for prediction reliability

### 🎨 Modern Web Interface
- **Responsive Design** works on all devices
- **Drag & Drop Upload** with preview functionality
- **Interactive Dashboard** with analytics and charts
- **Real-time Progress** indicators during processing

### 👥 User Management
- **Secure Authentication** via Supabase
- **Personal Dashboard** with classification history
- **Achievement System** to gamify recycling
- **Usage Statistics** and environmental impact tracking

### 🌱 Environmental Impact
- **CO₂ Savings Calculator** shows environmental benefits
- **Recycling Guidelines** for each waste category
- **Educational Content** about sustainable practices
- **Community Impact** tracking and leaderboards

## 🏗️ Architecture

### Backend Stack
- **Flask** - Web framework
- **PyTorch** - Deep learning inference
- **Supabase** - Database and authentication
- **Gunicorn** - WSGI HTTP Server

### Frontend Stack
- **Bootstrap 5** - UI framework
- **Chart.js** - Data visualization
- **Vanilla JavaScript** - Interactive features
- **Font Awesome** - Icons

### AI Model
- **Architecture**: MobileNetV2 with transfer learning
- **Framework**: PyTorch
- **Input Size**: 224x224 RGB images
- **Output**: 5-class classification with confidence scores
- **Training**: 50 epochs on balanced dataset (2,970 images)

## 🚀 Quick Start

### Prerequisites
- Python 3.11+
- Git
- Supabase account
- Model files (MobileNetV2 weights)

### Local Development Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/ecoclassify.git
   cd ecoclassify
   ```

2. **Create virtual environment**
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

4. **Set up environment variables**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

5. **Set up the database**
   - Create a new project in [Supabase](https://supabase.com)
   - Run the SQL schema from `database/schema.sql`
   - Update database credentials in `.env`

6. **Set up your trained model**
   
   **Automated setup (recommended):**
   ```bash
   # Windows
   setup_model.bat
   
   # Linux/Mac
   chmod +x setup_model.sh && ./setup_model.sh
   ```
   
   **Manual setup:**
   ```bash
   mkdir model
   cp "D:\sampah\model\MobilenetV2\model_mobilenetv2_full.pth" model/
   cp "D:\sampah\model\MobilenetV2\model_config.json" model/
   ```
   
   See [SETUP_MODEL.md](SETUP_MODEL.md) for detailed instructions.

7. **Run the application**
   ```bash
   python app.py
   ```

8. **Visit** `http://localhost:5000`

## 📁 Project Structure

```
ecoclassify/
├── app.py                 # Main Flask application
├── requirements.txt       # Python dependencies
├── Procfile              # Heroku deployment config
├── runtime.txt           # Python version specification
├── README.md             # Project documentation
├── SETUP_MODEL.md        # Model setup instructions
├── setup_model.bat       # Windows model setup script
├── setup_model.sh        # Linux/Mac model setup script
├── .env.example          # Environment variables template
├── .gitignore           # Git ignore rules
│
├── static/              # Static assets
│   ├── css/
│   │   └── style.css    # Main stylesheet
│   ├── js/
│   │   └── main.js      # JavaScript functionality
│   ├── images/          # Static images
│   └── uploads/         # User uploaded images
│
├── templates/           # HTML templates
│   ├── base.html        # Base template
│   ├── index.html       # Landing page
│   ├── login.html       # Login page
│   ├── register.html    # Registration page
│   ├── classify.html    # Classification interface
│   ├── dashboard.html   # User dashboard
│   └── about.html       # About page
│
├── model/               # AI model files
│   ├── model_mobilenetv2_full.pth      # Complete trained model
│   ├── model_mobilenetv2_weights.pth   # Model weights (fallback)
│   └── model_config.json               # Model configuration
│
├── database/            # Database schema and migrations
│   └── schema.sql       # Supabase database schema
│
└── docs/               # Additional documentation
    ├── API.md          # API documentation
    ├── DEPLOYMENT.md   # Deployment guide
    └── CONTRIBUTING.md # Contributing guidelines
```

## 🔧 Configuration

### Environment Variables (.env)

```bash
# Flask Configuration
FLASK_APP=app.py
FLASK_ENV=development
SECRET_KEY=your-secret-key-here

# Supabase Configuration
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your-anon-key-here

# File Upload Configuration
MAX_CONTENT_LENGTH=16777216  # 16MB
UPLOAD_FOLDER=static/uploads

# Model Configuration
MODEL_PATH=model/
MODEL_WEIGHTS=model_mobilenetv2_weights.pth
MODEL_CONFIG=model_config.json

# Security
SESSION_PERMANENT=False
SESSION_TYPE=filesystem
```

### Supabase Setup

1. **Create a new project** in Supabase
2. **Run the database schema**:
   - Go to SQL Editor in Supabase dashboard
   - Copy and run the contents of `database/schema.sql`
3. **Configure authentication**:
   - Enable email authentication
   - Set up email templates (optional)
4. **Get your credentials**:
   - Project URL: `https://your-project.supabase.co`
   - Anon Key: Found in Settings > API

## 🌐 Deployment

### Setting Up Your Trained Model

If you've trained the model using the provided Jupyter notebook (`sampahv1.ipynb`), follow these steps:

1. **Locate your model directory**
   ```
   Your training saved models to: D:\sampah\model\MobilenetV2\
   ```

2. **Copy model files to the Flask app**
   ```bash
   # From your training directory
   cp "D:\sampah\model\MobilenetV2\model_mobilenetv2_full.pth" model/
   cp "D:\sampah\model\MobilenetV2\model_config.json" model/
   ```

3. **Verify model files**
   ```bash
   ls model/
   # Should show:
   # model_mobilenetv2_full.pth
   # model_config.json
   ```

The application will automatically detect and load your trained model with the exact same architecture and weights used during training, ensuring consistent 93.67% accuracy.

## 🌐 Deployment

### Heroku Deployment

1. **Install Heroku CLI**
   ```bash
   # macOS
   brew install heroku/brew/heroku
   
   # Windows
   # Download from https://devcenter.heroku.com/articles/heroku-cli
   ```

2. **Login to Heroku**
   ```bash
   heroku login
   ```

3. **Create Heroku app**
   ```bash
   heroku create your-app-name
   ```

4. **Set environment variables**
   ```bash
   heroku config:set SECRET_KEY="your-secret-key"
   heroku config:set SUPABASE_URL="your-supabase-url"
   heroku config:set SUPABASE_KEY="your-supabase-key"
   ```

5. **Deploy**
   ```bash
   git add .
   git commit -m "Initial deployment"
   git push heroku main
   ```

6. **Open your app**
   ```bash
   heroku open
   ```

### Docker Deployment

1. **Build the image**
   ```bash
   docker build -t ecoclassify .
   ```

2. **Run the container**
   ```bash
   docker run -p 5000:5000 --env-file .env ecoclassify
   ```

### DigitalOcean App Platform

1. **Connect your repository** to DigitalOcean
2. **Configure environment variables** in the dashboard
3. **Deploy** with automatic builds on push

## 🧠 Model Information

### Training Details
- **Dataset**: 2,970 balanced waste images
- **Classes**: 5 (Cardboard, Glass, Metal, Paper, Plastic)
- **Split**: 75% training, 15% validation, 10% testing
- **Augmentation**: Rotation, flipping, color jitter
- **Architecture**: MobileNetV2 with custom classifier

### Performance Metrics
- **Test Accuracy**: 93.67%
- **Model Size**: ~14MB
- **Inference Time**: ~200ms on CPU
- **Training Time**: ~2 hours on RTX 4070 SUPER

### Model Files Required
- `model_mobilenetv2_full.pth` - Complete PyTorch model (architecture + weights) - **Recommended**
- `model_config.json` - Model configuration, class labels, and metadata
- `model_mobilenetv2_weights.pth` - Model weights only (fallback option)

**Note**: The application will first try to load the full model (`model_mobilenetv2_full.pth`). If not found, it will fallback to loading weights only (`model_mobilenetv2_weights.pth`) and reconstruct the architecture.

## 📊 API Documentation

### Classification Endpoint
```http
POST /classify
Content-Type: multipart/form-data

Parameters:
- file: Image file (JPG, PNG, JPEG)

Response:
{
  "predicted_class": "plastic",
  "confidence": 95.67,
  "class_probabilities": {
    "plastic": 95.67,
    "glass": 2.15,
    "metal": 1.12,
    "paper": 0.73,
    "cardboard": 0.33
  }
}
```

### Statistics Endpoint
```http
GET /api/stats
Authorization: Bearer <token>

Response:
{
  "total_classifications": 42,
  "class_distribution": {
    "plastic": 15,
    "paper": 12,
    "cardboard": 8,
    "glass": 4,
    "metal": 3
  },
  "recent_classifications": 7
}
```

## 🧪 Testing

### Run Tests
```bash
# Install test dependencies
pip install pytest pytest-cov

# Run tests
pytest

# Run with coverage
pytest --cov=app
```

### Test Coverage
- Unit tests for classification logic
- Integration tests for API endpoints
- UI tests with Selenium (optional)

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](docs/CONTRIBUTING.md) for guidelines.

### Development Workflow
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Run the test suite
6. Submit a pull request

### Code Style
- Follow PEP 8 for Python code
- Use ESLint for JavaScript
- Format with Prettier for HTML/CSS
- Document new features

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **PyTorch Team** for the excellent deep learning framework
- **Supabase** for the amazing backend-as-a-service platform
- **Bootstrap Team** for the responsive UI components
- **The Open Source Community** for inspiration and tools

## 📞 Support

- **Documentation**: [docs/](docs/)
- **Issues**: [GitHub Issues](https://github.com/yourusername/ecoclassify/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/ecoclassify/discussions)
- **Email**: support@ecoclassify.com

## 🗺️ Roadmap

### Version 2.0
- [ ] Mobile app (React Native)
- [ ] Batch processing API
- [ ] Advanced analytics dashboard
- [ ] Multi-language support
- [ ] Integration with IoT devices

### Version 3.0
- [ ] Computer vision for live camera feed
- [ ] Blockchain-based carbon credits
- [ ] Community marketplace
- [ ] AR/VR classification experience

---

<div align="center">
  <p><strong>Made with ❤️ for a sustainable future</strong></p>
  <p>
    <a href="https://github.com/yourusername/ecoclassify">⭐ Star us on GitHub</a> •
    <a href="https://twitter.com/ecoclassify">🐦 Follow on Twitter</a> •
    <a href="https://linkedin.com/company/ecoclassify">💼 Connect on LinkedIn</a>
  </p>
</div>