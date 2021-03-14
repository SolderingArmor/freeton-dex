#!/bin/sh

# ================================================================================
#
AMOUNT_TONS=6000000000
GIVER="0:841288ed3b55d9cdafa806807f02a0ae0c169aa5edfe88a789a6482429756a94"
KEYS_FILE="keysFactory.json"
PUBKEY=$(cat $KEYS_FILE | grep public | cut -c 14-77)
ZERO_ADDRESS="0:0000000000000000000000000000000000000000000000000000000000000000"
DEBOT_ABI=$(cat ../contracts/DexDebot.abi.json | xxd -ps -c 20000)

NETWORK=$(./get_url.sh)

echo "===================================================================================================="
echo "deploying Dex DeBot"
echo "===================================================================================================="
tonos-cli genaddr --data '{}' ../contracts/DexDebot.tvc ../contracts/DexDebot.abi.json --setkey $KEYS_FILE --wc 0 --save
DEBOT_ADDRESS=$(tonos-cli genaddr --data '{}' ../contracts/DexDebot.tvc ../contracts/DexDebot.abi.json --setkey $KEYS_FILE --wc 0 --save | grep "Raw address:" | cut -c 14-)
echo "DeBot address: $DEBOT_ADDRESS"
echo "Giving $AMOUNT_TONS TONs to $DEBOT_ADDRESS"
tonos-cli -u $NETWORK call --abi local_giver.abi.json $GIVER sendGrams "{\"dest\":\"$DEBOT_ADDRESS\",\"amount\":\"$AMOUNT_TONS\"}" > /dev/null

echo "Deploying..."
tonos-cli -u $NETWORK deploy ../contracts/DexDebot.tvc '{}' --sign $KEYS_FILE --abi ../contracts/DexDebot.abi.json --wc 0
tonos-cli -u $NETWORK call $DEBOT_ADDRESS setABI "{\"dabi\":\"$DEBOT_ABI\"}" --sign $KEYS_FILE --abi ../contracts/DexDebot.abi.json
