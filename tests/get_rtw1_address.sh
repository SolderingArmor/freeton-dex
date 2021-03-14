#!/bin/sh

# ================================================================================
#
AMOUNT_TONS=6000000000
GIVER="0:841288ed3b55d9cdafa806807f02a0ae0c169aa5edfe88a789a6482429756a94"
CODE=$(tvm_linker decode --tvc ../contracts/TTW_FT.tvc  | grep code: | cut -c 8-)
KEYS_FILE="keysRTW1.json"
PUBKEY=$(cat $KEYS_FILE | grep public | cut -c 14-77)
ZERO_ADDRESS="0:0000000000000000000000000000000000000000000000000000000000000000"

RTW_NAME=$(echo -n "Shilo" | xxd -p )
RTW_SYMBOL=$(echo -n "SHL" | xxd -p )
RTW_DECIMALS="9"
RTW_OWNER_PK=$PUBKEY
RTW_OWNER_ADDRESS=$ZERO_ADDRESS
RTW_CODE=$CODE

RTW_DATA='{"_name":"'$RTW_NAME'","_symbol":"'$RTW_SYMBOL'","_decimals":'$RTW_DECIMALS',"_rootPublicKey":"0x'$RTW_OWNER_PK'","_rootOwnerAddress":"'$ZERO_ADDRESS'","_code":"'$CODE'"}'

NETWORK=$(./get_url.sh)

# ================================================================================
#
RTW_ADDRESS=$(tonos-cli genaddr --data $RTW_DATA ../contracts/RTW_FT.tvc ../contracts/RTW_FT.abi.json --setkey $KEYS_FILE --wc 0 --save | grep "Raw address:" | cut -c 14-)
RTW_ADDRESS=$(tonos-cli genaddr --data $RTW_DATA ../contracts/RTW_FT.tvc ../contracts/RTW_FT.abi.json --setkey $KEYS_FILE --wc 0 --save | grep "Raw address:" | cut -c 14-)
echo $RTW_ADDRESS