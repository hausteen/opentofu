# Opentofu

Opentofu automation for my home lab

## Running on Windows vs Linux

Linux will be much easier to work with. Windows will be more troublesome due to the bind mounts and file permissions that are used for the secrets and writeback folder.

## Why containers?

I want to keep clean separate environments.

## opentofuWriteback folder

- This repository will `NOT` let you keep anything in the `opentofuWriteback` folder permanently. It `WILL` delete everything in that folder when the container is started. The folder is meant to allow you to save the data that opentofu creates/ obtains. It should be kept clean and tidy.

## A note about secrets

- This repo uses Docker Compose secrets. You'll have to edit the Docker Compose file to add the secrets your secrets as needed. More info found here -> https://docs.docker.com/compose/how-tos/use-secrets/
- You can use the `opentofuSecrets` folder to store those secrets if you don't have any sort of secret manager tool. This folder is not tracked in version control.

## To run the opentofu Docker container

1. Make sure that Docker and Docker Compose are installed
2. Clone this repository down from Github
3. In this repository's base folder, run:
    - `docker compose up`
4. In another terminal window, connect to the opentofu Docker container:
    - `docker exec -it opentofu /bin/sh`
