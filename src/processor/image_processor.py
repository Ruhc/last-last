from pyspark.sql import SparkSession
from pyspark.sql.functions import from_json, col, current_timestamp
from pyspark.sql.types import StructType, StructField, StringType, IntegerType, LongType, TimestampType
import base64
import io
from datetime import datetime

class ImageProcessor:
    def __init__(self):
        self.spark = SparkSession.builder \
            .appName("ImageProcessingPipeline") \
            .config("spark.jars.packages", "org.apache.spark:spark-sql-kafka-0-10_2.12:3.4.1") \
            .config("spark.cassandra.connection.host", "localhost") \
            .config("spark.cassandra.connection.port", "9042") \
            .config("spark.cassandra.auth.username", "") \
            .config("spark.cassandra.auth.password", "") \
            .getOrCreate()

        # Define schema for Kafka messages
        self.schema = StructType([
            StructField("image_id", StringType()),
            StructField("file_path", StringType()),
            StructField("file_size", LongType()),
            StructField("mime_type", StringType()),
            StructField("hash", StringType()),
            StructField("upload_date", StringType()),
            StructField("metadata", StructType([
                StructField("format", StringType()),
                StructField("width", IntegerType()),
                StructField("height", IntegerType()),
                StructField("mode", StringType())
            ])),
            StructField("image_bytes", StringType())
        ])

    def process_stream(self):
        """Process the Kafka stream and store data in Cassandra and HDFS."""
        # Read from Kafka
        df = self.spark \
            .readStream \
            .format("kafka") \
            .option("kafka.bootstrap.servers", "localhost:9092") \
            .option("subscribe", "images") \
            .load()

        # Parse JSON and extract fields
        parsed_df = df.select(
            from_json(col("value").cast("string"), self.schema).alias("data")
        ).select("data.*")

        # Process each batch
        def process_batch(batch_df, batch_id):
            if batch_df.isEmpty():
                return

            # Store metadata in Cassandra
            metadata_df = batch_df.select(
                "image_id",
                col("metadata.format").alias("format"),
                col("metadata.width").alias("width"),
                col("metadata.height").alias("height"),
                current_timestamp().alias("upload_date"),
                "file_size",
                "hash"
            )

            metadata_df.write \
                .format("org.apache.spark.sql.cassandra") \
                .options(table="images_metadata", keyspace="images_db") \
                .mode("append") \
                .save()

            # Store images in HDFS
            for row in batch_df.collect():
                try:
                    # Decode base64 image
                    image_bytes = base64.b64decode(row.image_bytes)
                    
                    # Save to HDFS
                    hdfs_path = f"hdfs://localhost:9000/user/images/{row.image_id}.{row.metadata.format.lower()}"
                    
                    # Convert to RDD and save
                    image_rdd = self.spark.sparkContext.parallelize([image_bytes])
                    image_rdd.saveAsTextFile(hdfs_path)
                    
                    print(f"Processed image {row.image_id}")
                except Exception as e:
                    print(f"Error processing image {row.image_id}: {str(e)}")

        # Start streaming query
        query = parsed_df.writeStream \
            .foreachBatch(process_batch) \
            .outputMode("append") \
            .start()

        return query

    def stop(self):
        """Stop the Spark session."""
        self.spark.stop()

def main():
    processor = ImageProcessor()
    try:
        query = processor.process_stream()
        query.awaitTermination()
    finally:
        processor.stop()

if __name__ == "__main__":
    main() 