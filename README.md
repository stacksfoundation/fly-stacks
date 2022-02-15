# Stacks Blockchain on fly.io

https://fly.io/docs/hands-on/sign-up/

https://fly.io/docs/getting-started/installing-flyctl/

https://fly.io/docs/about/pricing/

## Quickstart

```bash
$ flyctl auth signup
$ flyctl auth login
$ flyctl auth docker
$ export FLY_ACCESS_TOKEN=$(flyctl auth token)
$ export RAND_STRING=$(openssl rand -hex 6)
$ export PSQL_NAME="stacks-postgres-${RAND_STRING}"
$ export APP_NAME="stacks-blockchain-${RAND_STRING}"
$ flyctl postgres create --name=$PSQL_NAME --region=lax  --initial-cluster-size=Development --vm-size=shared-cpu-1x --volume-size=25 --initial-cluster-size=1
$ flyctl launch --no-deploy --dockerfile Dockerfile --copy-config  --region=lax --name=$APP_NAME
$ flyctl scale vm dedicated-cpu-1x -a=$APP_NAME
$ flyctl scale memory 4096
$ flyctl postgres attach --postgres-app $PSQL_NAME
$ flyctl volumes create stacks_blockchain_data --size=50 --region=lax --encrypted=false
$ flyctl deploy --detach
```

This will launch 2 services in fly: a single node postgres instance and a stacks-blockchain (with API) using that DB. \
The name is randomized by `openssl rand -hex 6`, producing a name like `stacks-blockchain-9dbc4006e43e` - using a common name doesn't seem to be supported (i.e. not `stacks-blockchain`) \
The command `flyctl deploy --detach` will deploy the stacks blockchain service _without_ waiting for health checks to return. Remove `--detach` from the command to wait on health checks. \
Finally, to see the logs during the deploy - you can use the web UI, or run `flyctl logs` to monitor the progress.

## Notes

1. It should be trivial to create a standalone docker image here by adding postgres to the Dockerfile and configuring the env var to use that DB vs postgres hosted by https://fly.io
2. Blockchain sync time with the above VM settings will be a bit slower due to the shared single vcpu. For better performance -> [use a higher resource VM](https://fly.io/docs/about/pricing/)
3. When the command ``is run, it adds an env var`DATABASE_URL` to the deployment. [entrypoint.sh](scripts/entrypoint.sh#L37) uses this env var to connect to postgres.
4. The cloned [fly.toml](fly.toml) **will be overwritten** to remove commented lines and replace the app name using the randomized string. [fly.toml.sample](fly.toml.sample) is a copy of this file for reference.
5. The provided domain by fly isn't currently working, but you can access the services using the ip address (i.e. `http://x.x.x.x/v2/info`)
