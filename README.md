# Image Processing Pipeline for Low-Power Servers

This project implements a data pipeline for processing, storing, and managing graphical data (images, GIFs) using open-source technologies in a resource-constrained environment.

## Technologies Used

- Apache Kafka (streaming)
- Apache Spark (processing)
- Apache Cassandra (metadata storage)
- HDFS (binary data storage)
- Python (processing scripts)
- Flask (web interface)

## System Requirements

- Ubuntu Server
- 2 CPU cores
- 4 GB RAM
- 50 GB HDD

## Project Structure

```
.
├── config/                 # Configuration files
├── scripts/               # Setup and utility scripts
├── src/                   # Source code
│   ├── producer/         # Kafka producer
│   ├── processor/        # Spark processing
│   ├── storage/          # Storage handlers
│   └── web/             # Flask web interface
├── tests/                # Test files
└── requirements.txt      # Python dependencies
```

## Setup Instructions

1. Install system dependencies:
```bash
sudo apt-get update
sudo apt-get install -y python3-pip openjdk-8-jdk
```

2. Install Python dependencies:
```bash
pip3 install -r requirements.txt
```

3. Configure and start services:
```bash
./scripts/setup.sh
```

4. Start the pipeline:
```bash
./scripts/start_pipeline.sh
```

## Configuration

- HDFS: 2 replicas (optimized for low resources)
- Cassandra: Single node with SimpleStrategy
- Kafka: Single broker configuration
- Spark: Memory-optimized settings

## Monitoring

Use the following tools for monitoring:
- htop: System resource usage
- Spark UI: Processing metrics
- Hue: HDFS file browser
- Web interface: Image management

## License

MIT License 