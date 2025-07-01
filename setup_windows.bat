@echo off
REM ================================
REM EcoClassify Model Setup Script (Windows)
REM ================================

echo.
echo ============================================
echo  EcoClassify Model Setup
echo ============================================
echo.

REM Check if model directory exists
if not exist "model" (
    echo [INFO] Creating model directory...
    mkdir model
) else (
    echo [INFO] Model directory already exists.
)

REM Define source paths (from notebook training)
set SOURCE_DIR=D:\sampah\model\MobilenetV2
set TARGET_DIR=model

echo [INFO] Copying model files from training directory...
echo [INFO] Source: %SOURCE_DIR%
echo [INFO] Target: %TARGET_DIR%
echo.

REM Check if source directory exists
if not exist "%SOURCE_DIR%" (
    echo [ERROR] Source directory not found: %SOURCE_DIR%
    echo [ERROR] Please make sure you have trained the model using the notebook first.
    echo [ERROR] The training should create files in: D:\sampah\model\MobilenetV2\
    pause
    exit /b 1
)

REM Copy full model (priority)
if exist "%SOURCE_DIR%\model_mobilenetv2_full.pth" (
    echo [INFO] Copying full model...
    copy "%SOURCE_DIR%\model_mobilenetv2_full.pth" "%TARGET_DIR%\" >nul
    if errorlevel 1 (
        echo [ERROR] Failed to copy full model file.
        pause
        exit /b 1
    ) else (
        echo [SUCCESS] Full model copied successfully.
    )
) else (
    echo [WARNING] Full model not found, will try weights file...
)

REM Copy weights file (fallback)
if exist "%SOURCE_DIR%\model_mobilenetv2_weights.pth" (
    echo [INFO] Copying model weights...
    copy "%SOURCE_DIR%\model_mobilenetv2_weights.pth" "%TARGET_DIR%\" >nul
    if errorlevel 1 (
        echo [ERROR] Failed to copy weights file.
        pause
        exit /b 1
    ) else (
        echo [SUCCESS] Model weights copied successfully.
    )
) else (
    echo [WARNING] Model weights file not found.
)

REM Copy configuration file (required)
if exist "%SOURCE_DIR%\model_config.json" (
    echo [INFO] Copying model configuration...
    copy "%SOURCE_DIR%\model_config.json" "%TARGET_DIR%\" >nul
    if errorlevel 1 (
        echo [ERROR] Failed to copy config file.
        pause
        exit /b 1
    ) else (
        echo [SUCCESS] Model configuration copied successfully.
    )
) else (
    echo [ERROR] Model configuration file not found: %SOURCE_DIR%\model_config.json
    echo [ERROR] This file is required for the application to work.
    pause
    exit /b 1
)

echo.
echo ============================================
echo  Setup Verification
echo ============================================
echo.

REM Verify copied files
echo [INFO] Verifying copied files...
if exist "%TARGET_DIR%\model_mobilenetv2_full.pth" (
    echo [OK] Full model: model_mobilenetv2_full.pth
) else if exist "%TARGET_DIR%\model_mobilenetv2_weights.pth" (
    echo [OK] Model weights: model_mobilenetv2_weights.pth
) else (
    echo [ERROR] No model file found in target directory.
    pause
    exit /b 1
)

if exist "%TARGET_DIR%\model_config.json" (
    echo [OK] Configuration: model_config.json
) else (
    echo [ERROR] Configuration file missing.
    pause
    exit /b 1
)

REM Display file sizes
echo.
echo [INFO] Model file details:
for %%F in ("%TARGET_DIR%\*.pth") do (
    echo   %%~nxF - %%~zF bytes
)
for %%F in ("%TARGET_DIR%\*.json") do (
    echo   %%~nxF - %%~zF bytes
)

echo.
echo ============================================
echo  Setup Complete!
echo ============================================
echo.
echo [SUCCESS] Model files have been set up successfully.
echo [INFO] You can now run the Flask application:
echo.
echo   python app.py
echo.
echo [INFO] The application will be available at:
echo   http://localhost:5000
echo.
echo [INFO] For troubleshooting, see SETUP_MODEL.md
echo.

REM Optional: Test model loading
set /p test_model="Would you like to test model loading? (y/n): "
if /i "%test_model%"=="y" (
    echo.
    echo [INFO] Testing model loading...
    python -c "from app import load_model; result = load_model(); print('Model loading:', 'SUCCESS' if result else 'FAILED')"
    if errorlevel 1 (
        echo [WARNING] Model loading test failed. Check the error messages above.
    ) else (
        echo [SUCCESS] Model loading test passed!
    )
)

echo.
echo Press any key to exit...
pause >nul