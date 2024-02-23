#!/bin/bash

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

# Check if .env file exists, if not, copy from .env.example
if [ ! -f ".env" ]; then
    cp .env.example .env
    echo ".env file created from .env.example."

    # Ask for Docker Registry address and update .env
    read -p "Enter the Docker Registry address: " docker_registry
    sed -i '' "s|DOCKER_REGISTRY=.*|DOCKER_REGISTRY=\"$docker_registry\"|g" .env

    # Call function to check and install OpenSSL if necessary
    check_and_install_openssl

    # Generate AES_256_KEY and set in .env
    aes_256_key=$(openssl rand -base64 32)
    sed -i '' "s|AES_256_KEY=.*|AES_256_KEY=\"$aes_256_key\"|g" .env

    # Generate NEXTAUTH_SECRET and set in .env
    nextauth_secret=$(openssl rand -base64 32)
    sed -i '' "s|NEXTAUTH_SECRET=.*|NEXTAUTH_SECRET=\"$nextauth_secret\"|g" .env

    # Generate a random MongoDB password
    mongodb_password=$(openssl rand -base64 32 | tr -d /=+ | cut -c1-20)
    sed -i '' "s|MONGODB_PASSWORD=.*|MONGODB_PASSWORD=\"$mongodb_password\"|g" .env

    echo "Environment setup complete."
fi

# Check if SSL certificates exist, if not, generate them
if [ ! -f "localhost.crt" ] || [ ! -f "localhost.key" ]; then
    echo "SSL certificates not found, generating..."

    # Call function to check and install OpenSSL if necessary
    check_and_install_openssl

    # Command from https://letsencrypt.org/docs/certificates-for-localhost/
    openssl req -x509 -out localhost.crt -keyout localhost.key \
      -newkey rsa:2048 -nodes -sha256 \
      -subj '/CN=localhost' -extensions EXT -config <( \
       printf "[dn]\nCN=localhost\n[req]\ndistinguished_name = dn\n[EXT]\nsubjectAltName=DNS:localhost\nkeyUsage=digitalSignature\nextendedKeyUsage=serverAuth")
    echo "SSL certificates generated."
fi

echo "Stopping and removing current containers"
docker-compose down

echo "Pulling latest images from Docker Registry"
docker-compose pull || echo "Failed to pull some images. Using local images if available."

echo "Running docker-compose up"
docker-compose up -d

echo "Redirecting docker-compose logs to docker_compose.log"
docker-compose logs > docker_compose.log 2>&1
