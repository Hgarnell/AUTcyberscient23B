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
    cat <<EOF > conf.d/default.conf
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

# Generate the HTTP configuration
generate_http_config

#Run docker
docker-compose up 

# Restart Nginx with Docker Compose
docker-compose restart web
