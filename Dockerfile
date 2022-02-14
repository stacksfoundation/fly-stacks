# default versions to use (set to current defaults for 02/2022)
ARG STACKS_BLOCKCHAIN_VERSION=2.05.0.1.0
ARG STACKS_BLOCKCHAIN_API_VERSION=2.1.1

FROM blockstack/stacks-blockchain:${STACKS_BLOCKCHAIN_VERSION} as stacks-blockchain-build
FROM hirosystems/stacks-blockchain-api:${STACKS_BLOCKCHAIN_API_VERSION} as stacks-blockchain-api-build

FROM node:16-alpine
# set defaults for env vars, allow build args to modify them
ARG STACKS_NETWORK=mainnet
ARG NODE_ENV=production
ARG GIT_TAG=master
ARG STACKS_BLOCKCHAIN_API_PORT=3999
ARG STACKS_CORE_EVENT_PORT=3700
ARG STACKS_CORE_RPC_PORT=20443
ARG STACKS_CORE_P2P_PORT=20444
ARG V2_POX_MIN_AMOUNT_USTX=90000000260
ARG STACKS_CORE_EVENT_HOST=127.0.0.1
ARG STACKS_CORE_RPC_HOST=127.0.0.1
ARG STACKS_BLOCKCHAIN_API_HOST=0.0.0.0

# use defaults to set the env vars the API will use. can be overridden 
ENV STACKS_NETWORK=${STACKS_NETWORK}
ENV NODE_ENV=${NODE_ENV}
ENV GIT_TAG=${GIT_TAG}
ENV STACKS_CORE_EVENT_PORT=${STACKS_CORE_EVENT_PORT}
ENV STACKS_CORE_EVENT_HOST=${STACKS_CORE_EVENT_HOST}
ENV STACKS_BLOCKCHAIN_API_PORT=${STACKS_BLOCKCHAIN_API_PORT}
ENV STACKS_BLOCKCHAIN_API_HOST=${STACKS_BLOCKCHAIN_API_HOST}
ENV STACKS_CORE_RPC_HOST=${STACKS_CORE_RPC_HOST}
ENV STACKS_CORE_RPC_PORT=${STACKS_CORE_RPC_PORT}
ENV STACKS_CORE_P2P_PORT=${STACKS_CORE_P2P_PORT}
ENV V2_POX_MIN_AMOUNT_USTX=${V2_POX_MIN_AMOUNT_USTX}

COPY --from=stacks-blockchain-build /bin/stacks-node /bin
COPY --from=stacks-blockchain-build /bin/puppet-chain /bin
COPY --from=stacks-blockchain-api-build /app /app
RUN apk add \
    nginx

RUN mkdir -p /stacks-blockchain/data

# add nginx proxy so all http traffic goes over port 80
COPY configs/nginx.conf /etc/nginx/http.d/default.conf 
COPY configs/Stacks-*.toml /stacks-blockchain/
COPY scripts/entrypoint.sh /docker-entrypoint.sh
COPY scripts/setup-bns.sh /setup-bns.sh


RUN chmod 755 \
    /docker-entrypoint.sh \
    /setup-bns.sh

CMD /docker-entrypoint.sh