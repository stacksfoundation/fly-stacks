# Stacks Blockchain on fly.io

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Pull Requests Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat)](http://makeapullrequest.com)

https://fly.io/docs/hands-on/sign-up/

https://fly.io/docs/getting-started/installing-flyctl/

https://fly.io/docs/about/pricing/

## Quickstart

The following commands are meant as examples only - **the minimum viable settings are used to launch the service**.

- This will launch 2 services in fly: a single node postgres instance and a stacks-blockchain (with API) using that DB.
- The name is randomized by `openssl rand -hex 6`, producing a name like `stacks-blockchain-9dbc4006e43e` - using a common name doesn't seem to be supported (i.e. not `stacks-blockchain`)
- The command `flyctl deploy --detach` will deploy the stacks blockchain service _without_ waiting for health checks to return. Remove `--detach` from the command to wait on health checks.
- Finally, to see the logs during the deploy - you can use the web UI, or run `flyctl logs` to monitor the progress.
-

### Using a fly.io managed database

```bash
flyctl auth signup
flyctl auth login
flyctl auth docker
export FLY_ACCESS_TOKEN=$(flyctl auth token)
export RAND_STRING=$(openssl rand -hex 6)
export PSQL_NAME="stacks-postgres-${RAND_STRING}"
export APP_NAME="stacks-blockchain-${RAND_STRING}"
cp fly.toml.sample fly.toml
sed -i "/^app =/s/.*/app = \"${APP_NAME}\"/" fly.toml
flyctl postgres create --name=${PSQL_NAME} --region=lax  --initial-cluster-size=Development --vm-size=dedicated-cpu-1x --volume-size=50 --initial-cluster-size=1
flyctl launch --no-deploy --dockerfile Dockerfile --copy-config  --region=lax --name=${APP_NAME}
flyctl volumes create stacks_blockchain_data --size=50 --region=lax --no-encryption
flyctl scale vm dedicated-cpu-1x -a=${APP_NAME}
flyctl scale memory 4096
flyctl postgres attach --postgres-app ${PSQL_NAME}
flyctl deploy --detach
```

### Using an external database

```bash
flyctl auth signup
flyctl auth login
flyctl auth docker
export FLY_ACCESS_TOKEN=$(flyctl auth token)
export RAND_STRING=$(openssl rand -hex 6)
export PSQL_NAME="stacks-postgres-${RAND_STRING}"
export APP_NAME="stacks-blockchain-${RAND_STRING}"
export PG_URL="<postgres url>"
cp fly.toml.sample fly.toml
sed -i "/^app =/s/.*/app = \"${APP_NAME}\"/" fly.toml
flyctl launch --no-deploy --dockerfile Dockerfile --copy-config  --region=lax --name=${APP_NAME}
flyctl --app ${APP_NAME} secrets set DATABASE_URL="${PG_URL}"
flyctl volumes create stacks_blockchain_data --size=50 --region=lax --no-encryption
flyctl scale vm dedicated-cpu-1x -a=${APP_NAME}
flyctl scale memory 4096
flyctl deploy --detach
rm logs.txt
```

## Notes

1. Blockchain sync time with the above VM settings will be a bit slower due to the shared single vcpu. For better performance -> [use a higher resource VM](https://fly.io/docs/about/pricing/)
   1. Pricing for a 4GB instance for 1 month is about $30 with a managed DB
2. When the command `flyctl postgres create` is run, it adds an env var `DATABASE_URL` to the deployment. [entrypoint.sh](scripts/entrypoint.sh#L37) uses this env var to connect to postgres.
3. The cloned [fly.toml](fly.toml) **will be overwritten** to remove commented lines and replace the app name using the randomized string. [fly.toml.sample](fly.toml.sample) is a copy of this file for reference.

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
  "server_version": "stacks-blockchain-api v4.0.4 (master:cd0c8aef)",
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
  "server_version": "stacks-node 2.05.0.2.2 (develop:4641001, release build, linux [x86_64])",
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

### Sample output from CLI

```
{7:54}~/Git/fly-stacks:master ✗ ➭ flyctl auth login
Opening https://fly.io/app/auth/cli/c39e16dc3c07a8c3ff4df07a5e839175 ...

Waiting for session... Done
successfully logged in as xxxxxxxx
{7:54}~/Git/fly-stacks:master ✗ ➭ flyctl auth docker
Authentication successful. You can now tag and push images to registry.fly.io/{your-app}

{7:54}~/Git/fly-stacks:master ✗ ➭ export FLY_ACCESS_TOKEN=$(flyctl auth token)
{7:54}~/Git/fly-stacks:master ✗ ➭ export RAND_STRING=$(openssl rand -hex 6)
{7:54}~/Git/fly-stacks:master ✗ ➭ export PSQL_NAME="stacks-postgres-${RAND_STRING}"
{7:54}~/Git/fly-stacks:master ✗ ➭ export APP_NAME="stacks-blockchain-${RAND_STRING}"
{7:54}~/Git/fly-stacks:master ✗ ➭ cp fly.toml.sample fly.toml
{7:55}~/Git/fly-stacks:master ✓ ➭ sed -i -e "s|app = \"\"|app = \"${APP_NAME}\"|" fly.toml
{7:55}~/Git/fly-stacks:master ✗ ➭ flyctl postgres create --name=$PSQL_NAME --region=lax  --initial-cluster-size=Development --vm-size=dedicated-cpu-1x --volume-size=50 --initial-cluster-size=1
Automatically selected personal organization: xxxxxxxx
Creating postgres cluster stacks-postgres-3d9f78229768 in organization personal
Postgres cluster stacks-postgres-3d9f78229768 created
  Username:    postgres
  Password:    xxxxxxxx
  Hostname:    stacks-postgres-3d9f78229768.internal
  Proxy Port:  5432
  PG Port: 5433
Save your credentials in a secure place, you won't be able to see them again!

Monitoring Deployment

1 desired, 1 placed, 1 healthy, 0 unhealthy [health checks: 3 total, 3 passing]
--> v0 deployed successfully

Connect to postgres
Any app within the personal organization can connect to postgres using the above credentials and the hostname "stacks-postgres-3d9f78229768.internal."
For example: postgres://postgres:xxxxxxxx@stacks-postgres-3d9f78229768.internal:5432

See the postgres docs for more information on next steps, managing postgres, connecting from outside fly:  https://fly.io/docs/reference/postgres/

{7:56}~/Git/fly-stacks:master ✗ ➭ flyctl launch --no-deploy --dockerfile Dockerfile --copy-config  --region=lax --name=$APP_NAME
An existing fly.toml file was found for app stacks-blockchain-3d9f78229768
Creating app in ~/Git/fly-stacks
Using dockefile Dockerfile
Selected App Name: stacks-blockchain-3d9f78229768
Automatically selected personal organization: xxxxxxxx
Created app stacks-blockchain-3d9f78229768 in organization personal
Wrote config file fly.toml
Your app is ready. Deploy with `flyctl deploy`

{7:56}~/Git/fly-stacks:master ✗ ➭ flyctl volumes create stacks_blockchain_data --size=50 --region=lax --no-encryption
        ID: vol_5podq4qljggrg8w1
      Name: stacks_blockchain_data
       App: stacks-blockchain-3d9f78229768
    Region: lax
      Zone: c6d5
   Size GB: 50
 Encrypted: false
Created at: 13 May 22 14:56 UTC
{7:56}~/Git/fly-stacks:master ✗ ➭ flyctl scale vm dedicated-cpu-1x -a=$APP_NAME
Scaled VM Type to
 dedicated-cpu-1x
      CPU Cores: 1
         Memory: 2 GB

{7:56}~/Git/fly-stacks:master ✗ ➭ flyctl scale memory 4096
Scaled VM Memory size to 4 GB
      CPU Cores: 1
         Memory: 4 GB

{7:57}~/Git/fly-stacks:master ✗ ➭ flyctl postgres attach --postgres-app $PSQL_NAME
Postgres cluster stacks-postgres-3d9f78229768 is now attached to stacks-blockchain-3d9f78229768
The following secret was added to stacks-blockchain-3d9f78229768:
  DATABASE_URL=postgres://stacks_blockchain_3d9f78229768:xxxxxxxx@top2.nearest.of.stacks-postgres-3d9f78229768.internal:5432/stacks_blockchain_3d9f78229768

{7:57}~/Git/fly-stacks:master ✗ ➭ flyctl deploy --detach
==> Verifying app config
--> Verified app config
==> Building image
==> Creating build context
--> Creating build context done
==> Building image with Docker
--> docker host: 20.10.14 linux aarch64
Sending build context to Docker daemon  207.9kB
[+] Building 0.3s (16/16) FINISHED
 => [internal] load remote build context                                                                                                                                                                                                                                                                                         0.0s
 => copy /context /                                                                                                                                                                                                                                                                                                              0.2s
 => [internal] load metadata for docker.io/hirosystems/stacks-blockchain-api:3.0.3                                                                                                                                                                                                                                               0.0s
 => [internal] load metadata for docker.io/blockstack/stacks-blockchain:2.05.0.2.0                                                                                                                                                                                                                                               0.0s
 => CACHED [stacks-blockchain-build 1/1] FROM docker.io/blockstack/stacks-blockchain:2.05.0.2.0                                                                                                                                                                                                                                  0.0s
 => [stage-1 1/9] FROM docker.io/hirosystems/stacks-blockchain-api:3.0.3                                                                                                                                                                                                                                                         0.0s
 => CACHED [stage-1 2/9] COPY --from=stacks-blockchain-build /bin/stacks-node /bin                                                                                                                                                                                                                                               0.0s
 => CACHED [stage-1 3/9] RUN apk add     nginx                                                                                                                                                                                                                                                                                   0.0s
 => CACHED [stage-1 4/9] RUN mkdir -p /stacks-blockchain     mkdir -p /etc/stacks-blockchain                                                                                                                                                                                                                                     0.0s
 => CACHED copy /context /                                                                                                                                                                                                                                                                                                       0.0s
 => CACHED [stage-1 5/9] COPY configs/nginx.conf /etc/nginx/http.d/default.conf                                                                                                                                                                                                                                                  0.0s
 => CACHED [stage-1 6/9] COPY configs/Stacks-*.toml /etc/stacks-blockchain/                                                                                                                                                                                                                                                      0.0s
 => CACHED [stage-1 7/9] COPY scripts/entrypoint.sh /docker-entrypoint.sh                                                                                                                                                                                                                                                        0.0s
 => CACHED [stage-1 8/9] COPY scripts/setup-bns.sh /setup-bns.sh                                                                                                                                                                                                                                                                 0.0s
 => CACHED [stage-1 9/9] RUN chmod 755     /docker-entrypoint.sh     /setup-bns.sh                                                                                                                                                                                                                                               0.0s
 => exporting to image                                                                                                                                                                                                                                                                                                           0.0s
 => => exporting layers                                                                                                                                                                                                                                                                                                          0.0s
 => => writing image sha256:6dc6ce9223716a669a4e66c0ba6f247a1fbfd97f4a0d00ea08e07d6f8ed71266                                                                                                                                                                                                                                     0.0s
 => => naming to registry.fly.io/stacks-blockchain-3d9f78229768:deployment-1652453833                                                                                                                                                                                                                                            0.0s
--> Building image done
==> Pushing image to fly
The push refers to repository [registry.fly.io/stacks-blockchain-3d9f78229768]
267a218c6685: Pushed
4704f25be9d5: Pushed
14f1d08fc485: Pushed
5a43a268693a: Pushed
56a0646e008a: Pushed
3cd854260cb4: Pushed
df8bc4dd87b6: Pushed
69a71887c4c5: Pushed
677f30c91cbe: Pushed
ea0445892f4a: Pushed
aa852cb2c237: Pushed
a800c27d8dc6: Pushed
58a65de4707f: Pushed
dbe5d2d44207: Pushed
763833755329: Pushed
72f8e4a1bf04: Pushed
4e3e1721ea11: Pushed
a1c01e366b99: Pushed
deployment-1652453833: digest: sha256:3cf102b558a7b52297f298921565411ad641c7c586845731deebea84bb8855ac size: 4088
--> Pushing image done
image: registry.fly.io/stacks-blockchain-3d9f78229768:deployment-1652453833
image size: 1.5 GB
==> Creating release
--> release v2 created
```
