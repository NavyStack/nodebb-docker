# nodebb-docker

```bash
set_defaults() {
  export CONFIG_DIR="${CONFIG_DIR:-/opt/config}"
  export CONFIG="$CONFIG_DIR/config.json"
  export NODEBB_INIT_VERB="${NODEBB_INIT_VERB:-install}"
  export START_BUILD="${START_BUILD:-false}"
  export SETUP="${SETUP:-}"
  export PACKAGE_MANAGER="${PACKAGE_MANAGER:-pnpm}"
  export OVERRIDE_UPDATE_LOCK="${OVERRIDE_UPDATE_LOCK:-false}"
}
```

see environment

## Simple Start

```bash
git clone https://github.com/NavyStack/nodebb-docker.git
```

```bash
cd nodebb-docker
```

```bash
mkdir -p ./data/
```

1. `nodebb-mongo-init.js`
2. `setup.json`
3. `docker-compose.yml`

- Make the necessary corrections: DB or domain, etc.
- Docker volume utilised due to permissions issue. ( uid 1001 , pid 1001 )
- This is the result of tweaking all over the place. I don't know why the WebGUI doesn't reflect the values entered and uses the hardcoded `setup.json`.
- So simply modify the `setup.json` to mount it and proceed to the WebUI.
- Similarly, PGsql keeps trying to use hardcoded values in the log even if we set the DB user and PASSWORD correctly......
- Most likely designed without Docker in mind.
- I'd like to PR the original, but I can't afford to.....
- Related files are clustered together in ./data/ for easy movement.

## License

As with all Docker images, this one may also contain other software, subject to additional licenses (such as the Bash shell of the underlying distribution and the indirect dependencies of the included software).

Regarding the use of pre-built images, it is the responsibility of the image user to ensure compliance with the relevant licenses for all software included in the image.

All other trademarks are the property of their respective owners, and unless otherwise specified, we do not claim any affiliation, endorsement, or association with the trademark owners or other companies mentioned in the text.
