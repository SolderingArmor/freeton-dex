#!/bin/sh

# ================================================================================
#
AMOUNT_TONS=6000000000
GIVER="0:841288ed3b55d9cdafa806807f02a0ae0c169aa5edfe88a789a6482429756a94"
CODE=$(tvm_linker decode --tvc ../contracts/DnsRecord.tvc  | grep code: | cut -c 8-)
KEYS_FILE="keysFactory.json"
PUBKEY=$(cat $KEYS_FILE | grep public | cut -c 14-77)
ZERO_ADDRESS="0:0000000000000000000000000000000000000000000000000000000000000000"

NETWORK=$(./get_url.sh)

echo "===================================================================================================="
echo "deploying DeNS DeBot"
echo "===================================================================================================="

DEBOT_ADDRESS=$(tonos-cli genaddr --data '{}' ../contracts/DexDebot.tvc ../contracts/DexDebot.abi.json --setkey $KEYS_FILE --wc 0 --save | grep "Raw address:" | cut -c 14-)
DEBOT_ADDRESS=$(tonos-cli genaddr --data '{}' ../contracts/DexDebot.tvc ../contracts/DexDebot.abi.json --setkey $KEYS_FILE --wc 0 --save | grep "Raw address:" | cut -c 14-)

tonos-cli -u $NETWORK debot fetch $DEBOT_ADDRESS