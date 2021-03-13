pragma ton-solidity >= 0.38.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

//================================================================================
// 
interface ITonTokenWallet 
{
    //========================================
    // Get
    //========================================
    //
    function getName()                         external view returns (bytes);
    function getSymbol()                       external view returns (bytes);
    function getDecimals()                     external view returns (uint8);
    function getBalance()                      external view returns (uint128);
    function getWalletKey()                    external view returns (uint256);
    function getRootAddress()                  external view returns (address);
    function getOwnerAddress()                 external view returns (address);
    function getCode()                         external view returns (TvmCell);
    function allowanceAddress(address spender) external view returns (uint128);
    function allowancePubKey (uint256 spender) external view returns (uint128);

    //========================================
    // Management/Allowance
    //========================================
    //    
    /// @notice Sends all the remaining funds to "dest" and destroys the wallet;
    ///
    /// @param dest - TTW that will receive all tokens and all remaining TON Crystals; 
    //
    function destroy(address dest) external;

    /// @notice Create an allowance for address/public key;
    ///         ZPK means Zero Public Key, that means an internal message from contract to contract;
    ///
    /// @param spender      - target address/public key that will get access to this TTW's tokens;;
    /// @param curAllowance - current allowance; is needed to prevent double-spending attack;
    /// @param newAllowance - new allowance; may be 0;
    //
    function approveAddress   (address spender, uint128 curAllowance, uint128 newAllowance) external             returns (uint);
    function approveAddressZPK(address spender, uint128 curAllowance, uint128 newAllowance) external responsible returns (uint);
    function approvePubKey    (uint256 spender, uint128 curAllowance, uint128 newAllowance) external             returns (uint);
    function approvePubKeyZPK (uint256 spender, uint128 curAllowance, uint128 newAllowance) external responsible returns (uint);

    /// @notice Remove an allowance for address/public key;
    ///         ZPK means Zero Public Key, that means an internal message from contract to contract;
    ///
    /// @param spender - target address/public key that will loose access to this TTW's tokens;
    //
    function disapproveAddress   (address spender) external             returns (uint);
    function disapproveAddressZPK(address spender) external responsible returns (uint);
    function disapprovePubKey    (uint256 spender) external             returns (uint);
    function disapprovePubKeyZPK (uint256 spender) external responsible returns (uint);
    
    //========================================
    // Transfers
    //========================================
    //
    /// @notice Receives tokens from the RTW. Called by an internal message only.
    ///
    /// @param tokens - number of tokens to receive; 
    //
    function receiveTokensFromRTW(uint128 tokens) external;
    
    /// @notice Called by other TTW contracts to send tokens. Initiated by an internal message only. 
    ///         The function MUST NOT call accept or other buygas primitives.
    ///
    /// @param tokens        - number of tokens to receive;
    /// @param senderPubKey  - sender's TTW public key;    required to check validity of the transfer;
    /// @param senderAddress - sender's TTW owner address; required to check validity of the transfer;
    //
    function receiveTokensFromTTW(uint128 tokens, uint256 senderPubKey, address senderAddress) external;
    
    /// @notice Called by owner of this TTW; sends tokens from this TTW to another TTW;
    ///         ZPK means Zero Public Key, that means an internal message from contract to contract;
    ///
    /// @param tokens       - number of tokens to transfer;
    /// @param grams        - number of nanograms to transfer with internal message;
    ///                       must be enough to pay for gas used by destination wallet;
    /// @param to           - destination token wallet address;
    // 
    function sendTokensProvideAddress   (uint128 tokens, uint128 grams, address to)              external             returns (uint, uint128, uint128, address);
    function sendTokensProvideAddressZPK(uint128 tokens, uint128 grams, address to)              external responsible returns (uint, uint128, uint128, address);
    function sendTokensResolveAddress   (uint128 tokens, uint128 grams, uint256 pubKeyToResolve) external             returns (uint, uint128, uint128, uint256);
    function sendTokensResolveAddressZPK(uint128 tokens, uint128 grams, uint256 pubKeyToResolve) external responsible returns (uint, uint128, uint128, uint256);

    //function sendTokens           (uint128 tokens, uint128 grams, address to, bool notifyCaller) external; 
    //function sendTokensUsingPubKey(uint128 tokens, uint128 grams, uint256 to, bool notifyCaller) external; 

    /// @notice Send tokens from this TTW to another TTW; 
    ///         Called by another contract that has allowance;
    ///         ZPK means Zero Public Key, that means an internal message from contract to contract;
    /// 
    /// @param tokens       - number of tokens to transfer;
    /// @param to           - destination token wallet address;
    //
    function sendMyTokensUsingAllowance   (uint128 tokens, address to) external             returns (uint, uint128, address);
    function sendMyTokensUsingAllowanceZPK(uint128 tokens, address to) external responsible returns (uint, uint128, address);
    
    /// @notice Send tokens from "from" TTW to another TTW; 
    ///         Called by this TTW owner that should have allowance set in "from" TTW;
    ///         ZPK means Zero Public Key, that means an internal message from contract to contract;
    /// 
    /// @param tokens       - number of tokens to transfer;
    /// @param grams        - number of nanograms to transfer with internal message;
    ///                       must be enough to pay for gas used by destination wallet;
    /// @param from         - source TTW that should have allowance for this TTW to perform a transfer;
    /// @param to           - destination token wallet address;
    //
    function sendSomeonesTokensUsingAllowance   (uint128 tokens, uint128 grams, address from, address to) external             returns (uint, uint128, uint128, address, address);
    function sendSomeonesTokensUsingAllowanceZPK(uint128 tokens, uint128 grams, address from, address to) external responsible returns (uint, uint128, uint128, address, address);
} 

//================================================================================
//
