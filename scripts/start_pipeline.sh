#!/bin/bash

# Exit on error
set -e

echo "Starting the image processing pipeline..."

# Start all services
./scripts/start_services.sh

# Wait for services to be ready
echo "Waiting for services to be ready..."
sleep 10

# Start Spark processor in the background
echo "Starting Spark processor..."
python3 src/processor/image_processor.py &
SPARK_PID=$!

# Start web interface
echo "Starting web interface..."
python3 src/web/app.py &
WEB_PID=$!

# Save PIDs to file for later cleanup
echo $SPARK_PID > .pids
echo $WEB_PID >> .pids

echo "Pipeline started successfully!"
echo "Web interface available at http://localhost:5000"
echo "Press Ctrl+C to stop all services"

# Wait for user interrupt
trap "kill $(cat .pids); rm .pids; echo 'Pipeline stopped'" INT
wait 