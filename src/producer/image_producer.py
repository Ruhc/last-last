import os
import json
import base64
import hashlib
from datetime import datetime
from kafka import KafkaProducer
from PIL import Image
import magic

class ImageProducer:
    def __init__(self, bootstrap_servers=['localhost:9092']):
        self.producer = KafkaProducer(
            bootstrap_servers=bootstrap_servers,
            value_serializer=lambda v: json.dumps(v).encode('utf-8')
        )
        self.topic = 'images'

    def _calculate_hash(self, file_path):
        """Calculate SHA-256 hash of the file."""
        sha256_hash = hashlib.sha256()
        with open(file_path, "rb") as f:
            for byte_block in iter(lambda: f.read(4096), b""):
                sha256_hash.update(byte_block)
        return sha256_hash.hexdigest()

    def _get_image_metadata(self, file_path):
        """Extract metadata from image file."""
        with Image.open(file_path) as img:
            return {
                'format': img.format,
                'width': img.width,
                'height': img.height,
                'mode': img.mode
            }

    def send_image(self, file_path):
        """Send image to Kafka topic."""
        try:
            # Generate unique ID
            image_id = f"img_{datetime.now().strftime('%Y%m%d_%H%M%S')}_{os.path.basename(file_path)}"
            
            # Get file metadata
            file_size = os.path.getsize(file_path)
            mime_type = magic.from_file(file_path, mime=True)
            file_hash = self._calculate_hash(file_path)
            
            # Get image-specific metadata
            image_metadata = self._get_image_metadata(file_path)
            
            # Read file content
            with open(file_path, 'rb') as f:
                image_bytes = base64.b64encode(f.read()).decode('utf-8')
            
            # Prepare message
            message = {
                'image_id': image_id,
                'file_path': file_path,
                'file_size': file_size,
                'mime_type': mime_type,
                'hash': file_hash,
                'upload_date': datetime.now().isoformat(),
                'metadata': image_metadata,
                'image_bytes': image_bytes
            }
            
            # Send to Kafka
            self.producer.send(self.topic, message)
            self.producer.flush()
            
            print(f"Successfully sent image {image_id} to Kafka")
            return image_id
            
        except Exception as e:
            print(f"Error sending image to Kafka: {str(e)}")
            raise

    def close(self):
        """Close the Kafka producer."""
        self.producer.close()

def main():
    # Example usage
    producer = ImageProducer()
    
    # Example: Send a single image
    try:
        image_path = "path/to/your/image.jpg"  # Replace with actual image path
        image_id = producer.send_image(image_path)
        print(f"Image sent with ID: {image_id}")
    finally:
        producer.close()

if __name__ == "__main__":
    main() 