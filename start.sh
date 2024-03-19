#!/bin/bash

# Ensure the script exits on any error
set -e

# Check if running on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    echo "This script is intended to run on macOS only."
    exit 1
fi

# Function to check and install openssl if necessary
check_and_install_openssl() {
    # Check if openssl is available
    if ! command -v openssl &> /dev/null; then
        echo "openssl could not be found, checking for Homebrew..."

        # Check if Homebrew is installed
        if ! command -v brew &> /dev/null; then
            echo "Homebrew is not installed, installing now..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi

        echo "Installing openssl using Homebrew..."
        brew install openssl
    fi
}

# Function to validate base64 string format
validate_base64_format() {
    local value=$1
    # Allow for base64 characters, including +, /, and = for padding.
    local regex="^[A-Za-z0-9+/]+={0,2}$"
    if ! [[ $value =~ $regex ]]; then
        echo "The value does not match the expected base64 format."
        exit 1
    fi
}

# Validate AES_256_KEY and NEXTAUTH_SECRET formats
validate_keys() {
    aes_256_key=$(grep "AES_256_KEY" .env | cut -d'"' -f2)
    validate_base64_format "$aes_256_key"

    nextauth_secret=$(grep "NEXTAUTH_SECRET" .env | cut -d'"' -f2)
    validate_base64_format "$nextauth_secret"

    echo ".env values for AES_256_KEY and NEXTAUTH_SECRET are correctly formatted."
}

generate_ssl_certificates() {
    # Check if SSL certificates exist, if not, generate them
    if [ ! -f "localhost.crt" ] || [ ! -f "localhost.key" ]; then
        echo "SSL certificates not found, generating..."

        # Command from https://letsencrypt.org/docs/certificates-for-localhost/
        openssl req -x509 -out localhost.crt -keyout localhost.key \
        -newkey rsa:2048 -nodes -sha256 \
        -subj '/CN=localhost' -extensions EXT -config <( \
        printf "[dn]\nCN=localhost\n[req]\ndistinguished_name = dn\n[EXT]\nsubjectAltName=DNS:localhost\nkeyUsage=digitalSignature\nextendedKeyUsage=serverAuth")
        echo "SSL certificates generated."
    fi
}

# Check if .env file exists, if not, create and populate it
if [ ! -f ".env" ]; then
    touch .env
    echo "MODE=\"local\"" >> .env

    read -p "Enter the Docker Registry address along with port number: " docker_registry
    echo "DOCKER_REGISTRY=\"$docker_registry\"" >> .env

    check_and_install_openssl

    aes_256_key=$(openssl rand -base64 32)
    echo "AES_256_KEY=\"$aes_256_key\"" >> .env

    nextauth_secret=$(openssl rand -base64 32)
    echo "NEXTAUTH_SECRET=\"$nextauth_secret\"" >> .env

    echo "MONGODB_USERNAME=\"zenbox_mongo_user\"" >> .env
    mongodb_password=$(openssl rand -base64 32 | tr -d /=+ | cut -c1-20)
    echo "MONGODB_PASSWORD=\"$mongodb_password\"" >> .env
    echo "MONGODB_ADDRESS=mongo" >> .env
    echo "MONGODB_PORT=27017" >> .env
    echo "MONGODB_URI=\"mongodb://\${MONGODB_USERNAME}:\${MONGODB_PASSWORD}@\${MONGODB_ADDRESS}:\${MONGODB_PORT}\"" >> .env
    echo "MONGODB_DATABASE_NAME=\"zenbox\"" >> .env


    echo "LLM_CHOICE=\"local\"" >> .env
    echo "GMAIL_OAUTH_ENABLED=false" >> .env
    echo "NEXTAUTH_URL=\"https://localhost\"" >> .env
    echo "BACKEND_API_URL=\"http://api:8000\"" >> .env

    echo "SSL_KEY_PATH=./localhost.key" >> .env
    echo "SSL_CERT_PATH=./localhost.crt" >> .env

    echo "Environment setup complete."
fi

# Validate AES_256_KEY and NEXTAUTH_SECRET formats
validate_keys

generate_ssl_certificates

echo "Stopping and removing current containers"
docker-compose down

echo "Pulling latest images from Docker Registry"
docker-compose pull || echo "Failed to pull some images. Using local images if available."

echo "Running docker-compose up"
docker-compose up -d

echo "Redirecting docker-compose logs to docker_compose.log"
docker-compose logs > docker_compose.log 2>&1

open https://localhost
