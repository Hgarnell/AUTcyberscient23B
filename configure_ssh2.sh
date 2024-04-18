
#Run docker
Docker-compose up -d

# Restart Nginx with Docker Compose
docker-compose restart web

# Generate the HTTPS configuration
generate_https_config

# Restart Nginx again to apply HTTPS configuration
docker-compose restart web
