#!/bin/sh

# ================================================================================
#
CODE=$(tvm_linker decode --tvc ../contracts/SymbolPair.tvc  | grep code: | cut -c 8-)
KEYS_FILE="keysFactory.json"
PUBKEY=$(cat $KEYS_FILE | grep public | cut -c 14-77)

NETWORK=$(./get_url.sh)

RTW1_ADDRESS=$(./get_rtw1_address.sh)
RTW2_ADDRESS=$(./get_rtw2_address.sh)
FACTORY_ADDRESS=$(./get_factory_address.sh)

PAIR_ADDRESS=$(tonos-cli -u $NETWORK run $FACTORY_ADDRESS getPairAddress '{"symbol1RTW":"'$RTW1_ADDRESS'","symbol2RTW":"'$RTW2_ADDRESS'"}' --abi ../contracts/DexFactory.abi.json | grep "value0" | cut -c 14-79)
echo $PAIR_ADDRESS