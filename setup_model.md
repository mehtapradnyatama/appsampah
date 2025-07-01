# 🤖 Model Setup Instructions

This guide will help you set up your trained model from the Jupyter notebook (`sampahv1.ipynb`) with the Flask web application.

## ⚠️ Important Requirements

Before setting up the model, ensure you have:

- **Python 3.11+** (same version used for training)
- **PyTorch 2.0.1** (exact version compatibility required)
- **Sufficient RAM** (at least 2GB free for model loading)
- **Model files** from completed notebook training

**Install dependencies:**
```bash
pip install -r requirements.txt
```

## 📁 Model Files Location

After running the notebook, your model files should be saved in:
```
D:\sampah\model\MobilenetV2\
├── model_mobilenetv2_full.pth      (~14MB - Complete model)
├── model_mobilenetv2_weights.pth   (~14MB - Weights only) 
└── model_config.json               (~1KB - Configuration)
```

**Note**: The `model_mobilenetv2_full.pth` contains both architecture and weights, making it the preferred choice for deployment.

## 🚀 Quick Setup

### Option 1: Automated Setup (Recommended)

**Windows:**
```bash
# Run the automated setup script
setup_model.bat
```

**Linux/Mac:**
```bash
# Make script executable and run
chmod +x setup_model.sh
./setup_model.sh
```

### Option 2: Manual Setup

### Step 1: Create Model Directory
```bash
# In your Flask app root directory
mkdir model
```

### Step 2: Copy Model Files
```bash
# Copy the essential files (Windows)
copy "D:\sampah\model\MobilenetV2\model_mobilenetv2_full.pth" model\
copy "D:\sampah\model\MobilenetV2\model_config.json" model\

# On Linux/Mac
cp "D:\sampah\model\MobilenetV2\model_mobilenetv2_full.pth" model/
cp "D:\sampah\model\MobilenetV2\model_config.json" model/
```

### Step 3: Verify Setup
```bash
# Check if files exist
ls model/
# Should show:
# model_mobilenetv2_full.pth
# model_config.json
```

### Step 4: Test Model Loading
```bash
python -c "from app import load_model; load_model()"
```

Expected output:
```
INFO:__main__:Loaded config: 5 classes, image size: (224, 224)
INFO:__main__:Full model loaded successfully from model_mobilenetv2_full.pth
INFO:__main__:Model loaded successfully with 5 classes: ['cardboard', 'glass', 'metal', 'paper', 'plastic']
```

## 🔧 Troubleshooting

### Problem: "Model files not found"
**Solution**: Ensure you've copied the files to the correct `model/` directory in your Flask app root.

### Problem: "Error loading model"
**Solution**: 
1. Check if PyTorch version matches (2.0.1)
2. Verify file integrity (not corrupted during copy)
3. Ensure you have enough RAM (model is ~14MB)

### Problem: "Config file not found"
**Solution**: Make sure `model_config.json` exists and contains:
```json
{
    "num_classes": 5,
    "image_size": [224, 224],
    "class_labels": {
        "0": "cardboard",
        "1": "glass", 
        "2": "metal",
        "3": "paper",
        "4": "plastic"
    },
    "batch_size": 32,
    "learning_rate": 0.0001,
    "epochs": 50,
    "device": "cuda:0",
    "model_state": {
        "test_accuracy": 0.9367,
        "test_loss": 0.1483
    }
}
```

## 📊 Model Information

- **Architecture**: MobileNetV2 with custom classifier
- **Input Size**: 224×224 RGB images  
- **Output**: 5 classes (cardboard, glass, metal, paper, plastic)
- **Accuracy**: 93.67% on test set
- **File Size**: ~14MB (compressed)
- **Inference Time**: ~200ms on CPU

## 🎯 Performance Verification

After setup, test the model with a sample image:

1. Start the Flask app: `python app.py`
2. Go to `http://localhost:5000/classify`
3. Upload a test image
4. Verify prediction matches expected results

Expected confidence scores should be similar to your notebook training results.

## 📝 Notes

- The Flask app prioritizes loading `model_mobilenetv2_full.pth` (complete model)
- If full model is not available, it falls back to `model_mobilenetv2_weights.pth`
- Configuration is loaded from `model_config.json` for consistent class labels
- Model runs in evaluation mode by default for inference

## 🔒 Production Deployment

For production deployment:

1. **Compress model files** (optional):
   ```bash
   gzip model_mobilenetv2_full.pth
   ```

2. **Environment variables**:
   ```bash
   export MODEL_PATH=model/
   export MODEL_FILE=model_mobilenetv2_full.pth
   ```

3. **Health check**: The app includes model validation on startup

## 💡 Tips

- Keep both `model_mobilenetv2_full.pth` and `model_mobilenetv2_weights.pth` as backup
- Monitor model loading time in production (should be <5 seconds)
- Consider using model quantization for faster inference if needed
- The model is CPU-optimized and doesn't require GPU for inference