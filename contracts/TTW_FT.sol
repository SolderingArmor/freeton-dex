pragma ton-solidity >= 0.38.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

//================================================================================
// Imports
import "../interfaces/ITTW_FT.sol";

//================================================================================
//
// Ton Token Wallet, Fungible Token
//
contract TonTokenWallet is ITonTokenWallet
{
    //========================================
    // Constants
    address constant addressZero = address.makeAddrStd(0, 0);

    // Error codes
    uint constant MESSAGE_SENDER_IS_NOT_MY_OWNER    = 100;
    uint constant MESSAGE_SENDER_IS_NOT_MY_ROOT     = 101;
    uint constant NOT_ENOUGH_BALANCE                = 102;
    uint constant MESSAGE_SENDER_IS_NOT_GOOD_WALLET = 103;
    uint constant WRONG_BOUNCED_HEADER              = 104;
    uint constant WRONG_BOUNCED_ARGS                = 105;
    uint constant NON_ZERO_REMAINING                = 106;
    uint constant NO_ALLOWANCE_SET                  = 107;
    uint constant WRONG_SPENDER                     = 108;
    uint constant NOT_ENOUGH_ALLOWANCE              = 109;
    uint constant WRONG_CURRENT_ALLOWANCE           = 110;
    uint constant WRONG_DEST_ADDRESS                = 111;

    //========================================
    // Variables
    bytes   static  _name;            //
    bytes   static  _symbol;          //
    uint8   static  _decimals;        //
    uint128 private _balance;         //
    uint256 static  _rootPublicKey;   //
    uint256 static  _walletPublicKey; //
    address static  _rootAddress;     //
    address static  _ownerAddress;    //
    TvmCell static  _code;            //
    int8    private _workchainID;     //

    //========================================
    // Mappings
    mapping(address => uint128) public _allowanceAddresses;
    mapping(uint256 => uint128) public _allowancePubKeys;

    //========================================
    // Modifiers
    function calledByOwnerPubKey()  internal inline view returns (bool) {    return(_ownerAddress == addressZero && _walletPublicKey == msg.pubkey());    }
    function calledByOwnerAddress() internal inline view returns (bool) {    return(_ownerAddress == msg.sender  && _walletPublicKey == 0           );    }

    function calledByRootPubKey()   internal inline view returns (bool) {    return(_rootPublicKey == msg.pubkey()  );    }
    function calledByRootAddress()  internal inline view returns (bool) {    return(_rootAddress == msg.sender      );    }

    modifier onlyOwner {    require(calledByOwnerPubKey() || calledByOwnerAddress(), MESSAGE_SENDER_IS_NOT_MY_OWNER);    _;    }
    modifier onlyRoot  {    require(calledByRootPubKey()  || calledByRootAddress(),  MESSAGE_SENDER_IS_NOT_MY_ROOT );    _;    }

    //========================================
    //========================================
    //========================================
    // Get
    //
    function getName()                         external view override returns (bytes)   {    return _name;                          }
    function getSymbol()                       external view override returns (bytes)   {    return _symbol;                        }
    function getDecimals()                     external view override returns (uint8)   {    return _decimals;                      }
    function getBalance()                      external view override returns (uint128) {    return _balance;                       }
    function getRootKey()                      external view override returns (uint256) {    return _rootPublicKey;                 }
    function getWalletKey()                    external view override returns (uint256) {    return _walletPublicKey;               }
    function getRootAddress()                  external view override returns (address) {    return _rootAddress;                   }
    function getOwnerAddress()                 external view override returns (address) {    return _ownerAddress;                  }
    function getCode()                         external view override returns (TvmCell) {    return _code;                          }
    function allowanceAddress(address spender) external view override returns (uint128) {    return _allowanceAddresses[spender];   }
    function allowancePubKey (uint256 spender) external view override returns (uint128) {    return _allowancePubKeys  [spender];   }

    //========================================
    //
    function calculateFutureAddress(uint256 ownerPubKey, address ownerAddress) private inline view returns (address, TvmCell)
    {
        TvmCell stateInit = tvm.buildStateInit({
            contr: TonTokenWallet,
            varInit: {
                _name:            _name,
                _symbol:          _symbol,
                _decimals:        _decimals,
                _rootPublicKey:   _rootPublicKey,
                _walletPublicKey: ownerPubKey,
                _rootAddress:     _rootAddress,
                _ownerAddress:    ownerAddress,
                _code:            _code
            },
            pubkey: ownerPubKey,
            code:  _code
        });

        return (address(tvm.hash(stateInit)), stateInit);
    }
    
    //========================================
    //========================================
    //========================================
    //
    function destroy(address dest) external override onlyOwner  
    {
        _sendTokens(calledByOwnerAddress(), _balance, 0, dest);
        selfdestruct(dest);
    }

    //========================================
    //========================================
    //========================================
    //
    function _approveAddress(bool zpk, address spender, uint128 curAllowance, uint128 newAllowance) internal returns (uint)
    {
        if( zpk && !calledByOwnerAddress())              {    return MESSAGE_SENDER_IS_NOT_MY_OWNER;    }
        if(!zpk && !calledByOwnerPubKey() )              {    return MESSAGE_SENDER_IS_NOT_MY_OWNER;    }
        if(_allowanceAddresses[spender] != curAllowance) {    return WRONG_CURRENT_ALLOWANCE;           }

        if(!zpk){ tvm.accept(); }
        _allowanceAddresses[spender] = newAllowance;
        return 0;
    }

    function approveAddress(address spender, uint128 curAllowance, uint128 newAllowance) external override returns (uint)
    {
        uint    errorCode = _approveAddress(false, spender, curAllowance, newAllowance);
        require(errorCode == 0, errorCode);
        return  errorCode;
    }

    function approveAddressZPK(address spender, uint128 curAllowance, uint128 newAllowance) external responsible override returns (uint)
    {
        uint errorCode = _approveAddress(true, spender, curAllowance, newAllowance);
        return{value: 0, flag: 64}(errorCode);
    }

    //========================================
    //========================================
    //========================================
    // 
    function _approvePubKey(bool zpk, uint256 spender, uint128 curAllowance, uint128 newAllowance) internal returns (uint)
    {
        if( zpk && !calledByOwnerAddress())            {    return MESSAGE_SENDER_IS_NOT_MY_OWNER;    }
        if(!zpk && !calledByOwnerPubKey() )            {    return MESSAGE_SENDER_IS_NOT_MY_OWNER;    }
        if(_allowancePubKeys[spender] != curAllowance) {    return WRONG_CURRENT_ALLOWANCE;           }

        if(!zpk){ tvm.accept(); }
        _allowancePubKeys[spender] = newAllowance;
        return 0;
    }

    function approvePubKey(uint256 spender, uint128 curAllowance, uint128 newAllowance) external override returns (uint)
    {
        uint    errorCode = _approvePubKey(false, spender, curAllowance, newAllowance);
        require(errorCode == 0, errorCode);
        return  errorCode;
    }

    function approvePubKeyZPK(uint256 spender, uint128 curAllowance, uint128 newAllowance) external responsible override returns (uint)
    {
        uint errorCode = _approvePubKey(true, spender, curAllowance, newAllowance);
        return{value: 0, flag: 64}(errorCode);
    }

    //========================================
    //========================================
    //========================================
    //
    function _disapproveAddress(bool zpk, address spender) internal returns (uint)
    {
        if( zpk && !calledByOwnerAddress()) {    return MESSAGE_SENDER_IS_NOT_MY_OWNER;    }
        if(!zpk && !calledByOwnerPubKey() ) {    return MESSAGE_SENDER_IS_NOT_MY_OWNER;    }

        if(!zpk){ tvm.accept(); }
        delete _allowanceAddresses[spender];
    }
    
    function disapproveAddress(address spender) external override returns (uint)
    {
        uint    errorCode = _disapproveAddress(false, spender);
        require(errorCode == 0, errorCode);
        return  errorCode;
    }

    function disapproveAddressZPK(address spender) external responsible override returns (uint)
    {
        uint errorCode = _disapproveAddress(true, spender);
        return{value: 0, flag: 64}(errorCode);
    }

    //========================================
    //========================================
    //========================================
    // 
    function _disapprovePubKey(bool zpk, uint256 spender) internal returns (uint)
    {
        if( zpk && !calledByOwnerAddress()) {    return MESSAGE_SENDER_IS_NOT_MY_OWNER;    }
        if(!zpk && !calledByOwnerPubKey() ) {    return MESSAGE_SENDER_IS_NOT_MY_OWNER;    }

        if(!zpk){ tvm.accept(); }
        delete _allowancePubKeys[spender];
        return 0;
    }

    function disapprovePubKey(uint256 spender) external override returns (uint)
    {
        uint    errorCode = _disapprovePubKey(false, spender);
        require(errorCode == 0, errorCode);
        return  errorCode;
    }

    function disapprovePubKeyZPK(uint256 spender) external responsible override returns (uint)
    {
        uint errorCode = _disapprovePubKey(true, spender);
        return{value: 0, flag: 64}(errorCode);
    }
    
    //========================================
    //========================================
    //========================================
    //
    function receiveTokensFromRTW(uint128 tokens) external override onlyRoot  
    {
        tvm.accept();
        _balance += tokens;
    }

    //========================================
    //
    function receiveTokensFromTTW(uint128 tokens, uint256 senderPubKey, address senderAddress) external override 
    {
        (address desiredAddress, ) = calculateFutureAddress(senderPubKey, senderAddress);
        require(msg.sender == desiredAddress, MESSAGE_SENDER_IS_NOT_GOOD_WALLET);

        tvm.accept();
        _balance += tokens;
    }

    //========================================
    //========================================
    //========================================
    //
    function _sendTokens(bool zpk, uint128 tokens, uint128 grams, address to) internal returns (uint)
    {
        if( zpk && !calledByOwnerAddress()) {    return MESSAGE_SENDER_IS_NOT_MY_OWNER;    }
        if(!zpk && !calledByOwnerPubKey() ) {    return MESSAGE_SENDER_IS_NOT_MY_OWNER;    }
        if(_balance < tokens              ) {    return NOT_ENOUGH_BALANCE;                }
        if(to == addressZero              ) {    return WRONG_DEST_ADDRESS;                }

        if(!zpk){ tvm.accept(); }
        ITonTokenWallet(to).receiveTokensFromTTW{value: grams}(tokens, _walletPublicKey, _ownerAddress);
        _balance -= tokens;
        return 0;
    }

    function sendTokensProvideAddress(uint128 tokens, uint128 grams, address to) external override returns (uint, uint128, uint128, address)
    {
        uint    errorCode = _sendTokens(false, tokens, grams, to);
        require(errorCode == 0, errorCode);
        return (errorCode, tokens, grams, to);
    }

    function sendTokensProvideAddressZPK(uint128 tokens, uint128 grams, address to) external responsible override returns (uint, uint128, uint128, address)
    {
        uint errorCode = _sendTokens(true, tokens, grams, to);
        return{value: 0, flag: 64}(errorCode, tokens, grams, to);
    }

    //========================================
    //
    function sendTokensResolveAddress(uint128 tokens, uint128 grams, uint256 pubKeyToResolve) external override returns (uint, uint128, uint128, uint256)
    {
        (address desiredAddress, ) = calculateFutureAddress(pubKeyToResolve, addressZero);
        uint errorCode = _sendTokens(false, tokens, grams, desiredAddress);
        require(errorCode == 0, errorCode);
        return (errorCode, tokens, grams, pubKeyToResolve);
    }

    function sendTokensResolveAddressZPK(uint128 tokens, uint128 grams, uint256 pubKeyToResolve) external responsible override returns (uint, uint128, uint128, uint256)
    {
        (address desiredAddress, ) = calculateFutureAddress(pubKeyToResolve, addressZero);
        uint errorCode = _sendTokens(true, tokens, grams, desiredAddress);
        return{value: 0, flag: 64}(errorCode, tokens, grams, pubKeyToResolve);
    }

    //========================================
    //========================================
    //========================================
    //
    function _sendMyTokensUsingAllowance(bool zpk, uint128 tokens, address to) internal returns (uint)
    {
        if(msg.sender   != addressZero && _allowanceAddresses[msg.sender] < tokens) {    return NOT_ENOUGH_ALLOWANCE;    }
        if(msg.pubkey() != 0           && _allowancePubKeys[msg.pubkey()] < tokens) {    return NOT_ENOUGH_ALLOWANCE;    }
        if(tokens > _balance)                                                       {    return NOT_ENOUGH_BALANCE;      }

        if(!zpk){ tvm.accept(); }
        _balance -= tokens;
        if(msg.sender != addressZero) {    _allowanceAddresses[msg.sender  ] -= tokens;    } // one or the other
        else                          {    _allowancePubKeys  [msg.pubkey()] -= tokens;    } // one or the other  

        ITonTokenWallet(to).receiveTokensFromTTW(tokens, _walletPublicKey, _ownerAddress);
        return 0;
    }

    function sendMyTokensUsingAllowance(uint128 tokens, address to) external override returns (uint, uint128, address)
    {
        uint errorCode = _sendMyTokensUsingAllowance(false, tokens, to);
        require(errorCode == 0, errorCode);
        return (errorCode, tokens, to);
    }

    function sendMyTokensUsingAllowanceZPK(uint128 tokens, address to) external responsible override returns (uint, uint128, address)
    {
        uint errorCode = _sendMyTokensUsingAllowance(true, tokens, to);
        return{value: 0, flag: 64}(errorCode, tokens, to);
    }


    //========================================
    //========================================
    //========================================
    //
    function _sendSomeonesTokensUsingAllowance(bool zpk, uint128 tokens, uint128 grams, address from, address to) internal returns (uint)
    {
        if( zpk && !calledByOwnerAddress()) {    return MESSAGE_SENDER_IS_NOT_MY_OWNER;    }
        if(!zpk && !calledByOwnerPubKey() ) {    return MESSAGE_SENDER_IS_NOT_MY_OWNER;    }
        if(to == addressZero)               {    return WRONG_DEST_ADDRESS;                }

        if(!zpk){ tvm.accept(); }
        ITonTokenWallet(from).sendMyTokensUsingAllowance{value: grams}(tokens, to);
        return 0;
    }

    function sendSomeonesTokensUsingAllowance(uint128 tokens, uint128 grams, address from, address to) external override returns (uint, uint128, uint128, address, address)
    {
        uint    errorCode = _sendSomeonesTokensUsingAllowance(false, tokens, grams, from, to);
        require(errorCode == 0, errorCode);
        return (errorCode, tokens, grams, from, to);
    }

    function sendSomeonesTokensUsingAllowanceZPK(uint128 tokens, uint128 grams, address from, address to) external responsible override returns (uint, uint128, uint128, address, address)
    {
        uint errorCode = _sendSomeonesTokensUsingAllowance(false, tokens, grams, from, to);
        return{value: 0, flag: 64}(errorCode, tokens, grams, from, to);
    }
}

//================================================================================
//
