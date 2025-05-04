#!/bin/bash

# Exit on error
set -e

echo "Starting setup process..."

# Update system and install basic dependencies
echo "Installing system dependencies..."
sudo apt-get update
sudo apt-get install -y \
    python3-pip \
    openjdk-8-jdk \
    wget \
    curl \
    gnupg2 \
    software-properties-common

# Install Python dependencies
echo "Installing Python dependencies..."
pip3 install -r requirements.txt

# Download and install Hadoop
if [ ! -d /opt/hadoop ]; then
    echo "Installing Hadoop..."
    if [ ! -f hadoop-3.3.6.tar.gz ]; then
        wget https://archive.apache.org/dist/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz
    fi
    tar -xzf hadoop-3.3.6.tar.gz
    sudo mv hadoop-3.3.6 /opt/hadoop
    rm hadoop-3.3.6.tar.gz
else
    echo "Hadoop already installed, skipping download."
fi

# Configure Hadoop
echo "Configuring Hadoop..."
cat > /opt/hadoop/etc/hadoop/core-site.xml << EOF
<?xml version="1.0"?>
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://localhost:9000</value>
    </property>
</configuration>
EOF

cat > /opt/hadoop/etc/hadoop/hdfs-site.xml << EOF
<?xml version="1.0"?>
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>2</value>
    </property>
    <property>
        <name>dfs.namenode.name.dir</name>
        <value>/opt/hadoop/data/namenode</value>
    </property>
    <property>
        <name>dfs.datanode.data.dir</name>
        <value>/opt/hadoop/data/datanode</value>
    </property>
</configuration>
EOF

# Download and install Kafka
if [ ! -d /opt/kafka ]; then
    echo "Installing Kafka..."
    if [ ! -f kafka_2.13-3.5.1.tgz ]; then
        wget https://archive.apache.org/dist/kafka/3.5.1/kafka_2.13-3.5.1.tgz
    fi
    tar -xzf kafka_2.13-3.5.1.tgz
    sudo mv kafka_2.13-3.5.1 /opt/kafka
    rm kafka_2.13-3.5.1.tgz
else
    echo "Kafka already installed, skipping download."
fi

# Configure Kafka
echo "Configuring Kafka..."
cat > /opt/kafka/config/server.properties << EOF
broker.id=0
listeners=PLAINTEXT://localhost:9092
log.dirs=/opt/kafka/logs
zookeeper.connect=localhost:2181
EOF

# Download and install Cassandra
if [ ! -d /opt/cassandra ]; then
    echo "Installing Cassandra..."
    if [ ! -f apache-cassandra-4.1.2-bin.tar.gz ]; then
        wget https://archive.apache.org/dist/cassandra/4.1.2/apache-cassandra-4.1.2-bin.tar.gz
    fi
    tar -xzf apache-cassandra-4.1.2-bin.tar.gz
    sudo mv apache-cassandra-4.1.2 /opt/cassandra
    rm apache-cassandra-4.1.2-bin.tar.gz
else
    echo "Cassandra already installed, skipping download."
fi

# Configure Cassandra
echo "Configuring Cassandra..."
cat > /opt/cassandra/conf/cassandra.yaml << EOF
cluster_name: 'ImagePipeline'
num_tokens: 256
seed_provider:
    - class_name: org.apache.cassandra.locator.SimpleSeedProvider
      parameters:
          - seeds: "127.0.0.1"
listen_address: localhost
rpc_address: localhost
endpoint_snitch: SimpleSnitch
EOF

# Create necessary directories
echo "Creating directories..."
mkdir -p /opt/hadoop/data/namenode
mkdir -p /opt/hadoop/data/datanode
mkdir -p /opt/kafka/logs
mkdir -p /opt/cassandra/data
mkdir -p /opt/cassandra/commitlog
mkdir -p /opt/cassandra/saved_caches

# Set up environment variables
echo "Setting up environment variables..."
cat > ~/.bashrc << EOF
export HADOOP_HOME=/opt/hadoop
export PATH=\$PATH:\$HADOOP_HOME/bin
export KAFKA_HOME=/opt/kafka
export PATH=\$PATH:\$KAFKA_HOME/bin
export CASSANDRA_HOME=/opt/cassandra
export PATH=\$PATH:\$CASSANDRA_HOME/bin
EOF

# Initialize HDFS
echo "Initializing HDFS..."
/opt/hadoop/bin/hdfs namenode -format

echo "Setup completed successfully!"
echo "Please source ~/.bashrc to update your environment variables"
echo "Then run ./scripts/start_services.sh to start all services" 