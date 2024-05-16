#!/bin/bash

# Check if a domain name is provided as an argument
if [ $# -eq 0 ]; then
    echo "Usage: $0 [domain_name]"
    exit 1
fi

# Assign the domain name to a variable
DOMAIN="$1"

# Function to generate the config.json configuration
generate_config_json() {
    cat <<EOF > config.json
{
    "admin_server": {
        "listen_url": "0.0.0.0:3333",
        "use_tls": true,
        "cert_path": "/etc/nginx/ssl/live/${DOMAIN}/fullchain.pem",
        "key_path": "/etc/nginx/ssl/live/${DOMAIN}/privkey.pem"
    },
    "phish_server": {
        "listen_url": "0.0.0.0:8080",
        "use_tls": false,
        "cert_path": "/etc/nginx/ssl/live/${DOMAIN}/fullchain.pem",
        "key_path": "/etc/nginx/ssl/live/${DOMAIN}/privkey.pem"
    }
}
EOF
}

# Generate the config.json configuration
generate_config_json

# Notify the user
echo "Configuration for ${DOMAIN} has been written to config.json"
