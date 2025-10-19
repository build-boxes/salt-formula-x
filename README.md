# Salt-Formula-X
A template for salt formula, with serverspec testing in local Vagrant managed docker container.

## Build Podman Image
```
podman build . -t hammadrauf/saltx
```

## Launching the Container (Locally)
```
podman run -d --systemd=true  --name saltx01 --hostname saltx01 -it hammadrauf/saltx
podman run -d --name saltx01 --hostname saltx01 -it hammadrauf/saltx
```

## Launching the Container (From Quay.io)
```
podman run -d --name saltx01 --hostname saltx01 -it quay.io/hammadrauf/saltx
```

## Launching the Container - with SSH Key
```
podman run -d --name saltx01 --hostname saltx01 -e SSH_PUB_KEY="$(cat ~/.ssh/id_rsa_salt.pub)" -it quay.io/hammadrauf/saltx
```

## Launching the Container - with Volume and Port mapping
```
podman run -d --name saltx01 --hostname saltx01 -v $(pwd)/x:/srv/salt -it quay.io/hammadrauf/saltx
podman run -d --name saltx01 --hostname saltx01 -v $(pwd)/x:/srv/salt -p 8080:80 -p 2232:22 -it quay.io/hammadrauf/saltx
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

## Pairing the Minion with Local Salt Master

To configure the container to act as both a Salt master and its own minion, the image sets up the minion to point to `localhost` and assigns it a static ID (`local-master`). This is done automatically during build of the Dockerfile, and requires no action on part of the user of the Container.  
The Salt master is configured to auto-accept minion keys.  
Once inside the container shell, you can manually trigger the pairing and apply the highstate using the bootstrap script:  
```
$ /opt/salt/bootstrap_minion.sh
OR
$ bootstrap_minion.sh
```
This script starts both services Master and Minion, waits briefly, and runs the following:
```
salt-call test.ping
salt-call state.apply
```
This confirms the minion is connected and applies the configured states from /srv/salt. The container is now fully self-contained for Salt testing and orchestration.

## How To Run Serverspec Tests Manually
1. Place your formula Tests inside the "test" folder:
    ```
    x
    ├── formula
    │   ├── ntp
    │   │   ├── init.sls
    │   │   └── test
    │   │       └── ntp_spec.rb
    │   └── timezone
    │       ├── init.sls
    │       └── test
    │           └── timezone_spec.rb
    ├── pillar
    │   ├── ntp.sls
    │   ├── timezone.sls
    │   └── top.sls
    └── top.sls
    ```
1. All serverspec files should:
    - named like "*_spec.rb"
    - contain a first line of:
        ```
        require '/opt/serverspec/spec_helper'
        ```
1. You should login to the Container (either via SSH or podman exec).
    ```
    cd /srv/salt/formula
    rspec timezone/test/timezone_spec.rb
    rspec ntp/test/ntp_spec.rb
    ```
1. To run all tests, run the following from any folder:
    ```
    $ /opt/serverspec/run_all_tests.sh
    OR
    $ run_all_tests.sh
    ```
