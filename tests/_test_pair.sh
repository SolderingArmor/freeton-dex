#!/bin/sh

# ================================================================================
#
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
echo "getPairRatio"
echo "===================================================================================================="
tonos-cli -u $NETWORK run $PAIR_ADDRESS getPairRatio '{"firstFirst":"false"}' --abi ../contracts/SymbolPair.abi.json | awk '/Result: {/,/}/'

echo "===================================================================================================="
echo "getPairLiquidity"
echo "===================================================================================================="
tonos-cli -u $NETWORK run $PAIR_ADDRESS getPairLiquidity '{}' --abi ../contracts/SymbolPair.abi.json | awk '/Result: {/,/}/'