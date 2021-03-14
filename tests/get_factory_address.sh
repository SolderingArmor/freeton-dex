#!/bin/sh

# ================================================================================
#
CODE=$(tvm_linker decode --tvc ../contracts/SymbolPair.tvc  | grep code: | cut -c 8-)
KEYS_FILE="keysFactory.json"
PUBKEY=$(cat $KEYS_FILE | grep public | cut -c 14-77)

NETWORK=$(./get_url.sh)

FACTORY_ADDRESS=$(tonos-cli genaddr --data '{"_symbolPairCode":"'$CODE'"}' ../contracts/DexFactory.tvc ../contracts/DexFactory.abi.json --setkey $KEYS_FILE --wc 0 --save | grep "Raw address:" | cut -c 14-)
FACTORY_ADDRESS=$(tonos-cli genaddr --data '{"_symbolPairCode":"'$CODE'"}' ../contracts/DexFactory.tvc ../contracts/DexFactory.abi.json --setkey $KEYS_FILE --wc 0 --save | grep "Raw address:" | cut -c 14-)
echo $FACTORY_ADDRESS