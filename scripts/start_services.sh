#!/bin/bash

# Exit on error
set -e

echo "Starting all services..."

# Start HDFS
echo "Starting HDFS..."
/opt/hadoop/sbin/start-dfs.sh

# Start Zookeeper (required for Kafka)
echo "Starting Zookeeper..."
/opt/kafka/bin/zookeeper-server-start.sh -daemon /opt/kafka/config/zookeeper.properties

# Wait for Zookeeper to start
sleep 5

# Start Kafka
echo "Starting Kafka..."
/opt/kafka/bin/kafka-server-start.sh -daemon /opt/kafka/config/server.properties

# Start Cassandra
echo "Starting Cassandra..."
/opt/cassandra/bin/cassandra

# Wait for services to start
echo "Waiting for services to start..."
sleep 10

# Create Kafka topic
echo "Creating Kafka topic..."
/opt/kafka/bin/kafka-topics.sh --create \
    --bootstrap-server localhost:9092 \
    --topic images \
    --partitions 1 \
    --replication-factor 2 || echo "Topic 'images' already exists or not enough brokers for replication"

# Create Cassandra keyspace and table
echo "Creating Cassandra schema..."
cqlsh -e "
CREATE KEYSPACE IF NOT EXISTS images_db
WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};

USE images_db;

CREATE TABLE IF NOT EXISTS images_metadata (
    image_id TEXT PRIMARY KEY,
    format TEXT,
    width INT,
    height INT,
    upload_date TIMESTAMP,
    file_size BIGINT,
    hash TEXT
);"

echo "All services started successfully!"
echo "You can now run the image processing pipeline" 