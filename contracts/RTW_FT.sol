pragma ton-solidity >= 0.38.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

//================================================================================
// Imports
import "../interfaces/IRTW_FT.sol";
import "../interfaces/ITTW_FT.sol";
import "TTW_FT.sol";

//================================================================================
//
contract RootTokenWallet is IRootTokenWallet
{
    //========================================
    // Constants
    address constant addressZero = address.makeAddrStd(0, 0);

    // Error codes
    uint constant MESSAGE_SENDER_IS_NOT_MY_OWNER    = 100;
    uint constant NOT_ENOUGH_BALANCE                = 101;
    uint constant MESSAGE_SENDER_IS_NOT_GOOD_WALLET = 103;
    uint constant WRONG_DEST_ADDRESS                = 111;

    //========================================
    // Variables
    bytes   static  _name;            //
    bytes   static  _symbol;          //
    uint8   static  _decimals;        //
    uint128 private _totalSupply;     //
    uint256 static  _rootPublicKey;   //
    address static  _rootOwnerAddress;//
    TvmCell static  _code;            //
    int8    private _workchainID;     //

    //========================================
    // Modifiers
    function calledByOwnerPubKey()  internal inline view returns (bool) {    return(_rootOwnerAddress == addressZero && _rootPublicKey == msg.pubkey());    }
    function calledByOwnerAddress() internal inline view returns (bool) {    return(_rootOwnerAddress == msg.sender  && _rootPublicKey == 0           );    }

    modifier onlyOwner {    require(calledByOwnerPubKey() || calledByOwnerAddress(), MESSAGE_SENDER_IS_NOT_MY_OWNER);    _;    }

    //========================================
    //========================================
    // Get
    //========================================
    //
    function getName()             external view override returns (bytes)   {    return _name;                }
    function getSymbol()           external view override returns (bytes)   {    return _symbol;              }
    function getDecimals()         external view override returns (uint8)   {    return _decimals;            }
    function getTotalSupply()      external view override returns (uint128) {    return _totalSupply;         }
    function getRootPublicKey()    external view override returns (uint256) {    return _rootPublicKey;       }
    function getRootOwnerAddress() external view override returns (address) {    return _rootOwnerAddress;    }
    function getCode()             external view override returns (TvmCell) {    return _code;                }

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
                _walletPublicKey: ownerPubKey,
                _rootAddress:     address(this),
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
    function getWalletAddress(uint256 walletPublicKey, address ownerAddress) external view override returns (address, uint256, address)
    {
        (address desiredAddress, ) = calculateFutureAddress(walletPublicKey, ownerAddress);
        return (desiredAddress, walletPublicKey, ownerAddress);
    }

    function getWalletAddressZPK(uint256 walletPublicKey, address ownerAddress) external view responsible override returns (address, uint256, address)
    {
        (address desiredAddress, ) = calculateFutureAddress(walletPublicKey, ownerAddress);
        return{value: 0, flag: 64}(desiredAddress, walletPublicKey, ownerAddress);
    }

    //========================================
    //========================================
    //========================================
    //
    function getTokenDetails() external override returns (bytes, bytes, uint8)
    {
        // TODO:
        //IRootTokenWallet_VerifyTokenDetails(msg.sender).callback_VerifyTokenDetails(_name, _symbol, _decimals);
        return (_name, _symbol, _decimals);
    }

    function getTokenDetailsZPK() external responsible override returns (bytes, bytes, uint8)
    {
        return{value: 0, flag: 64}(_name, _symbol, _decimals);
    }

    //========================================
    //========================================
    //========================================
    //
    function _deployWallet(bool zpk, uint128 tokens, uint128 grams, uint256 walletPublicKey, address ownerAddress) internal returns (uint, address)
    {
        if( zpk && !calledByOwnerAddress()) {    return (MESSAGE_SENDER_IS_NOT_MY_OWNER, addressZero);    }
        if(!zpk && !calledByOwnerPubKey() ) {    return (MESSAGE_SENDER_IS_NOT_MY_OWNER, addressZero);    }
        if(walletPublicKey == 0 && ownerAddress == addressZero){    return (5555, addressZero);    } // both zero
        if(walletPublicKey != 0 && ownerAddress != addressZero){    return (5555, addressZero);    } // something should be zero        
    
        if(!zpk){ tvm.accept(); }
        (address desiredAddress, TvmCell stateInit) = calculateFutureAddress(walletPublicKey, ownerAddress);
        address newTTW = new TonTokenWallet{stateInit: stateInit, value: grams}();
        _mint(zpk, tokens, desiredAddress);
        return (0, desiredAddress);
    }

    function _deployEmptyWallet(bool zpk, uint128 grams, uint256 walletPublicKey, address ownerAddress) internal returns (uint, address)
    {
        if(walletPublicKey == 0 && ownerAddress == addressZero){    return (5555, addressZero);    } // both zero
        if(walletPublicKey != 0 && ownerAddress != addressZero){    return (5555, addressZero);    } // something should be zero
        
        if(!zpk){ tvm.accept(); }
        (address desiredAddress, TvmCell stateInit) = calculateFutureAddress(walletPublicKey, ownerAddress);
        address newTTW = new TonTokenWallet{stateInit: stateInit, value: grams}();
        return (0, desiredAddress);
    }

    //========================================
    //
   function deployWallet(uint128 tokens, uint128 grams, uint256 walletPublicKey, address ownerAddress) external override returns (address, uint128, uint128, uint256, address)
    {
        (uint errorCode, address addr) = _deployWallet(false, tokens, grams, walletPublicKey, ownerAddress);
        require(errorCode == 0, errorCode);
        return (addr, tokens, grams, walletPublicKey, ownerAddress);
    }

    function deployWalletZPK(uint128 tokens, uint128 grams, uint256 walletPublicKey, address ownerAddress) external responsible override returns (address, uint128, uint128, uint256, address)
    {
        (uint errorCode, address addr) = _deployWallet(true, tokens, grams, walletPublicKey, ownerAddress);
        return{value: 0, flag: 64}(addr, tokens, grams, walletPublicKey, ownerAddress);
    }

    //========================================
    //
   function deployEmptyWallet(uint128 grams, uint256 walletPublicKey, address ownerAddress) external override returns (address, uint128, uint256, address)
    {
        (uint errorCode, address addr) = _deployEmptyWallet(false, grams, walletPublicKey, ownerAddress);
        require(errorCode == 0, errorCode);
        return (addr, grams, walletPublicKey, ownerAddress);
    }

    function deployEmptyWalletZPK(uint128 grams, uint256 walletPublicKey, address ownerAddress) external responsible override returns (address, uint128, uint256, address)
    {
        (uint errorCode, address addr) = _deployEmptyWallet(true, grams, walletPublicKey, ownerAddress);
        return{value: 0, flag: 64}(addr, grams, walletPublicKey, ownerAddress);
    }
    
    //========================================
    //========================================
    //========================================
    //
    function _mint(bool zpk, uint128 tokens, address to) internal returns (uint)
    {
        if( zpk && !calledByOwnerAddress()) {    return MESSAGE_SENDER_IS_NOT_MY_OWNER;    }
        if(!zpk && !calledByOwnerPubKey() ) {    return MESSAGE_SENDER_IS_NOT_MY_OWNER;    }
        if(to == addressZero)               {    return WRONG_DEST_ADDRESS;                }
        if(tokens == 0)                     {    return 0;                                 }

        if(!zpk){ tvm.accept(); }
        _totalSupply += tokens;
        ITonTokenWallet(to).receiveTokensFromRTW(tokens);
        return 0;
    }

    function mint(uint128 tokens, address to) external override returns (uint, uint128, address)
    {
        uint    errorCode = _mint(false, tokens, to);
        require(errorCode == 0, errorCode);
        return (errorCode, tokens, to);
    }

    function mintZPK(uint128 tokens, address to) external responsible override returns (uint, uint128, address)
    {
        uint errorCode = _mint(false, tokens, to);
        return{value: 0, flag: 64}(errorCode, tokens, to);
    }

    //========================================
    //========================================
    //========================================
    //
    onBounce(TvmSlice slice) external 
    {
        tvm.accept();
        uint funcID = slice.decode(uint32);
        if(funcID == tvm.functionId(ITonTokenWallet.receiveTokensFromRTW)) 
        {
            uint128 tokens = slice.decode(uint128);
            _totalSupply -= tokens;
        }
    }
    
    //========================================
    //
}

//================================================================================
//
