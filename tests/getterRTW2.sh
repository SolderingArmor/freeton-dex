#!/bin/sh

# ================================================================================
#
NETWORK=$(./get_url.sh)

GETTER_NAME=$1

echo "===================================================================================================="
echo "Getting $GETTER_NAME from $@"
echo "===================================================================================================="

RTW_ADDRESS=$(./get_rtw2_address.sh $@)
echo "RTW ADDRESS: $RTW_ADDRESS"

tonos-cli -u $NETWORK run $RTW_ADDRESS $GETTER_NAME '{}' --abi ../contracts/RTW_FT.abi.json | awk '/Result: {/,/}/'
