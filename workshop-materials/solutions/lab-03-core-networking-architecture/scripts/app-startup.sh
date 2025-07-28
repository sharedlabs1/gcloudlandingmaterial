#!/bin/bash
apt-get update
apt-get install -y python3 python3-pip

# Create simple Python app
cat > /opt/app.py << 'PYTHON_APP'
#!/usr/bin/env python3
import json
import socket
from http.server import HTTPServer, BaseHTTPRequestHandler

class AppHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/health':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            response = {"status": "healthy", "hostname": socket.gethostname()}
            self.wfile.write(json.dumps(response).encode())
        else:
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            response = {"message": "TechCorp App Tier", "hostname": socket.gethostname()}
            self.wfile.write(json.dumps(response).encode())

if __name__ == '__main__':
    server = HTTPServer(('0.0.0.0', 8080), AppHandler)
    server.serve_forever()
PYTHON_APP

# Start the application
python3 /opt/app.py &
