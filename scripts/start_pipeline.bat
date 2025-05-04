@echo off
echo Starting the image processing pipeline...

REM Start all services
call scripts\start_services.bat

REM Wait for services to be ready
echo Waiting for services to be ready...
timeout /t 10

REM Start Spark processor in the background
echo Starting Spark processor...
start /B python src\processor\image_processor.py

REM Start web interface
echo Starting web interface...
start /B python src\web\app.py

echo Pipeline started successfully!
echo Web interface available at http://localhost:5000
echo Press Ctrl+C to stop all services

REM Keep the window open
pause 