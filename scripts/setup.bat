@echo off
echo Starting setup process...

REM Update system and install basic dependencies
echo Installing system dependencies...
sudo apt-get update
sudo apt-get install -y python3-pip openjdk-8-jdk wget curl gnupg2 software-properties-common

REM Install Python dependencies
echo Installing Python dependencies...
pip3 install -r requirements.txt

REM Download and install Hadoop
echo Installing Hadoop...
wget https://dlcdn.apache.org/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz
tar -xzf hadoop-3.3.6.tar.gz
sudo mv hadoop-3.3.6 /opt/hadoop
del hadoop-3.3.6.tar.gz

REM Configure Hadoop
echo Configuring Hadoop...
(
echo ^<?xml version="1.0"?^>
echo ^<configuration^>
echo     ^<property^>
echo         ^<name^>fs.defaultFS^</name^>
echo         ^<value^>hdfs://localhost:9000^</value^>
echo     ^</property^>
echo ^</configuration^>
) > /opt/hadoop/etc/hadoop/core-site.xml

(
echo ^<?xml version="1.0"?^>
echo ^<configuration^>
echo     ^<property^>
echo         ^<name^>dfs.replication^</name^>
echo         ^<value^>2^</value^>
echo     ^</property^>
echo     ^<property^>
echo         ^<name^>dfs.namenode.name.dir^</name^>
echo         ^<value^>/opt/hadoop/data/namenode^</value^>
echo     ^</property^>
echo     ^<property^>
echo         ^<name^>dfs.datanode.data.dir^</name^>
echo         ^<value^>/opt/hadoop/data/datanode^</value^>
echo     ^</property^>
echo ^</configuration^>
) > /opt/hadoop/etc/hadoop/hdfs-site.xml

REM Download and install Kafka
echo Installing Kafka...
wget https://dlcdn.apache.org/kafka/3.5.1/kafka_2.13-3.5.1.tgz
tar -xzf kafka_2.13-3.5.1.tgz
sudo mv kafka_2.13-3.5.1 /opt/kafka
del kafka_2.13-3.5.1.tgz

REM Configure Kafka
echo Configuring Kafka...
(
echo broker.id=0
echo listeners=PLAINTEXT://localhost:9092
echo log.dirs=/opt/kafka/logs
echo zookeeper.connect=localhost:2181
) > /opt/kafka/config/server.properties

REM Download and install Cassandra
echo Installing Cassandra...
wget https://dlcdn.apache.org/cassandra/4.1.2/apache-cassandra-4.1.2-bin.tar.gz
tar -xzf apache-cassandra-4.1.2-bin.tar.gz
sudo mv apache-cassandra-4.1.2 /opt/cassandra
del apache-cassandra-4.1.2-bin.tar.gz

REM Configure Cassandra
echo Configuring Cassandra...
(
echo cluster_name: 'ImagePipeline'
echo num_tokens: 256
echo seed_provider:
echo     - class_name: org.apache.cassandra.locator.SimpleSeedProvider
echo       parameters:
echo           - seeds: "127.0.0.1"
echo listen_address: localhost
echo rpc_address: localhost
echo endpoint_snitch: SimpleSnitch
) > /opt/cassandra/conf/cassandra.yaml

REM Create necessary directories
echo Creating directories...
mkdir /opt/hadoop/data/namenode
mkdir /opt/hadoop/data/datanode
mkdir /opt/kafka/logs
mkdir /opt/cassandra/data
mkdir /opt/cassandra/commitlog
mkdir /opt/cassandra/saved_caches

REM Set up environment variables
echo Setting up environment variables...
(
echo export HADOOP_HOME=/opt/hadoop
echo export PATH=$PATH:$HADOOP_HOME/bin
echo export KAFKA_HOME=/opt/kafka
echo export PATH=$PATH:$KAFKA_HOME/bin
echo export CASSANDRA_HOME=/opt/cassandra
echo export PATH=$PATH:$CASSANDRA_HOME/bin
) > ~/.bashrc

REM Initialize HDFS
echo Initializing HDFS...
/opt/hadoop/bin/hdfs namenode -format

echo Setup completed successfully!
echo Please source ~/.bashrc to update your environment variables
echo Then run ./scripts/start_services.bat to start all services 