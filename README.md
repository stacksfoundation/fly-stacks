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
$ cp fly.toml.sample fly.toml
# note: sed is assumed to be GNU sed, BSD variants might not work as is
$ sed -i -e "s|app = \"\"|app = \"${APP_NAME}\"|" fly.toml
$ flyctl postgres create --name=$PSQL_NAME --region=lax  --initial-cluster-size=Development --vm-size=dedicated-cpu-1x --volume-size=50 --initial-cluster-size=1
$ flyctl launch --no-deploy --dockerfile Dockerfile --copy-config  --region=lax --name=$APP_NAME
$ flyctl volumes create stacks_blockchain_data --size=50 --region=lax --no-encryption
$ flyctl scale vm dedicated-cpu-1x -a=$APP_NAME
$ flyctl scale memory 4096
$ flyctl postgres attach --postgres-app $PSQL_NAME
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

```bash
$ flyctl ips list
TYPE ADDRESS             REGION CREATED AT
v4   213.188.218.127     global 32m44s ago
v6   2a09:8280:1::a:37d4 global 32m44s ago

$ flyctl apps list
NAME                          	OWNER   	STATUS 	LATEST DEPLOY
stacks-blockchain-3d9f78229768	personal	running	32m54s ago
stacks-postgres-3d9f78229768  	personal	running	36m49s ago
```

```bash
$ curl -sL https://stacks-blockchain-3d9f78229768.fly.dev/
{
  "server_version": "stacks-blockchain-api v3.0.3 (master:cd0c8aef)",
  "status": "ready",
  "chain_tip": {
    "block_height": 1026,
    "block_hash": "0x9e4d487d1ebcc825728ff155c159499163098386be9d7e12ecd4f11db300aa09",
    "index_block_hash": "0x3ee40b55b6ce3d29970d0a79231aea213ed88a06accfa090e024c75182ccdbab"
  }
}

$ curl -sL https://stacks-blockchain-3d9f78229768.fly.dev/v2/info | jq
{
  "peer_version": 402653189,
  "pox_consensus": "4d402b1e688e23efdd123d4e205172779d54de56",
  "burn_block_height": 667440,
  "stable_pox_consensus": "54a253aed603327559c78ab585fa4997ff19e4f1",
  "stable_burn_block_height": 667433,
  "server_version": "stacks-node 2.05.0.2.0 (develop:4641001, release build, linux [x86_64])",
  "network_id": 1,
  "parent_network_id": 3652501241,
  "stacks_tip_height": 1055,
  "stacks_tip": "b39f642e6e0c915e92a525229ddb7c8a54161fa9f0c48b7c0979d0de751f590e",
  "stacks_tip_consensus_hash": "062039b8235b94e2bc5134db846e2a63122bc8a8",
  "genesis_chainstate_hash": "74237aa39aa50a83de11a4f53e9d3bb7d43461d1de9873f402e5453ae60bc59b",
  "unanchored_tip": null,
  "unanchored_seq": null,
  "exit_at_block_height": null,
  "node_public_key": "02d8f1b0c58988cb4606feea86b8bc96eb3c5b37a17b14bbe7dd51f03b15c4f13a",
  "node_public_key_hash": "cf01284458f6a183ae2861759d68b9a12d774435"
}
```
