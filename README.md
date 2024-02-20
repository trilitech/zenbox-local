# Zenbox local version for trilitech

## Setup

1. Install Docker Desktop: https://www.docker.com/products/docker-desktop/

1. Open Docker Desktop and compelte the setup

1. Go to Settings -> Docker Engine -> add `"insecure-registries: ["<IP address of the local registry>:5001"]` to the JSON. This is to allow the local registry to be used.

1. Set the required environment variables. You can copy the example file and update the values.

  ```sh
  cp .env.example .env
  ```

  - Get a key from https://platform.openai.com/account/api-keys and set it as OPENAI_API_KEY
  - Set up Google OAuth credentials (https://console.cloud.google.com/apis/credentials) and set the values for GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET


## Building/Running locally

```sh
docker-compose up --build
```

To define how frequently to check for emails (and take actions), update the value of `RUN_EVERY_N_SECONDS` in [entrypoint.py](./backend/entrypoint.py). Default is 30 seconds.

### Logs

You will see INFO level logs for the backend, in the terminal (docker-compose output).

You can run `tail -f backend/debug.log` to check the DEBUG level logs (all logs).

Log level is set in [logger.py](./backend/util/logger.py). You can also set the log level to `INFO` or `ERROR` to see only those logs.

### Viewing stored data

You can install [MongoDB Compass](https://www.mongodb.com/products/tools/compass) to have a GUI access to the DB.

```
Host: localhost:27017
Username: root
Password: example
```

These values are taken from [docker-compose.yml](./docker-compose.yml).


## Someone needs to start a Docker Registry locally

- `docker run -d -p 5001:5000 --restart=always --name registry registry:latest`
-

Refer: https://www.docker.com/blog/how-to-use-your-own-registry-2/