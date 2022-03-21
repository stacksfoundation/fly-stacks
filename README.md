# Stacks Blockchain on fly.io

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Pull Requests Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat)](http://makeapullrequest.com)

https://fly.io/docs/hands-on/sign-up/

https://fly.io/docs/getting-started/installing-flyctl/

https://fly.io/docs/about/pricing/

## Quickstart

The following comamnds are meant as examples only - **the minimum viable settings are used to launch the service**.

```bash
$ flyctl auth signup
$ flyctl auth login
$ flyctl auth docker
$ export FLY_ACCESS_TOKEN=$(flyctl auth token)
$ export RAND_STRING=$(openssl rand -hex 6)
$ export PSQL_NAME="stacks-postgres-${RAND_STRING}"
$ export APP_NAME="stacks-blockchain-${RAND_STRING}"
$ flyctl postgres create --name=$PSQL_NAME --region=lax  --initial-cluster-size=Development --vm-size=dedicated-cpu-1x --volume-size=10 --initial-cluster-size=1
$ flyctl launch --no-deploy --dockerfile Dockerfile --copy-config  --region=lax --name=$APP_NAME
$ flyctl scale vm dedicated-cpu-1x -a=$APP_NAME
$ flyctl scale memory 4096
$ flyctl postgres attach --postgres-app $PSQL_NAME
$ flyctl volumes create stacks_blockchain_data --size=50 --region=lax --no-encryption
$ flyctl deploy --detach
```

- This will launch 2 services in fly: a single node postgres instance and a stacks-blockchain (with API) using that DB.
- The name is randomized by `openssl rand -hex 6`, producing a name like `stacks-blockchain-9dbc4006e43e` - using a common name doesn't seem to be supported (i.e. not `stacks-blockchain`)
- The command `flyctl deploy --detach` will deploy the stacks blockchain service _without_ waiting for health checks to return. Remove `--detach` from the command to wait on health checks.
- Finally, to see the logs during the deploy - you can use the web UI, or run `flyctl logs` to monitor the progress.

## Notes

1. It should be trivial to create a standalone docker image here by adding postgres to the Dockerfile and configuring the env var to use that DB vs postgres hosted by https://fly.io
2. Blockchain sync time with the above VM settings will be a bit slower due to the shared single vcpu. For better performance -> [use a higher resource VM](https://fly.io/docs/about/pricing/)
   1. Pricing for a 4GB instance for 1 month is about $30 with a managed DB
3. When the command `flyctl postgres create` is run, it adds an env var `DATABASE_URL` to the deployment. [entrypoint.sh](scripts/entrypoint.sh#L37) uses this env var to connect to postgres.
4. The cloned [fly.toml](fly.toml) **will be overwritten** to remove commented lines and replace the app name using the randomized string. [fly.toml.sample](fly.toml.sample) is a copy of this file for reference.
5. The provided domain by fly isn't currently working, but you can access the services using the ip address (i.e. `http://x.x.x.x/v2/info`)

```bash
$ flyctl ips list
TYPE ADDRESS           REGION CREATED AT
v4   66.51.127.159     global 26m3s ago
v6   2a09:8280:1::2957 global 26m3s ago
```

```bash
$ curl -sL 66.51.127.159/v2/info | jq
{
  "peer_version": 402653189,
  "pox_consensus": "7bb613b32725ee2a2e848092cd933faa3fccbb12",
  "burn_block_height": 666636,
  "stable_pox_consensus": "3863cf76dbcaeb9c1e80c6ba6dba31fd07f698e6",
  "stable_burn_block_height": 666629,
  "server_version": "stacks-node 2.05.0.1.0 (master:de541f9, release build, linux [x86_64])",
  "network_id": 1,
  "parent_network_id": 3652501241,
  "stacks_tip_height": 423,
  "stacks_tip": "8b0bf6c7019378ab445ccd0b3b6bff8387d7cb31f0658cf73c3a707f09c3fb09",
  "stacks_tip_consensus_hash": "7dfb7b7542cb7ccdc2e9111c683e2d380104aa65",
  "genesis_chainstate_hash": "74237aa39aa50a83de11a4f53e9d3bb7d43461d1de9873f402e5453ae60bc59b",
  "unanchored_tip": null,
  "unanchored_seq": null,
  "exit_at_block_height": null
}
```
