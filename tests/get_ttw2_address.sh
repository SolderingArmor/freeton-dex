#!/bin/sh

# ================================================================================
#
TTW_KEYS_FILE="keys$1.json"
PUBKEY_TTW=$(cat $TTW_KEYS_FILE | grep public | cut -c 14-77)
ZERO_ADDRESS="0:0000000000000000000000000000000000000000000000000000000000000000"

NETWORK=$(./get_url.sh)

# ================================================================================
#
RTW_ADDRESS=$(./get_rtw2_address.sh)
TTW_ADDRESS=$(tonos-cli -u $NETWORK run $RTW_ADDRESS getWalletAddress '{"walletPublicKey":"0x'$PUBKEY_TTW'","ownerAddress":"'$ZERO_ADDRESS'"}' --abi ../contracts/RTW_FT.abi.json | grep "value0" | cut -c 14-79)
echo $TTW_ADDRESS