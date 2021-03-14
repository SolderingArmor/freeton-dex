pragma ton-solidity >= 0.38.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

//================================================================================
//
enum SymbolType
{
    TonCrystal, // TON Crystal RTW address is 0;
    Tip3,       // TIP-3       RTW address of the RTW;
    Erc20       // ERC-20      RTW address of the Root Wallet;
}

//================================================================================
// 
struct Symbol
{
    SymbolType symbolType; //
    address    symbolRTW;  // Root Token Wallet for symbol if applicable (used in TIP-3 and ERC20), ...
    address    symbolTTW;  // TON  Token Wallet for symbol if applicable (used in TIP-3),           keeps all the liquidity of the symbol (across all the pairs);
    bytes      name;       //
    bytes      symbol;     //
    uint8      decimals;   //
    uint256    amount;     // In Factory: amount 0, check TTW for value;
                           // In Pair:    amount of this symbol in this pair, always equals to TTW value;
}

//================================================================================
// 
struct manageLiquidityStatus // both deposit and withdraw
{
    uint32  dtRequested;
    address symbol1TTW;
    uint128 symbol1Requested;
    uint128 symbol1ToProcess;
    uint128 symbol1Processed;
    uint    symbol1Error;
    address symbol2TTW;
    uint128 symbol2Requested;
    uint128 symbol2ToProcess;
    uint128 symbol2Processed;
    uint    symbol2Error;
    bool    done;
}

struct swapTokenStatus
{
    uint32  dtRequested;
    bool    direction;        // true means "get symbol1 and give symbol2", false means "give symbol1 and get symbol2"
    address symbol1TTW;
    uint128 symbol1Requested;
    uint128 symbol1Processed;
    uint    symbol1Error;
    address symbol2TTW;
    uint128 symbol2Requested;
    uint128 symbol2Processed;
    uint    symbol2Error;
    bool    done;
}

/*struct StateMachineAction
{
    //uint128 amount;
    bool    processed;
    uint    errorCode;
}

struct StateMachine
{
    address symbol1; // RTW address;
    address symbol2; // RTW address;
    uint128 amount1;
    uint128 amount2;

    StateMachineAction[3] actions;
    uint8   currentAction;
    uint    errorCode;
    bool    done;
}*/

//================================================================================
//
interface ISymbolPair
{
    //========================================
    //
    /// @notice Sets the fee that Liquidity Providers ger from each trade; 1% = 100; 100% = 10000;
    ///
    /// @param fee - Fee value; default 3% = 30;
    //
    function setProviderFee(uint16 fee) external;

    /// @notice Sets custom fee for this SymbolPair;
    ///
    /// @param isCustom   - If the fee is custom, when FALSE, see is set to be the same as common Provider fee;
    /// @param fee        - Fee value; default 3% = 30;
    //
    function setCustomProviderFee(bool isCustom, uint16 fee) external;

    //========================================
    // Liquidity
    function getPairRatio(bool firstFirst)                                                             external view returns (uint256, uint8); // Returns current pool ratio and decimals, is needed to perform correct "depositLiquidity";
    function depositLiquidity (uint128 amount1, uint128 amount2, address ttwToken1, address ttwToken2) external;                               // ORDER OF SYMBOLS MATTERS
    function withdrawLiquidity(uint256 amountLiquidity)                                                external;                               //
    function getPairLiquidity ()                                                                       external view returns (uint256, uint8); //
    function getUserLiquidity (uint256 ownerPubKey)                                                    external view returns (uint256, uint8); //
    function getUserTotalLiquidity()                                                                   external view returns (uint256, uint8); //

    // Trading
    function getPrice  (address RTW_ofTokenToGet, address RTW_ofTokenToGive, uint128 amountToGive) external view returns (uint256, uint8);
    function swapTokens(address tokenToGet, address tokenToGive, uint128 amountToGive, address ttwTokenToGet, address ttwTokenToGive) external;

    // Callbacks
    function callbackDeployEmptyWallet        (address newWalletAddress,       uint128 grams, uint256 walletPublicKey, address ownerAddress) external;
    function callbackSwapGetTTWAddress        (address targetAddress,                         uint256 walletPublicKey, address ownerAddress) external;
    function callbackDepositGetTTWAddress     (address targetAddress,                         uint256 walletPublicKey, address ownerAddress) external;
    function callbackSendTokensWithResolve    (uint errorCode, uint128 tokens, uint128 grams, uint256 pubKeyToResolve                      ) external;
    function callbackSwapGetTransferResult    (uint errorCode, uint128 tokens,                                         address to          ) external;
    function callbackDepositGetTransferResult2(uint errorCode, uint128 tokens,                                         address to          ) external;
    function callbackDepositGetTransferResult (uint errorCode, uint128 tokens,                                         address to          ) external;
}

//================================================================================
//
