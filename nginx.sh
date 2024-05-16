#!/bin/bash

# Check if a domain name is provided as an argument
if [ $# -eq 0 ]; then
    echo "Usage: $0 [domain_name]"
    exit 1
fi

# Assign the domain name to a variable
DOMAIN="$1"

# Function to generate the HTTP Nginx configuration
generate_nginx_config() {
    cat <<EOF > /root/AUTcyberscient23B/conf.d/default.conf
server {
    listen 80;
    server_name kiwibytesolution555.info;
    # Redirect all HTTP requests to HTTPS
    location / {
        return 301 https://$host$request_uri;
    }
}

server {
    listen 443 ssl;
    server_name kiwibytesolution555.info;
    
    # SSL certificate settings
    ssl_certificate /etc/nginx/ssl/live/kiwibytesolution555.info/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/live/kiwibytesolution555.info/privkey.pem;
    ssl_dhparam /etc/nginx/dhparam/dhparam-2048.pem;

    # Proxy pass settings
    location / {
        proxy_pass http://autcyberscient23b_gophish_1:80;  # HTTP connection to Gophish
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
EOF
}

# Generate the HTTP configuration
generate_nginx_config
