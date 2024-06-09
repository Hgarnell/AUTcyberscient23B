#!/bin/bash

# Check if a domain name is provided as an argument
if [ $# -eq 0 ]; then
    echo "Usage: $0 [domain_name]"
    exit 1
fi

# Assign the domain name to a variable
DOMAIN_NAME="$1"

# Function to generate the HTTP Nginx configuration
generate_nginx_config() {
    cat <<EOF > conf.d/default.conf
server {
    listen 80;
    server_name ${DOMAIN_NAME};
    root /public_html/;

    location ~ /.well-known/acme-challenge {
        allow all;
        root /usr/share/nginx/html/letsencrypt;
    }

    # Redirect all HTTP requests to HTTPS
    location / {
        return 301 https://\$host\$request_uri;
    }
}
EOF
}

# Generate the HTTP configuration
generate_nginx_config

# Notify the user
echo "Nginx configuration for ${DOMAIN_NAME} has been written to conf.d/default.conf"
