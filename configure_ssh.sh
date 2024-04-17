#!/bin/bash

# Check if a domain name is provided as an argument
if [ $# -eq 0 ]; then
    echo "Usage: $0 [domain_name]"
    exit 1
fi

# Assign the domain name to a variable
DOMAIN="$1"

# Function to generate the HTTP Nginx configuration
generate_http_config() {
    cat <<EOF > /root/AUTcyberscient23B/conf.d/default.conf
    server {
        listen 80;
        server_name ${DOMAIN};
        root /public_html/;

        location ~ /.well-known/acme-challenge {
            allow all;
            root /usr/share/nginx/html/letsencrypt;
        }

        location / {
            return 301 https://${DOMAIN}\$request_uri;
        }
    }
EOF
}

# Function to generate the HTTPS Nginx configuration
generate_https_config() {
    cat <<EOF > /root/AUTcyberscient23B/conf.d/default.conf
    server {
        listen 443 ssl http2;
        server_name ${DOMAIN};
        root /public_html/;

        ssl on;
        server_tokens off;
        ssl_certificate /etc/nginx/ssl/live/${DOMAIN}/fullchain.pem;
        ssl_certificate_key /etc/nginx/ssl/live/${DOMAIN}/privkey.pem;
        ssl_dhparam /etc/nginx/dhparam/dhparam-2048.pem;
        
        ssl_buffer_size 8k;
        ssl_protocols TLSv1.2 TLSv1.1 TLSv1;
        ssl_prefer_server_ciphers on;
        ssl_ciphers ECDH+AESGCM:ECDH+AES256:ECDH+AES128:DH+3DES:!ADH:!AECDH:!MD5;

        location / {
            index index.html;
        }
    }
EOF
}

# Generate the HTTP configuration
generate_http_config

#Run docker
Docker-compose up -d

# Restart Nginx with Docker Compose
docker-compose restart web

# Generate the HTTPS configuration
generate_https_config

# Restart Nginx again to apply HTTPS configuration
docker-compose restart web
