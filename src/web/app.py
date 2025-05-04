from flask import Flask, render_template, request, jsonify, send_file
from cassandra.cluster import Cluster
from cassandra.auth import PlainTextAuthProvider
import os
import tempfile
from hdfs import InsecureClient
from werkzeug.utils import secure_filename
from src.producer.image_producer import ImageProducer
import json

app = Flask(__name__)
app.config['UPLOAD_FOLDER'] = tempfile.gettempdir()
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # 16MB max file size

# Initialize Cassandra connection
cluster = Cluster(['localhost'])
session = cluster.connect('images_db')

# Initialize HDFS client
hdfs_client = InsecureClient('http://localhost:50070')

# Initialize Kafka producer
producer = ImageProducer()

@app.route('/')
def index():
    """Render the main page."""
    return render_template('index.html')

@app.route('/upload', methods=['POST'])
def upload_file():
    """Handle file upload."""
    if 'file' not in request.files:
        return jsonify({'error': 'No file part'}), 400
    
    file = request.files['file']
    if file.filename == '':
        return jsonify({'error': 'No selected file'}), 400
    
    if file:
        filename = secure_filename(file.filename)
        filepath = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        file.save(filepath)
        
        try:
            # Send to Kafka
            image_id = producer.send_image(filepath)
            
            # Clean up temporary file
            os.remove(filepath)
            
            return jsonify({
                'message': 'File uploaded successfully',
                'image_id': image_id
            })
        except Exception as e:
            return jsonify({'error': str(e)}), 500

@app.route('/images')
def list_images():
    """List all images with their metadata."""
    try:
        rows = session.execute('SELECT * FROM images_metadata')
        images = []
        for row in rows:
            images.append({
                'image_id': row.image_id,
                'format': row.format,
                'width': row.width,
                'height': row.height,
                'upload_date': row.upload_date.isoformat(),
                'file_size': row.file_size,
                'hash': row.hash
            })
        return jsonify(images)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/images/<image_id>')
def get_image(image_id):
    """Retrieve an image by ID."""
    try:
        # Get metadata
        row = session.execute(
            'SELECT * FROM images_metadata WHERE image_id = %s',
            [image_id]
        ).one()
        
        if not row:
            return jsonify({'error': 'Image not found'}), 404
        
        # Get image from HDFS
        hdfs_path = f"/user/images/{image_id}.{row.format.lower()}"
        
        # Create temporary file
        with tempfile.NamedTemporaryFile(delete=False) as temp_file:
            hdfs_client.download(hdfs_path, temp_file.name)
            return send_file(
                temp_file.name,
                mimetype=f'image/{row.format.lower()}',
                as_attachment=True,
                download_name=f"{image_id}.{row.format.lower()}"
            )
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/images/<image_id>/metadata')
def get_image_metadata(image_id):
    """Get metadata for a specific image."""
    try:
        row = session.execute(
            'SELECT * FROM images_metadata WHERE image_id = %s',
            [image_id]
        ).one()
        
        if not row:
            return jsonify({'error': 'Image not found'}), 404
        
        return jsonify({
            'image_id': row.image_id,
            'format': row.format,
            'width': row.width,
            'height': row.height,
            'upload_date': row.upload_date.isoformat(),
            'file_size': row.file_size,
            'hash': row.hash
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000) 