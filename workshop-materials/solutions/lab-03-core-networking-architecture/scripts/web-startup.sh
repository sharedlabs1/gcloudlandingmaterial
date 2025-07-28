#!/bin/bash
apt-get update
apt-get install -y nginx

# Configure nginx
cat > /etc/nginx/sites-available/default << 'NGINX_CONFIG'
server {
    listen 80 default_server;
    root /var/www/html;
    index index.html;
    
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
    
    location / {
        try_files $uri $uri/ =404;
    }
}
NGINX_CONFIG

# Create simple web page
cat > /var/www/html/index.html << 'HTML_END'
<!DOCTYPE html>
<html>
<head><title>TechCorp Web Tier</title></head>
<body>
    <h1>TechCorp Web Application</h1>
    <p>Server: $(hostname)</p>
    <p>Zone: $(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/zone | cut -d/ -f4)</p>
</body>
</html>
HTML_END

systemctl restart nginx
systemctl enable nginx
