#!/bin/sh
case $STACKS_NETWORK in
    mainnet)
        CONFIG=/stacks-blockchain/Stacks-mainnet.toml
        export STACKS_CHAIN_ID=0x00000001
        ;;
    testnet)
        CONFIG=/stacks-blockchain/Stacks-testnet.toml
        export STACKS_CHAIN_ID=0x80000000
        ;;
    *)
        CONFIG=/stacks-blockchain/Stacks-mocknet.toml
        export STACKS_CHAIN_ID=2147483648
        ;;
esac


if [ ! -z "${BNS_IMPORT_DIR}" ]; then
    if [ ! -f "${BNS_IMPORT_DIR}/imported" ]; then
        if [ -f "/setup-bns.sh" ]; then
            /setup-bns.sh
            if [ $? -ne 0 ];then
                echo "Error processing BNS data. exiting"
                exit 1
            fi
        fi
    fi
fi



echo "Staring Nginx"
/usr/sbin/nginx -g "daemon off;" 2>&1 &

echo "Starting stacks-blockchain-api"
if [ "${DATABASE_URL}" ]; then
    export PG_CONNECTION_URI="${DATABASE_URL}"
    cd /app && node ./lib/index.js > /dev/stdout 2>&1 & 
else
    echo "Missing DATABASE_URL env var"
    exit 2
fi
echo "Starting stacks-blockchain"
/bin/stacks-node start --config=${CONFIG}
