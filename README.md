# Zenbox local version for trilitech

## Setup

1. Install Docker Desktop: https://www.docker.com/products/docker-desktop/

1. Open Docker Desktop and compelte the setup

1. Go to Settings -> Docker Engine -> add `"insecure-registries": ["<IP address of the local registry>:5001"]` to the JSON. This is to allow the local registry to be used.

1. Run start script

```sh
# Make the script executable
chmod +x start.sh

# Run the script
./start.sh
```

### Viewing stored data

You can install [MongoDB Compass](https://www.mongodb.com/products/tools/compass) to have a GUI access to the DB. You can find the credentials in `.env` file. We map the port `27017` to the host machine, so when you open MongoDB Compass, you can use `mongodb://zenbox_mongo_user:password_here@localhost:27017/` as the URI.


## Someone needs to start a Docker Registry locally

- Start the registry: `docker run -d -p 5001:5000 --restart=always --name registry registry:latest` (refer https://www.docker.com/blog/how-to-use-your-own-registry-2/)
- Tag images and push them to the local registry

  ```sh
  docker tag zenbox-backend localhost:5001/zenbox-backend
  docker tag zenbox-nextjs-app localhost:5001/zenbox-nextjs-app
  docker tag zenbox-api localhost:5001/zenbox-backend-api
  ```

  ```sh
  docker push localhost:5001/zenbox-backend
  docker push localhost:5001/zenbox-nextjs-app
  docker push localhost:5001/zenbox-backend-api
  ```
