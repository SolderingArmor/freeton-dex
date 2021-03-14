#!/bin/sh

# ================================================================================
#
KEYS1_FILE="keys1.json"
PUBKEY1=$(cat $KEYS1_FILE | grep public | cut -c 14-77)
KEYS2_FILE="keys2.json"
PUBKEY2=$(cat $KEYS2_FILE | grep public | cut -c 14-77)
ZERO_ADDRESS="0:0000000000000000000000000000000000000000000000000000000000000000"

NETWORK=$(./get_url.sh)

echo "===================================================================================================="
PAIR_ADDRESS=$(./get_symbol_pair_address.sh)
echo "PAIR ADDRESS: $PAIR_ADDRESS"

echo "===================================================================================================="
echo "Pair Symbols"
echo "===================================================================================================="
tonos-cli -u $NETWORK run $PAIR_ADDRESS _symbol1 '{}' --abi ../contracts/SymbolPair.abi.json | awk '/Result: {/,/}/'
tonos-cli -u $NETWORK run $PAIR_ADDRESS _symbol2 '{}' --abi ../contracts/SymbolPair.abi.json | awk '/Result: {/,/}/'

echo "===================================================================================================="
echo "Current fee"
echo "===================================================================================================="
tonos-cli -u $NETWORK run $PAIR_ADDRESS _currentFee '{}' --abi ../contracts/SymbolPair.abi.json | awk '/Result: {/,/}/'

echo "===================================================================================================="
echo "depositLiquidity"
echo "===================================================================================================="
tonos-cli -u $NETWORK call $PAIR_ADDRESS depositLiquidity '{"amount1":"40000000000000", "amount2":"1234000000000000"}' --abi ../contracts/SymbolPair.abi.json --sign $KEYS1_FILE | awk '/Result: {/,/}/'
#tonos-cli -u $NETWORK call $PAIR_ADDRESS depositLiquidity '{"amount1":"40000000000000", "amount2":"123400000000000"}' --abi ../contracts/SymbolPair.abi.json --sign $KEYS1_FILE | awk '/Result: {/,/}/'
#tonos-cli -u $NETWORK call $PAIR_ADDRESS depositLiquidity '{"amount1":"76234876324866", "amount2":"12344563456000000"}' --abi ../contracts/SymbolPair.abi.json --sign $KEYS1_FILE | awk '/Result: {/,/}/'

echo "===================================================================================================="
echo "getPairRatio"
echo "===================================================================================================="
tonos-cli -u $NETWORK run $PAIR_ADDRESS getPairRatio '{"firstFirst":"true"}'  --abi ../contracts/SymbolPair.abi.json | awk '/Result: {/,/}/'
tonos-cli -u $NETWORK run $PAIR_ADDRESS getPairRatio '{"firstFirst":"false"}' --abi ../contracts/SymbolPair.abi.json | awk '/Result: {/,/}/'

echo "===================================================================================================="
echo "getPairLiquidity"
echo "===================================================================================================="
tonos-cli -u $NETWORK run $PAIR_ADDRESS getUserTotalLiquidity '{}' --abi ../contracts/SymbolPair.abi.json | awk '/Result: {/,/}/'
tonos-cli -u $NETWORK run $PAIR_ADDRESS getUserLiquidity '{"ownerPubKey":"0x'$PUBKEY1'"}' --abi ../contracts/SymbolPair.abi.json | awk '/Result: {/,/}/'

echo "===================================================================================================="
echo "withdrawLiquidity"
echo "===================================================================================================="
tonos-cli -u $NETWORK call $PAIR_ADDRESS withdrawLiquidity '{"amountLiquidity":"40000000000000000000", "crystalWalletAddress":"'$ZERO_ADDRESS'"}' --abi ../contracts/SymbolPair.abi.json --sign $KEYS1_FILE | awk '/Result: {/,/}/'

echo "===================================================================================================="
echo "getPairLiquidity"
echo "===================================================================================================="
tonos-cli -u $NETWORK run $PAIR_ADDRESS getUserTotalLiquidity '{}' --abi ../contracts/SymbolPair.abi.json | awk '/Result: {/,/}/'
tonos-cli -u $NETWORK run $PAIR_ADDRESS getUserLiquidity '{"ownerPubKey":"0x'$PUBKEY1'"}' --abi ../contracts/SymbolPair.abi.json | awk '/Result: {/,/}/'
