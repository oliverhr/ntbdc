# Nautobot - Jobs and Plugins Development Environment

Based on [Nautobot Docker Compose](https://github.com/nautobot/nautobot-docker-compose) project, so most of the docs and files are taken from there.

**Read First:**

- https://docs.nautobot.com/projects/core/en/stable/user-guide/administration/guides/docker

#### Changes

The main differences are:

- Renamed the invoke namespace context/configuration from
  - From `nautobot_docker_compose`
  - To `networktocode`
- Nested some properties used as environment variables for Docker-Compose and Dockerfile
  - `namespace.configuration().networktocode.env`
  - All the properties on `networktocode.env` dictionary must be all caps

## Requirements

- Docker
  - Compose
  - Buildx
- Bash +=4.x

## Configuration

Environment files (.env) are the standard way of providing configuration information or secrets in Docker containers. This project includes two example environment files that each serve a specific purpose:

* `settings.env` - The local environment file is intended to store all relevant configurations that are safe to be stored in git. This would typically be things like specifying the database user or whether debug is enabled or not. Do not store secrets, ie passwords or tokens, in this file!

* `crendentials.env` - The creds environment file is intended to store all configuration information that you wish to keep out of git. The `creds.env` file is in `.gitignore` and thus will not be pushed to git by default. This is essential to keep passwords and tokens from being leaked accidentally.

```bash
cp docker/settings.env docker/settings.dist.env
cp docker/crendentials.dist.env docker/crendentials.dist.env

# Make this files available for the current user only.
chmod 0600 docker/crendentials.dist.env
```

###  Environment Variables

```
...
```



## CLI Helper Commands

Each command can be executed with a simple `compose.sh <command>`.

#### Manage Nautobot environment

```bash
  build            Build all docker images.
  debug            Start Nautobot and its dependencies in debug mode.
  destroy          Destroy all containers and volumes.
  start            Start Nautobot and its dependencies in detached mode.
  stop             Stop Nautobot and its dependencies.
  db-export        Export Database data to nautobot_backup.dump.
  db-import        Import test data.
```

#### Utility

```bash
  cli              Launch a shell inside the Nautobot container.
  migrate          Run database migrations in Django.
  nbshell          Launch a nbshell session.
  shellplus        Launch a nbshell shellplus session.
```
Nuatobot shell [docs](https://docs.nautobot.com/projects/core/en/stable/user-guide/administration/tools/nautobot-shell/)

## Getting Started

```bash
# By Default uses cache when building the image
./compose.sh build

# To not use cache when building the image
./compose.sh build --no-cache
```

To start the environment:

```bash
./compose.sh start
```

### Create a Super User Account

**Via Environment**

The Docker container has a Docker entry point script that allows you to create a super user by the usage of Environment variables. This can be done by updating the `creds.env` file environment option of `NAUTOBOT_CREATE_SUPERUSER` to `True`. This will then use the information supplied to create the specified superuser.

**Via Container**

After the containers have started:

1. Verify the containers are running:

```bash
docker container ls
```

2. Execute Create Super User Command and follow the prompts

```bash
./compose.sh createsuperuser
```

Example Prompts:

```bash
nautobot@bb29124d7acb:~$ invoke createsuperuser
Username: administrator
Email address:
Password:
Password (again):
Superuser created successfully.
```

## Additional Documentation

### LDAP

...

### Plugins

...


## References

- Docker Hub Network to Code profile
  - https://hub.docker.com/r/networktocode
- Nautobot docker images on docker hub
  - https://hub.docker.com/r/networktocode/nautobot
  - https://hub.docker.com/r/networktocode/nautobot-dev
- Nautobot Development guide:
  - https://docs.nautobot.com/projects/core/en/stable/development/core/getting-started/
