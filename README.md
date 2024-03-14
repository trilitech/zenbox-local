# Zenbox local version for trilitech

## Setup

1. Install Docker Desktop: https://www.docker.com/products/docker-desktop/

1. Open Docker Desktop and complete the setup

1. Go to Settings -> Docker Engine -> add `"insecure-registries": ["<IP address of the local registry>:5001"]` to the JSON. This is to allow the local registry to be used.

1. Clone this repository and cd into it

1. Run start script

    ```sh
    # Make the script executable
    chmod +x start.sh
    
    # Run the script
    ./start.sh
    ```

1. Now you can access Zenbox at https://localhost. Please ignore the certificate warning and proceed to the website. <br/><br/>
<b>Further Details</b>: When visiting a website, your browser expects a security certificate that has been verified by a trusted authority. This helps ensure the site is secure. However, because we're setting up the website to run directly on your computer, we use a local process to generate these certificates. These aren't recognized by standard authorities, which is why you're seeing the warning. To learn more about how these certificates are created, you can refer to the start-up script. <br/>
Despite this, your data remains secure. It never leaves your computer. We use HTTPS encryption, which means even if someone could listen in on the data being sent to and from your computer (via loopback traffic), they would only see encrypted information, keeping your data safe.


### (Optional) Viewing stored data

You can install [MongoDB Compass](https://www.mongodb.com/products/tools/compass) to have a GUI access to the DB. You can find the credentials in `.env` file. We map the port `27017` to the host machine, so when you open MongoDB Compass, you can use `mongodb://zenbox_mongo_user:password_here@localhost:27017/` as the URI.
