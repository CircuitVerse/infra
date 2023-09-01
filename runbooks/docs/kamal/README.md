# Kamal

[CircuitVerse](github.com/CircuitVerse/CircuitVerse) uses docker containers for production deployment which are orchestrated 
using [kamal](https://github.com/basecamp/kamal). 

Kamal uses the dynamic reverse-proxy Traefik to hold requests, while the new app container is started and the old one is 
stopped — working seamlessly across multiple hosts, using SSHKit to execute commands.


## Configuration 

Kamal Configuration

- [config/deploy.yml](https://github.com/CircuitVerse/CircuitVerse/blob/master/config/deploy.yml)

GitHub Action Workflow

- [.github/workflows/deploy.yml](https://github.com/CircuitVerse/CircuitVerse/blob/master/.github/workflows/deploy.yml)

## Commands

- [Kamal-docs](https://kamal-deploy.org/docs/commands)


```bash
kamal details 
```

Running data migrations

This will spin up a new container and then run `bin/rails data:migrate` inside it.
```bash
kamal app exec 'bin/rails data:migrate'
```

Reverting to a previous deployment

```bash
kamal rollback <git-commit-hash>
```
#### Traefik and Accessories

**Traefik**

```bash
kamal traefik boot

# reboot traefik after making any changes to its configuration
kamal traefik reboot
```

[**yosys2digitaljs-server**](https://github.com/CircuitVerse/yosys2digitaljs-server)

```bash
kamal accessory boot yosys2digitaljs-server 
```

#### Locks

```bash
# place a lock on deployment
kamal lock acquire -m "Running data migrations"
# release lock
kamal lock release
```

#### Deploy

```bash
# checks on all servers if curl and docker are present, then starts building the docker image.
kamal deploy

# skips intial tests and starts building the docker image.
kamal redeploy

# Skips building the docker image, directly pulls it from the registry
kamal redeploy -v --skip_push
```
