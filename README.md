# Salt-Formula-X
A template for salt formula, with serverspec testing in local Vagrant managed docker container.

## Build Podman Image
```
podman build . -t saltx
```

## Launching the Container
```
podman run -d --systemd=true  --name saltx01 --hostname saltx01 -it localhost/saltx
podman run -d --name saltx01 --hostname saltx01 -it localhost/saltx
```

## Launching the Container - with SSH Key
```
podman run -d --name saltx01 --hostname saltx01 -e SSH_PUB_KEY="$(cat ~/.ssh/id_rsa_salt.pub)" -it localhost/saltx
```

## Launching the Container - with Volume and Port mapping
```
podman run -d --name saltx01 --hostname saltx01 -v $(pwd)/x:/srv/salt/formula -it localhost/saltx
podman run -d --name saltx01 --hostname saltx01 -v $(pwd)/x:/srv/salt/formula -p 8080:80 -p 2232:22 -it localhost/saltx
```

## Connect to Running Container - via Podman Exec
```
podman exec -it saltx01 /bin/bash
```

## Connect to Running Container - via SSH
- Default root password (if SSH_PUB_KEY is not used) = podman!
```
ssh-keygen -R localhost
OR
mv ~/.ssh/known_hosts ~/.ssh/known_hosts.old 
ssh root@localhost -p 2232
```

## Stop and Destroy the Container
```
podman stop saltx01
OR
podman container stop saltx01

podman rm saltx01
OR
podman container rm saltx01
```

## List and Delete Unwanted Images
```
podman image ls

podman image rm <Image-ID01> [<Image-ID02>/<ImageName-02> ...}
```

## Manually Upload Image to Repositories
You should have an account with DockerHub.io or Quay.io to push built images.
```
podman push ....
```