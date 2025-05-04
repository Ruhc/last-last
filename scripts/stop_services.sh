#!/bin/bash

echo "Stopping all services..."

# Stop HDFS
echo "Stopping HDFS..."
/opt/hadoop/sbin/stop-dfs.sh

# Stop Kafka
echo "Stopping Kafka..."
/opt/kafka/bin/kafka-server-stop.sh

# Stop Zookeeper
echo "Stopping Zookeeper..."
/opt/kafka/bin/zookeeper-server-stop.sh

# Stop Cassandra
echo "Stopping Cassandra..."
pkill -f cassandra

# Stop any running Python processes
echo "Stopping Python processes..."
if [ -f .pids ]; then
    kill $(cat .pids) 2>/dev/null || true
    rm .pids
fi

echo "All services stopped successfully!" 