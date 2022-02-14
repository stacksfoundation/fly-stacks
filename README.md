# Stacks Blockchain on fly.io

https://fly.io/docs/hands-on/sign-up/
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
