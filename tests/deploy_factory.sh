#!/bin/sh

# ================================================================================
#
AMOUNT_TONS=600000000000
GIVER="0:841288ed3b55d9cdafa806807f02a0ae0c169aa5edfe88a789a6482429756a94"
CODE=$(tvm_linker decode --tvc ../contracts/SymbolPair.tvc  | grep code: | cut -c 8-)
KEYS_FILE="keysFactory.json"
PUBKEY=$(cat $KEYS_FILE | grep public | cut -c 14-77)
ZERO_ADDRESS="0:0000000000000000000000000000000000000000000000000000000000000000"

NETWORK=$(./get_url.sh)

echo "===================================================================================================="
echo "deploying Factory"
echo "===================================================================================================="
FACTORY_ADDRESS=$(./get_factory_address.sh)

echo "Giving $AMOUNT_TONS TONs to $FACTORY_ADDRESS"
tonos-cli -u $NETWORK call --abi local_giver.abi.json $GIVER sendGrams "{\"dest\":\"$FACTORY_ADDRESS\",\"amount\":\"$AMOUNT_TONS\"}" > /dev/null
tonos-cli -u $NETWORK deploy ../contracts/DexFactory.tvc '{"ownerPubKey":"0x'$PUBKEY'"}' --abi ../contracts/DexFactory.abi.json --sign $KEYS_FILE --wc 0
