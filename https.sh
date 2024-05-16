#!/bin/bash

# Check if a domain name is provided as an argument
if [ $# -eq 0 ]; then
    echo "Usage: $0 [domain_name]"
    exit 1
fi

# Assign the domain name to a variable
DOMAIN_NAME="$1"

# Function to generate the HTTP Nginx configuration
generate_https_config() {
    cat <<EOF  conf.d/default.conf


server {
    listen 443 ssl;
    server_name $DOMAIN_NAME;
    
    # SSL certificate settings
    ssl_certificate /etc/nginx/ssl/live/$DOMAIN_NAME/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/live/$DOMAIN_NAME/privkey.pem;
    ssl_dhparam /etc/nginx/dhparam/dhparam-2048.pem;

    # Proxy pass settings
    location / {
        proxy_pass http://autcyberscient23b_gophish_1:80;  # HTTP connection to Gophish
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF
}

# Generate the HTTPs configuration
generate_https_config

# Notify the user
echo "Nginx configuration for ${DOMAIN} has been written to conf.d/default.conf"
