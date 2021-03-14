#!/bin/sh

# ================================================================================
#
KEYS1_FILE="keys1.json"
PUBKEY1=$(cat $KEYS1_FILE | grep public | cut -c 14-77)
KEYS2_FILE="keys2.json"
PUBKEY2=$(cat $KEYS2_FILE | grep public | cut -c 14-77)
ZERO_ADDRESS="0:0000000000000000000000000000000000000000000000000000000000000000"

NETWORK=$(./get_url.sh)

RTW1_ADDRESS=$(./get_rtw1_address.sh)
RTW2_ADDRESS=$(./get_rtw2_address.sh)
TTW1_ADDRESS=$(./get_ttw1_address.sh 1)
TTW2_ADDRESS=$(./get_ttw2_address.sh 1)

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
echo "Give allowance"
echo "===================================================================================================="
tonos-cli -u $NETWORK call $TTW1_ADDRESS approveAddress '{"spender":"'$PAIR_ADDRESS'","curAllowance":0,"newAllowance":"80000000000000"}'   --abi ../contracts/TTW_FT.abi.json --sign $KEYS1_FILE | awk '/Result: {/,/}/'
tonos-cli -u $NETWORK call $TTW2_ADDRESS approveAddress '{"spender":"'$PAIR_ADDRESS'","curAllowance":0,"newAllowance":"2468000000000000"}' --abi ../contracts/TTW_FT.abi.json --sign $KEYS1_FILE | awk '/Result: {/,/}/'

tonos-cli -u $NETWORK run $TTW1_ADDRESS getBalance '{}'  --abi ../contracts/TTW_FT.abi.json | awk '/Result: {/,/}/'
tonos-cli -u $NETWORK run $TTW2_ADDRESS getBalance '{}'  --abi ../contracts/TTW_FT.abi.json | awk '/Result: {/,/}/'

tonos-cli -u $NETWORK run $TTW1_ADDRESS allowanceAddress '{"spender":"'$PAIR_ADDRESS'"}'  --abi ../contracts/TTW_FT.abi.json | awk '/Result: {/,/}/'
tonos-cli -u $NETWORK run $TTW2_ADDRESS allowanceAddress '{"spender":"'$PAIR_ADDRESS'"}'  --abi ../contracts/TTW_FT.abi.json | awk '/Result: {/,/}/'

echo "===================================================================================================="
echo "depositLiquidity"
echo "===================================================================================================="
tonos-cli -u $NETWORK call $PAIR_ADDRESS depositLiquidity '{"amount1":"40000000000000", "amount2":"1234000000000000","ttwToken1":"'$TTW1_ADDRESS'","ttwToken2":"'$TTW2_ADDRESS'"}' --abi ../contracts/SymbolPair.abi.json --sign $KEYS1_FILE

echo "===================================================================================================="
echo "getPairRatio"
echo "===================================================================================================="
tonos-cli -u $NETWORK run $PAIR_ADDRESS getPairRatio '{"firstFirst":"true"}'  --abi ../contracts/SymbolPair.abi.json | awk '/Result: {/,/}/'
tonos-cli -u $NETWORK run $PAIR_ADDRESS getPairRatio '{"firstFirst":"false"}' --abi ../contracts/SymbolPair.abi.json | awk '/Result: {/,/}/'

echo "===================================================================================================="
echo "getPairLiquidity"
echo "===================================================================================================="
tonos-cli -u $NETWORK run $PAIR_ADDRESS getPairLiquidity '{}' --abi ../contracts/SymbolPair.abi.json | awk '/Result: {/,/}/'
tonos-cli -u $NETWORK run $PAIR_ADDRESS getUserTotalLiquidity '{}' --abi ../contracts/SymbolPair.abi.json | awk '/Result: {/,/}/'
tonos-cli -u $NETWORK run $PAIR_ADDRESS getUserLiquidity '{"ownerPubKey":"0x'$PUBKEY1'"}' --abi ../contracts/SymbolPair.abi.json | awk '/Result: {/,/}/'

echo "===================================================================================================="
echo "getPrice 1-2"
echo "===================================================================================================="
tonos-cli -u $NETWORK run $PAIR_ADDRESS getPrice '{"RTW_ofTokenToGet":"'$RTW1_ADDRESS'","RTW_ofTokenToGive":"'$RTW2_ADDRESS'","amountToGive":"1000000000000"}' --abi ../contracts/SymbolPair.abi.json | awk '/Result: {/,/}/'
echo "===================================================================================================="
echo "getPrice 2-1"
echo "===================================================================================================="
tonos-cli -u $NETWORK run $PAIR_ADDRESS getPrice '{"RTW_ofTokenToGet":"'$RTW2_ADDRESS'","RTW_ofTokenToGive":"'$RTW1_ADDRESS'","amountToGive":"1000000000"}' --abi ../contracts/SymbolPair.abi.json | awk '/Result: {/,/}/'

echo "===================================================================================================="
echo "Swap"
echo "===================================================================================================="
tonos-cli -u $NETWORK call $PAIR_ADDRESS swapTokens '{"tokenToGet":"'$RTW1_ADDRESS'","tokenToGive":"'$RTW2_ADDRESS'","amountToGive":"1000000000000","ttwTokenToGet":"'$TTW1_ADDRESS'","ttwTokenToGive":"'$TTW2_ADDRESS'"}' --abi ../contracts/SymbolPair.abi.json --sign $KEYS1_FILE | awk '/Result: {/,/}/'

echo "===================================================================================================="
echo "getPairLiquidity"
echo "===================================================================================================="
tonos-cli -u $NETWORK run $PAIR_ADDRESS getPairLiquidity '{}' --abi ../contracts/SymbolPair.abi.json | awk '/Result: {/,/}/'
tonos-cli -u $NETWORK run $PAIR_ADDRESS getUserTotalLiquidity '{}' --abi ../contracts/SymbolPair.abi.json | awk '/Result: {/,/}/'
tonos-cli -u $NETWORK run $PAIR_ADDRESS getUserLiquidity '{"ownerPubKey":"0x'$PUBKEY1'"}' --abi ../contracts/SymbolPair.abi.json | awk '/Result: {/,/}/'

echo "===================================================================================================="
echo "withdrawLiquidity"
echo "===================================================================================================="
tonos-cli -u $NETWORK call $PAIR_ADDRESS withdrawLiquidity '{"amountLiquidity":"40000000000000000000"}' --abi ../contracts/SymbolPair.abi.json --sign $KEYS1_FILE | awk '/Result: {/,/}/'

echo "===================================================================================================="
echo "getPairLiquidity"
echo "===================================================================================================="
tonos-cli -u $NETWORK run $PAIR_ADDRESS getUserTotalLiquidity '{}' --abi ../contracts/SymbolPair.abi.json | awk '/Result: {/,/}/'
tonos-cli -u $NETWORK run $PAIR_ADDRESS getUserLiquidity '{"ownerPubKey":"0x'$PUBKEY1'"}' --abi ../contracts/SymbolPair.abi.json | awk '/Result: {/,/}/'
