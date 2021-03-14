#!/bin/sh

# ================================================================================
#
KEYS_FILE="keysFactory.json"
PUBKEY=$(cat $KEYS_FILE | grep public | cut -c 14-77)
ZERO_ADDRESS="0:0000000000000000000000000000000000000000000000000000000000000000"

NETWORK=$(./get_url.sh)

echo "===================================================================================================="
echo "Adding symbol 2 to DEX"
echo "===================================================================================================="
RTW_ADDRESS=$(./get_rtw2_address.sh)
echo "RTW ADDRESS: $RTW_ADDRESS"

FACTORY_ADDRESS=$(./get_factory_address.sh)
echo "FACTORY ADDRESS: $FACTORY_ADDRESS"

tonos-cli -u $NETWORK call $FACTORY_ADDRESS addSymbol '{"symbolRTW":"'$RTW_ADDRESS'", "symbolType":1}' --abi ../contracts/DexFactory.abi.json --sign $KEYS_FILE

echo "===================================================================================================="
echo "getSymbol"
echo "===================================================================================================="
tonos-cli -u $NETWORK run $FACTORY_ADDRESS getSymbol '{"symbolRTW":"'$RTW_ADDRESS'"}' --abi ../contracts/DexFactory.abi.json | awk '/Result: {/,/}/'

#echo "===================================================================================================="
#echo "getSymbolAwaiting"
#echo "===================================================================================================="
#tonos-cli -u $NETWORK run $FACTORY_ADDRESS getSymbolAwaiting '{"symbolRTW":"'$RTW_ADDRESS'"}' --abi ../contracts/DexFactory.abi.json | awk '/Result: {/,/}/'