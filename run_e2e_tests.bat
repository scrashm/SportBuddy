@echo off
echo ===============================================
echo   Sport Buddy - End-to-End Testing Setup
echo ===============================================

echo.
echo Step 1: Checking Node.js and npm...
node --version
npm --version

if %errorlevel% neq 0 (
    echo ERROR: Node.js is not installed or not in PATH
    echo Please install Node.js from https://nodejs.org/
    pause
    exit /b 1
)

echo.
echo Step 2: Installing backend dependencies...
npm install

if %errorlevel% neq 0 (
    echo ERROR: Failed to install backend dependencies
    pause
    exit /b 1
)

echo.
echo Step 3: Checking Flutter installation...
cd frontend
flutter --version

if %errorlevel% neq 0 (
    echo ERROR: Flutter is not installed or not in PATH
    echo Please install Flutter from https://flutter.dev/
    pause
    exit /b 1
)

echo.
echo Step 4: Installing Flutter dependencies...
flutter pub get

if %errorlevel% neq 0 (
    echo ERROR: Failed to install Flutter dependencies
    cd ..
    pause
    exit /b 1
)

cd ..

echo.
echo Step 5: Environment configuration check...
if not exist .env (
    echo WARNING: .env file not found. Creating template...
    copy nul .env > nul
    echo # SportBuddy Backend Environment Variables >> .env
    echo DATABASE_URL=postgresql://username:password@localhost:5432/sportbuddy_db >> .env
    echo TELEGRAM_BOT_TOKEN=your_telegram_bot_token_here >> .env
    echo PORT=3000 >> .env
    echo NODE_ENV=development >> .env
    echo.
    echo IMPORTANT: Please update the .env file with your actual credentials
    echo before running the tests.
)

if not exist frontend\.env (
    echo Creating frontend .env file...
    echo API_BASE_URL=http://localhost:3000 > frontend\.env
)

echo.
echo Step 6: Creating screenshots directory...
if not exist frontend\test\screenshots mkdir frontend\test\screenshots

echo.
echo ===============================================
echo   Test Execution Options
echo ===============================================
echo.
echo 1. Start Backend Server (in new window)
echo 2. Run Backend API Tests
echo 3. Run Flutter Integration Tests  
echo 4. Generate Test Report Template
echo 5. Complete E2E Test (Manual Steps Required)
echo 6. Exit
echo.

:menu
set /p choice="Select option (1-6): "

if "%choice%"=="1" goto start_backend
if "%choice%"=="2" goto test_backend
if "%choice%"=="3" goto test_flutter
if "%choice%"=="4" goto generate_report
if "%choice%"=="5" goto complete_e2e
if "%choice%"=="6" goto exit
echo Invalid choice. Please select 1-6.
goto menu

:start_backend
echo.
echo Starting backend server in new window...
start "SportBuddy Backend" cmd /c "node server.js & pause"
echo Backend server started. Check the new window for logs.
echo Press any key to return to menu...
pause > nul
goto menu

:test_backend
echo.
echo Running backend API tests...
node test_telegram_auth.js
echo.
echo Press any key to return to menu...
pause > nul
goto menu

:test_flutter
echo.
echo Running Flutter integration tests...
cd frontend
flutter test test/telegram_auth_integration_test.dart
cd ..
echo.
echo Press any key to return to menu...
pause > nul
goto menu

:generate_report
echo.
echo Generating test report template...
echo Test report template created at: frontend/test/QA_TEST_REPORT.md
echo Please fill out the report after completing manual tests.
echo.
echo Press any key to return to menu...
pause > nul
goto menu

:complete_e2e
echo.
echo ===============================================
echo   Complete End-to-End Test Instructions
echo ===============================================
echo.
echo PREREQUISITES:
echo 1. Backend server is running (Option 1)
echo 2. Physical device connected with Telegram app
echo 3. TELEGRAM_BOT_TOKEN configured in .env
echo 4. Database is accessible
echo.
echo MANUAL TESTING STEPS:
echo 1. Run: flutter devices (to see connected devices)
echo 2. Run: cd frontend && flutter run --release
echo 3. On device: Tap "Войти через Telegram"
echo 4. Complete login flow in Telegram
echo 5. Take screenshots at each step
echo 6. Fill out QA_TEST_REPORT.md
echo.
echo AUTOMATED TESTS:
echo - Backend API tests: Option 2
echo - Flutter integration tests: Option 3
echo.
echo FILES TO REVIEW:
echo - frontend/test/telegram_login_e2e_test.md (Testing guide)
echo - frontend/test/QA_TEST_REPORT.md (Report template)
echo - test_telegram_auth.js (Backend test script)
echo.
echo Press any key to return to menu...
pause > nul
goto menu

:exit
echo.
echo ===============================================
echo   Test Setup Complete
echo ===============================================
echo.
echo Next Steps:
echo 1. Configure your .env file with real credentials
echo 2. Start the backend server (Option 1)
echo 3. Run the tests (Options 2-5)
echo 4. Complete the QA report
echo.
echo Happy testing!
echo.
pause
exit /b 0
