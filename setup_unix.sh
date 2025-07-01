#!/bin/bash
# ================================
# EcoClassify Model Setup Script (Linux/Mac)
# ================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo
    echo "============================================"
    echo "  $1"
    echo "============================================"
    echo
}

# Main setup
print_header "EcoClassify Model Setup"

# Check if model directory exists
if [ ! -d "model" ]; then
    print_info "Creating model directory..."
    mkdir -p model
else
    print_info "Model directory already exists."
fi

# Define source paths (adjust if your training directory is different)
SOURCE_DIR="/mnt/d/sampah/model/MobilenetV2"  # Windows path in WSL
if [ ! -d "$SOURCE_DIR" ]; then
    # Try alternative paths
    SOURCE_DIR="$HOME/sampah/model/MobilenetV2"
    if [ ! -d "$SOURCE_DIR" ]; then
        SOURCE_DIR="./training_output/model/MobilenetV2"
    fi
fi

TARGET_DIR="model"

print_info "Copying model files from training directory..."
print_info "Source: $SOURCE_DIR"
print_info "Target: $TARGET_DIR"
echo

# Check if source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    print_error "Source directory not found: $SOURCE_DIR"
    print_error "Please specify the correct path to your trained model:"
    read -p "Enter the full path to your model directory: " SOURCE_DIR
    
    if [ ! -d "$SOURCE_DIR" ]; then
        print_error "Directory still not found. Exiting."
        exit 1
    fi
fi

# Function to copy file with verification
copy_file() {
    local src="$1"
    local dst="$2"
    local name="$3"
    
    if [ -f "$src" ]; then
        print_info "Copying $name..."
        if cp "$src" "$dst/"; then
            print_success "$name copied successfully."
            return 0
        else
            print_error "Failed to copy $name."
            return 1
        fi
    else
        print_warning "$name not found: $src"
        return 1
    fi
}

# Copy full model (priority)
copy_file "$SOURCE_DIR/model_mobilenetv2_full.pth" "$TARGET_DIR" "full model"
FULL_MODEL_OK=$?

# Copy weights file (fallback)
copy_file "$SOURCE_DIR/model_mobilenetv2_weights.pth" "$TARGET_DIR" "model weights"
WEIGHTS_OK=$?

# Copy configuration file (required)
copy_file "$SOURCE_DIR/model_config.json" "$TARGET_DIR" "model configuration"
CONFIG_OK=$?

# Check if we have at least one model file
if [ $FULL_MODEL_OK -ne 0 ] && [ $WEIGHTS_OK -ne 0 ]; then
    print_error "No model files were copied successfully."
    exit 1
fi

# Configuration file is mandatory
if [ $CONFIG_OK -ne 0 ]; then
    print_error "Configuration file is required for the application to work."
    exit 1
fi

print_header "Setup Verification"

# Verify copied files
print_info "Verifying copied files..."
if [ -f "$TARGET_DIR/model_mobilenetv2_full.pth" ]; then
    print_success "Full model: model_mobilenetv2_full.pth"
elif [ -f "$TARGET_DIR/model_mobilenetv2_weights.pth" ]; then
    print_success "Model weights: model_mobilenetv2_weights.pth"
else
    print_error "No model file found in target directory."
    exit 1
fi

if [ -f "$TARGET_DIR/model_config.json" ]; then
    print_success "Configuration: model_config.json"
else
    print_error "Configuration file missing."
    exit 1
fi

# Display file sizes
echo
print_info "Model file details:"
for file in "$TARGET_DIR"/*.pth "$TARGET_DIR"/*.json; do
    if [ -f "$file" ]; then
        size=$(ls -lh "$file" | awk '{print $5}')
        filename=$(basename "$file")
        echo "  $filename - $size"
    fi
done

print_header "Setup Complete!"

print_success "Model files have been set up successfully."
print_info "You can now run the Flask application:"
echo
echo "  python app.py"
echo
print_info "The application will be available at:"
echo "  http://localhost:5000"
echo
print_info "For troubleshooting, see SETUP_MODEL.md"
echo

# Optional: Test model loading
read -p "Would you like to test model loading? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo
    print_info "Testing model loading..."
    if python3 -c "from app import load_model; result = load_model(); print('Model loading:', 'SUCCESS' if result else 'FAILED')"; then
        print_success "Model loading test passed!"
    else
        print_warning "Model loading test failed. Check the error messages above."
    fi
fi

echo
print_info "Setup script completed."