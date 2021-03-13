pragma ton-solidity >= 0.38.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

//================================================================================
//
import "../interfaces/IRTW_FT.sol";
import "../interfaces/IDexFactory.sol";
import "../interfaces/ISymbolPair.sol";
import "SymbolPair.sol";

//================================================================================
//
contract DexFactory is IDexFactory
{    
    // Constants
    address constant addressZero = address.makeAddrStd(0, 0);
    
    // Errors
    uint constant ERROR_MESSAGE_SENDER_IS_NOT_MY_OWNER        = 100;
    uint constant ERROR_CANT_DISABLE_OWNER_WITHOUT_GOVERNANCE = 101;
    uint constant ERROR_GOVERNANCE_ADDRESS_CANT_BE_EMPTY      = 102;
    uint constant ERROR_SYMBOL_ALREADY_EXISTS                 = 103;
    uint constant ERROR_SYMBOL_DOES_NOT_EXIST                 = 104;
    uint constant ERROR_PAIR_DOES_NOT_EXIST                   = 105;
    uint constant ERROR_SYMBOLS_CANT_BE_THE_SAME              = 106;

    // Variables   
    uint256 public _ownerPubKey;           // DEX owner PubKey;
    bool    public _ownerDisabled = false; //
    address public _governanceAddress;     // Governance address;
    uint16  public _currentFee = 30;       // Current fee for Liquidity Providers to earn; Default 0.3%;

    TvmCell public static _symbolPairCode; // SymbolPair contract code;

    //========================================
    // Mappings
    mapping(address => Symbol) _listSymbols;
    mapping(address => Symbol) _listSymbolsAwaitingVerification;
    address[]                  _listPairs;

    //========================================
    // Events

    //========================================
    // Modifiers
    modifier onlyOwner   
    {
        bool isGovernance = (_governanceAddress != addressZero && msg.sender  == _governanceAddress);
        bool isOwner      = (_ownerDisabled     == false       && _ownerPubKey != 0 && msg.pubkey() == _ownerPubKey);
        
        require(isGovernance || isOwner, ERROR_MESSAGE_SENDER_IS_NOT_MY_OWNER);
        _;   
    }

    //========================================
    // Inline functions
    function _sortAddresses(address addr1, address addr2) internal inline view returns (address, address)
    {
        return (addr1 < addr2 ? (addr1, addr2) : (addr2, addr1));
    }

    //========================================
    // Callbacks
    /// @dev TODO: here "external" was purposely changed to "public", otherwise you get the following error:
    ///      Error: Undeclared identifier. "callback_VerifyTokenDetails" is not (or not yet) visible at this point.
    ///      The fix is coming: https://github.com/tonlabs/TON-Solidity-Compiler/issues/36
    function callback_VerifyTokenDetails(bytes name, bytes symbol, uint8 decimals) public override
    {
        require(_listSymbolsAwaitingVerification[msg.sender].symbolRTW == msg.sender, 5555);
        
        tvm.accept();
        _listSymbolsAwaitingVerification[msg.sender].name     = name;
        _listSymbolsAwaitingVerification[msg.sender].symbol   = symbol;
        _listSymbolsAwaitingVerification[msg.sender].decimals = decimals;

        _listSymbols[msg.sender] = _listSymbolsAwaitingVerification[msg.sender];
        delete _listSymbolsAwaitingVerification[msg.sender];
    }

    //========================================
    // 
    constructor(uint256 ownerPubKey) public
    {
        tvm.accept();
        _ownerPubKey = ownerPubKey;
        
        // Adding Symbol 0 - TON Crystal:
        _listSymbols[addressZero].symbolType = SymbolType.TonCrystal;
        _listSymbols[addressZero].symbolRTW  = addressZero;
        _listSymbols[addressZero].symbolTTW  = addressZero;
        _listSymbols[addressZero].name       = "TON Crystal";
        _listSymbols[addressZero].symbol     = "TON";
        _listSymbols[addressZero].decimals   = 9;
        _listSymbols[addressZero].amount     = 0;
    }

    //========================================
    //
    function calculatePairFutureAddress(address symbol1RTW, address symbol2RTW) private inline view returns (address, TvmCell)
    {
        (address symbol1, address symbol2) = _sortAddresses(symbol1RTW, symbol2RTW);
        
        TvmCell stateInit = tvm.buildStateInit({
            contr: SymbolPair,
            varInit: {
                _factoryAddress: address(this),
                _symbol1:        _listSymbols[symbol1],
                _symbol2:        _listSymbols[symbol2]
            },
            code: _symbolPairCode
        });

        return (address(tvm.hash(stateInit)), stateInit);
    }

    //========================================
    // 
    function setOwner(uint256 newOwner) external override onlyOwner 
    {
        require(newOwner != 0, 111);
        
        tvm.accept();
        _ownerPubKey = newOwner;
    }

    //========================================
    //
    function disableOwner() external override onlyOwner 
    {
        require(_governanceAddress != addressZero, ERROR_CANT_DISABLE_OWNER_WITHOUT_GOVERNANCE);
        
        tvm.accept();
        _ownerPubKey   = 0;
        _ownerDisabled = true;
    }

    //========================================
    //
    function setGovernance(address newGovernance) external override onlyOwner 
    {
        require(newGovernance != addressZero, ERROR_GOVERNANCE_ADDRESS_CANT_BE_EMPTY);
        
        tvm.accept();
        _governanceAddress = newGovernance;
    }

    //========================================
    /// @dev TODO: here "external" was purposely changed to "public", otherwise you get the following error:
    ///      Error: Undeclared identifier. "addSymbol" is not (or not yet) visible at this point.
    ///      The fix is coming: https://github.com/tonlabs/TON-Solidity-Compiler/issues/36
    function addSymbol(address symbolAddressRTW, SymbolType symbolType) public override onlyOwner
    {
        require(SymbolExists(symbolAddressRTW) == false, ERROR_SYMBOL_ALREADY_EXISTS);
        
        tvm.accept();

        _listSymbolsAwaitingVerification[symbolAddressRTW].symbolType = symbolType;
        _listSymbolsAwaitingVerification[symbolAddressRTW].symbolRTW  = symbolAddressRTW;
        _listSymbolsAwaitingVerification[symbolAddressRTW].symbolTTW  = addressZero;
        _listSymbolsAwaitingVerification[symbolAddressRTW].amount     = 0;

        if(symbolType == SymbolType.Tip3)
        {
            IRootTokenWallet(symbolAddressRTW).getTokenDetailsZPK{value: 1 ton, callback: callback_VerifyTokenDetails}(); // Populate the details and mark as verified;
            
        }

        if(symbolType == SymbolType.Erc20)
        {
            // NOT IMPLEMENTED
        }
    }

    //========================================
    //
    function addPair(address symbol1RTW, address symbol2RTW) external override
    {
        // DEV NOTE: for simplicity of the 1st stage of DEX, DexFactory sends 2 TON to every Pair from its own reserves;
        //           this behavior is only for simplicity and DEX proof-of-concept, it shouldn't be like this in a final version;
        //
        require(symbol1RTW != symbol2RTW,                       ERROR_SYMBOLS_CANT_BE_THE_SAME);
        require(SymbolExists(symbol1RTW) == true,               ERROR_SYMBOL_DOES_NOT_EXIST   );
        require(SymbolExists(symbol2RTW) == true,               ERROR_SYMBOL_DOES_NOT_EXIST   );
        require(getPair(symbol1RTW, symbol2RTW) == addressZero, ERROR_PAIR_DOES_NOT_EXIST     );

        tvm.accept();

        (address symbol1, address symbol2) = _sortAddresses(symbol1RTW, symbol2RTW);
        
        (address desierdAddress, TvmCell stateInit) = calculatePairFutureAddress(symbol1RTW, symbol2RTW);
        address newPair = new SymbolPair{stateInit: stateInit, value: 2 ton}();
        _listPairs.push(desierdAddress);
    }

    //========================================
    //
    function setProviderFee(uint16 fee) external override onlyOwner
    {
        tvm.accept();

        _currentFee = fee;
        for (address addr : _listPairs) 
        {
            ISymbolPair(addr).setProviderFee(fee);
        }
    }

    //========================================
    //
    function setProviderFeeCustom(address symbol1RTW, address symbol2RTW, bool isCustom, uint16 fee) external override onlyOwner
    {
        tvm.accept();

        (address desierdAddress, ) = calculatePairFutureAddress(symbol1RTW, symbol2RTW);
        uint16 newFee = (isCustom ? fee : _currentFee);
        ISymbolPair(desierdAddress).setCustomProviderFee(isCustom, newFee);
    }

    //========================================
    //
    function getProviderFee() external view override returns (uint128)
    {
        return _currentFee;
    }

    //========================================
    /// @dev TODO: here "external" was purposely changed to "public", otherwise you get the following error:
    ///      Error: Undeclared identifier. "symbolExists" is not (or not yet) visible at this point.
    ///      The fix is coming: https://github.com/tonlabs/TON-Solidity-Compiler/issues/36/
    function SymbolExists(address symbolRTW) public view override returns (bool)
    {
        if(symbolRTW == addressZero || _listSymbols[symbolRTW].symbolRTW != addressZero)
        {
            return true;
        }

        return false;
    }

    //========================================
    /// @dev TODO: here "external" was purposely changed to "public", otherwise you get the following error:
    ///      Error: Undeclared identifier. "getPair" is not (or not yet) visible at this point.
    ///      The fix is coming: https://github.com/tonlabs/TON-Solidity-Compiler/issues/36
    function getPair(address symbol1RTW, address symbol2RTW) public view override returns (address)
    {
        // TODO:        
        (address desierdAddress, ) = calculatePairFutureAddress(symbol1RTW, symbol2RTW);
        for (address addr : _listPairs) 
        {
            if(addr == desierdAddress)
            {
                return addr;   
            }
        }

        return addressZero;
    }

    function getAllPairs() external view override returns (address[])
    {
        return _listPairs;
    }
}

//================================================================================
//