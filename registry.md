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
