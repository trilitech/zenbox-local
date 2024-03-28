#!/bin/bash

# Exit the script on any error
set -e

# Check if Homebrew is installed, if not, install it
check_and_install_homebrew() {
    if ! command -v brew &> /dev/null; then
        echo "Homebrew is not installed, installing now..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
}

# Check if openssl is installed, if not, install using brew
check_and_install_openssl() {
    if ! command -v openssl &> /dev/null; then
        echo "openssl not found, checking for Homebrew..."
        check_and_install_homebrew
        echo "Installing openssl using Homebrew..."
        brew install openssl
    fi
}

# Check if docker compose is installed, if not, install using brew
check_and_install_docker_compose() {
    if ! command -v docker-compose &> /dev/null; then
        echo "docker-compose not found, checking for Homebrew..."
        check_and_install_homebrew
        echo "Installing docker-compose using Homebrew..."
        brew install docker-compose
    fi
}

# Validate AES_256_KEY and NEXTAUTH_SECRET formats
validate_keys() {
    # Validate base64 string format
    validate_base64_format() {
        local value=$1
        # Allow for base64 characters, including +, /, and = for padding.
        local regex="^[A-Za-z0-9+/]+={0,2}$"
        if ! [[ $value =~ $regex ]]; then
            echo "The value does not match the expected base64 format."
            exit 1
        fi
    }

    aes_256_key=$(grep "AES_256_KEY" .env | cut -d'"' -f2)
    validate_base64_format "$aes_256_key"

    nextauth_secret=$(grep "NEXTAUTH_SECRET" .env | cut -d'"' -f2)
    validate_base64_format "$nextauth_secret"

    echo ".env values for AES_256_KEY and NEXTAUTH_SECRET are correctly formatted."
}

