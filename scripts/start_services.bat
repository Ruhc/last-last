@echo off
echo Starting all services...

REM Start HDFS
echo Starting HDFS...
/opt/hadoop/sbin/start-dfs.sh

REM Start Zookeeper
echo Starting Zookeeper...
/opt/kafka/bin/zookeeper-server-start.sh -daemon /opt/kafka/config/zookeeper.properties

REM Wait for Zookeeper to start
timeout /t 5

REM Start Kafka
echo Starting Kafka...
/opt/kafka/bin/kafka-server-start.sh -daemon /opt/kafka/config/server.properties

REM Start Cassandra
echo Starting Cassandra...
/opt/cassandra/bin/cassandra

REM Wait for services to start
echo Waiting for services to start...
timeout /t 10

REM Create Kafka topic
echo Creating Kafka topic...
/opt/kafka/bin/kafka-topics.sh --create --bootstrap-server localhost:9092 --topic images --partitions 1 --replication-factor 1

REM Create Cassandra keyspace and table
echo Creating Cassandra schema...
cqlsh -e "CREATE KEYSPACE IF NOT EXISTS images_db WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1}; USE images_db; CREATE TABLE IF NOT EXISTS images_metadata (image_id TEXT PRIMARY KEY, format TEXT, width INT, height INT, upload_date TIMESTAMP, file_size BIGINT, hash TEXT);"

echo All services started successfully!
echo You can now run the image processing pipeline 