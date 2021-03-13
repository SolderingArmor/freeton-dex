#!/bin/sh

# ================================================================================
#
NETWORK=$(./get_url.sh)

GETTER_NAME=$1

echo "===================================================================================================="
echo "Getting $GETTER_NAME from $@"
echo "===================================================================================================="

FACTORY_ADDRESS=$(./get_factory_address.sh)
echo "FACTORY ADDRESS: $FACTORY_ADDRESS"

tonos-cli -u $NETWORK run $FACTORY_ADDRESS $GETTER_NAME '{}' --abi ../contracts/DexFactory.abi.json | awk '/Result: {/,/}/'
