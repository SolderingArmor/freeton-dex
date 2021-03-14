#!/bin/sh

# ================================================================================
#
KEYS_FILE="keysFactory.json"
PUBKEY=$(cat $KEYS_FILE | grep public | cut -c 14-77)
ZERO_ADDRESS="0:0000000000000000000000000000000000000000000000000000000000000000"

NETWORK=$(./get_url.sh)

echo "===================================================================================================="
echo "Adding Pair 1-2 to DEX"
echo "===================================================================================================="
RTW1_ADDRESS=$(./get_rtw1_address.sh)
echo "RTW1 ADDRESS: $RTW1_ADDRESS"

RTW2_ADDRESS=$(./get_rtw2_address.sh)
echo "RTW2 ADDRESS: $RTW2_ADDRESS"

FACTORY_ADDRESS=$(./get_factory_address.sh)
echo "FACTORY ADDRESS: $FACTORY_ADDRESS"

tonos-cli -u $NETWORK call $FACTORY_ADDRESS addPair '{"symbol1RTW":"'$RTW1_ADDRESS'","symbol2RTW":"'$RTW2_ADDRESS'"}' --abi ../contracts/DexFactory.abi.json --sign $KEYS_FILE

PAIR_ADDRESS=$(./get_symbol_pair_address.sh)
echo "PAIR ADDRESS: $PAIR_ADDRESS"

#echo "===================================================================================================="
#echo "Get SymbolPair "
#echo "===================================================================================================="
#tonos-cli -u $NETWORK run $PAIR_ADDRESS _symbol1 '{}' --abi ../contracts/SymbolPair.abi.json | awk '/Result: {/,/}/'
#tonos-cli -u $NETWORK run $PAIR_ADDRESS _symbol2 '{}' --abi ../contracts/SymbolPair.abi.json | awk '/Result: {/,/}/'
