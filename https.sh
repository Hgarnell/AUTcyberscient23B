#!/bin/bash

# Check if a domain name is provided as an argument
if [ $# -eq 0 ]; then
    echo "Usage: $0 [domain_name]"
    exit 1
fi

# Assign the domain name to a variable
DOMAIN="$1"

# Check if initial conifg is there

config_file="conf.d/default.conf"
if [ -f "$config_file" ]; then
    echo "The configuration file already exists. Appending configuration."
else
    echo "Generating new configuration."
fi


# Function to generate the HTTPS Nginx configuration
generate_https_config() {
    cat <<EOF 
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

new_config=$(generate_https_config)

# Generate the HTTPS configuration
echo "$new_config" | sudo tee -a "$config_file" > /dev/null

# Restart Nginx again to apply HTTPS configuration
docker-compose restart web