# Generate SSL certificates if they do not exist
check_and_generate_ssl_certificates() {
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

build_from_source=true

# Check if running on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    echo "This script is intended to run on macOS only."
    exit 1
fi

# Check if .env file exists, if not, create and populate it
if [ ! -f ".env" ]; then
    touch .env

    if [ "$build_from_source" = "false" ]; then
        read -p "Enter the Docker Registry address along with port number: " docker_registry
        echo "DOCKER_REGISTRY=\"$docker_registry\"" >> .env
    fi

    # Call function to check and install OpenSSL if necessary
    check_and_install_openssl

    # Ask for the MODE of operation and set relevant environment variables accordingly
    read -p "Enter the NEXT_PUBLIC_MODE (local or deployment): " mode
    echo "NEXT_PUBLIC_MODE=\"$mode\"" >> .env
    if [ "$mode" == "local" ]; then
        # Set GMAIL_OAUTH_ENABLED to false by default
        echo "GMAIL_OAUTH_ENABLED=false" >> .env
        echo "NEXT_PUBLIC_RECAPTCHA_SITE_KEY=\"\"" >> .env

        echo "SSL_KEY_PATH=./localhost.key" >> .env
        echo "SSL_CERT_PATH=./localhost.crt" >> .env

        echo "NEXTAUTH_URL=\"https://localhost\"" >> .env

    elif [ "$mode" == "deployment" ]; then
        read -p "Enter Google Analytics Measurement ID: " ga_measurement_id
        echo "GA_MEASUREMENT_ID=$ga_measurement_id" >> .env

        read -p "Enter Google Tag Manager ID: " ga_tag_manager_id
        echo "GA_TAG_MANAGER_ID=$ga_tag_manager_id" >> .env

        # Google OAuth
        echo "GMAIL_OAUTH_ENABLED=true" >> .env
        read -p "Enter Google Client ID: " google_client_id
        echo "GOOGLE_CLIENT_ID=$google_client_id" >> .env
        read -p "Enter Google Client Secret: " google_client_secret
        echo "GOOGLE_CLIENT_SECRET=$google_client_secret" >> .env

        # reCAPTCHA
        echo >> .env
        echo "# reCAPTCHA" >> .env
        read -p "NEXT_PUBLIC_RECAPTCHA_SITE_KEY: " recaptcha_site_key
        echo "NEXT_PUBLIC_RECAPTCHA_SITE_KEY=\"$recaptcha_site_key\"" >> .env
        read -p "RECAPTCHA_SECRET_KEY: " recaptcha_secret_key
        echo "RECAPTCHA_SECRET_KEY=\"$recaptcha_secret_key\"" >> .env
        read -p "RECAPTCHA_VERIFY_URL: " recaptcha_verify_url
        echo "RECAPTCHA_VERIFY_URL=\"$recaptcha_verify_url\"" >> .env
        echo >> .env

        echo "SSL_KEY_PATH=/etc/letsencrypt/live/zenbox.daksh.uno/privkey.pem" >> .env
        echo "SSL_CERT_PATH=/etc/letsencrypt/live/zenbox.daksh.uno/fullchain.pem" >> .env

        echo "NEXTAUTH_URL=\"https://zenbox.daksh.uno\"" >> .env
    else
        echo "You have entered an unsupported mode."
    fi

    # "local" or "chat_gpt"
    echo >> .env
    echo "# \"local\" or \"chat_gpt\". If it is chat_gpt, also define OPENAI_API_KEY" >> .env
    read -p "Enter the LLM_CHOICE (local or chat_gpt): " llm_choice
    echo "LLM_CHOICE=\"$llm_choice\"" >> .env
    if [ "$llm_choice" == "chat_gpt" ]; then
        read -p "Enter OpenAI API Key: " openai_api_key
        echo "OPENAI_API_KEY=\"$openai_api_key\"" >> .env
    fi

    # MongoDB
    echo >> .env
    echo "# MongoDB" >> .env
    echo "MONGODB_USERNAME=\"zenbox_mongo_user\"" >> .env
    # Generate a random MongoDB password
    mongodb_password=$(openssl rand -base64 32 | tr -d /=+ | cut -c1-20)
    echo "MONGODB_PASSWORD=\"$mongodb_password\"" >> .env
    echo "MONGODB_ADDRESS=mongo" >> .env
    echo "MONGODB_PORT=27017" >> .env
    echo "MONGODB_URI=\"mongodb://\${MONGODB_USERNAME}:\${MONGODB_PASSWORD}@\${MONGODB_ADDRESS}:\${MONGODB_PORT}\"" >> .env
    echo "MONGODB_DATABASE_NAME=\"zenbox\"" >> .env
    echo >> .env

    echo "BACKEND_API_URL=\"http://api:8000\"" >> .env

    echo "LOGIN_SUCCESS_REDIRECT_URL=\${NEXTAUTH_URL}/setup/google" >> .env

    echo >> .env

    # Generate AES_256_KEY and NEXTAUTH_SECRET
    echo "# Unique base64-encoded key(s) generated using \`openssl rand -base64 32\`" >> .env
    aes_256_key=$(openssl rand -base64 32)
    echo "AES_256_KEY=\"$aes_256_key\"" >> .env
    nextauth_secret=$(openssl rand -base64 32)
    echo "NEXTAUTH_SECRET=\"$nextauth_secret\"" >> .env

    echo "Environment setup complete."
fi

# Validate AES_256_KEY and NEXTAUTH_SECRET formats
validate_keys

check_and_generate_ssl_certificates

check_and_install_docker_compose

echo "Stopping and removing current containers"
docker-compose down

echo "Pulling latest images from Docker Registry"
docker-compose pull || echo "Failed to pull some images. Using local images if available."

echo "Running docker-compose up"
docker-compose up -d

echo "Redirecting docker-compose logs to docker_compose.log"
docker-compose logs > docker_compose.log 2>&1

echo >> .env
echo "To stop Zenbox, run 'docker-compose down' in the project directory."
echo "Open https://localhost in your browser to access Zenbox anytime while its running."

open https://localhost
