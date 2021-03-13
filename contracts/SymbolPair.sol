pragma ton-solidity >= 0.38.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

//================================================================================
//
import "../interfaces/ISymbolPair.sol";
import "../interfaces/IDexFactory.sol";
import "../interfaces/IRTW_FT.sol";
import "../interfaces/ITTW_FT.sol";

//================================================================================
//
contract SymbolPair is ISymbolPair//, IRootTokenWallet_DeployEmptyWallet
{
    // Constants
    address constant addressZero      = address.makeAddrNone(); // 
    uint256 constant minimumLiquidity = 10^3;                   //
    uint256 public   _totalLiquidity  = 0; // here it's the sum of all user liquidities, times 10**_localDecimals
    
    // Errors
    uint constant ERROR_SENDER_IS_NOT_MY_FACTORY            = 200;
    uint constant ERROR_SYMBOLS_SHOULD_BE_DIFFERENT         = 201;
    uint constant ERROR_SYMBOLS_SHOULD_HAVE_VALID_ADDRESSES = 202;
    uint constant ERROR_SYMBOL_MISSING                      = 203;
    
    // Variables   
    address public static _factoryAddress; //  
    Symbol  public static _symbol1;
    Symbol  public static _symbol2; 

    bool    public  _feeIsCustom   = false; // Custom fee for this Symbol Pair; when Factory changes the fee and this is "false", custom value stays intact;
    uint16  public  _currentFee    = 30;    // Current fee for Liquidity Providers to earn; Default 0.3%;  
    uint8   private _localDecimals = 18;  

    //========================================
    // Events

    //========================================
    // Modifiers
    modifier onlyFactory
    {
        // disabled for testing
        //require(msg.sender == _factoryAddress, ERROR_SENDER_IS_NOT_MY_FACTORY);
        _;
    }

    //========================================
    // Mappings
    mapping(uint256 => uint256)      _userLiquidity;   // (PubKey => LiquidityTokens number) mapping, amount that was provided by users;
    mapping(uint256 => StateMachine) _depositStatuses; // Action 0: deposit symbol1 (is filled out after 1st callback)
                                                       // Action 1: deposit symbol2 (is filled out after 2nd callback)
                                                       // Action 2: check the ratio and fulfill the order (is filled out after 2nd callback + Action 1)
                                                       // when there's an error - rollback everything;
    mapping(uint256 => StateMachine) _swapStatuses;    // Action 0: receive symbol from the TTW (is filled out after 1st callback)
                                                       // Action 1: check the ratio and fulfill the order (is filled out after 1st callback + Action 0)
                                                       // Action 2: [empty]
                                                       // when there's an error - rollback everything;

    //========================================
    //
    /// @dev TODO: here "external" was purposely changed to "public", otherwise you get the following error:
    ///      Error: Undeclared identifier. "callbackDeployEmptyWallet" is not (or not yet) visible at this point.
    ///      The fix is coming: https://github.com/tonlabs/TON-Solidity-Compiler/issues/36
    function callbackDeployEmptyWallet(address newWalletAddress, uint128 grams, uint256 walletPublicKey, address ownerAddress) public override
    {
        require(msg.sender == _symbol1.symbolRTW || msg.sender == _symbol2.symbolRTW, 5555);
        tvm.accept();

        if(msg.sender == _symbol1.symbolRTW) {    _symbol1.symbolTTW = newWalletAddress;    return;    }
        if(msg.sender == _symbol2.symbolRTW) {    _symbol2.symbolTTW = newWalletAddress;    return;    } 
    }

    constructor() public onlyFactory
    {        
        tvm.accept();
        if(_symbol1.symbolType == SymbolType.Tip3){    IRootTokenWallet(_symbol1.symbolRTW).deployEmptyWalletZPK{value: 2 ton, callback: SymbolPair.callbackDeployEmptyWallet}(2 ton, 0, address(this));    }
        if(_symbol2.symbolType == SymbolType.Tip3){    IRootTokenWallet(_symbol2.symbolRTW).deployEmptyWalletZPK{value: 2 ton, callback: SymbolPair.callbackDeployEmptyWallet}(2 ton, 0, address(this));    }
        
    }
    
    //========================================
    //
    function setProviderFee(uint16 fee) external override onlyFactory
    {
        tvm.accept();
        _currentFee  = fee;
    }

    //========================================
    //
    function setCustomProviderFee(bool isCustom, uint16 fee) external override onlyFactory
    {
        tvm.accept();
        _feeIsCustom = isCustom;
        _currentFee  = fee;
    }
    
    //========================================
    // 
    function getPairRatio(bool firstFirst) external view override returns (uint256, uint8)
    {
        Symbol symbol1 = firstFirst ? _symbol1 : _symbol2;
        Symbol symbol2 = firstFirst ? _symbol2 : _symbol1;

        uint256 ratio    = symbol1.amount;
        uint8   decimals = 0;

        // Empty
        if(symbol1.amount == 0 || symbol2.amount == 0)
        {
            return (0, 0);
        }

        if(symbol1.decimals >= symbol2.decimals)
        {
            decimals = _localDecimals - (symbol1.decimals - symbol2.decimals);
        }
        else 
        {
            decimals = _localDecimals + (symbol2.decimals - symbol1.decimals);
        }

        ratio *= (10^decimals);
        ratio /= symbol2.amount;

        return (ratio, decimals);
    }

    //========================================
    //
    function depositLiquidity(uint128 amount1, uint128 amount2) external override
    {
        (uint256 ratio, uint8 decimals) = getPairRatio();
        if(ratio == 0)
        {

        }
        else
        {
            
        }
    }

    //========================================
    //
    function withdrawLiquidity(uint128 amountLiquidity, address crystalWalletAddress) external override 
    {
        require(msg.sender == addressZero,                       5555);
        require(amountLiquidity > 0,                             5555);
        require(_userLiquidity[msg.pubkey()] >= amountLiquidity, 5555);

        tvm.accept();

        // OUR _totalLiquidity       has _localDecimals precision
        //     _userLiquidity[] also has _localDecimals precision
        // We purposely multiply all the values by 10^9 to have better precision when dividing to get ratio;
        // About every Symbol custom precision - we do not need to care about it;

        uint8 decimals = 9;
        uint256 ratio = (_totalLiquidity * 10^decimals) / amountLiquidity;
        uint256 amountSymbol1 = (_symbol1.amount * 10^decimals) / ratio;    amountSymbol1 /= 10^decimals; // no need for extra precision anymore;
                
        uint256 amountSymbol2 = (_symbol2.amount * 10^decimals) / ratio;    amountSymbol2 /= 10^decimals; // no need for extra precision anymore;

        // Symbol1
        //if(_symbol1.symbolType == SymbolType.TonCrystal) {    crystalWalletAddress.transfer(uint128(amountSymbol1), true, 0);    } // TODO: revisit flag 0
        //if(_symbol1.symbolType == SymbolType.Tip3)       {    ITonTokenWallet(_symbol1.symbolTTW).sendTokensResolveAddressZPK{value: 1 ton, callback: 000}(uint128(amountSymbol1), 1, msg.pubkey());  }
        //if(_symbol1.symbolType == SymbolType.Erc20)      { } // CURENTLY NOT IMPLEMENTED

        // Symbol2
        //if(_symbol2.symbolType == SymbolType.TonCrystal) {    crystalWalletAddress.transfer(uint128(amountSymbol2), true, 0);    } // TODO: revisit flag 0
        //if(_symbol2.symbolType == SymbolType.Tip3)       {    ITonTokenWallet(_symbol2.symbolTTW).sendTokensResolveAddressZPK{value: 1 ton, callback: 000}(uint128(amountSymbol1), 1, msg.pubkey());  }
        //if(_symbol2.symbolType == SymbolType.Erc20)      { } // CURENTLY NOT IMPLEMENTED

        _totalLiquidity              -= amountLiquidity;
        _userLiquidity[msg.pubkey()] -= amountLiquidity;

    }

    //========================================
    /// @dev TODO: here "external" was purposely changed to "public", otherwise you get the following error:
    ///      Error: Undeclared identifier. "getPairLiquidity" is not (or not yet) visible at this point.
    ///      The fix is coming: https://github.com/tonlabs/TON-Solidity-Compiler/issues/36
    function getPairLiquidity() public view override returns (uint256, uint8) 
    {
        uint256 amount  = _symbol1.amount   * _symbol2.amount;
        uint8  decimals = _symbol1.decimals + _symbol2.decimals;
        return (amount, decimals);
    }

    //========================================
    //
    function getUserLiquidity(uint256 ownerPubKey) external view override returns (uint256, uint8) 
    {
        // TODO: decimals?
        return (_userLiquidity[ownerPubKey], _localDecimals);
    }

    //========================================
    //
    function getPriceInternal(uint256 inputAmount, uint256 inputReserve, uint256 outputReserve) private view returns (uint256) 
    {
        // TODO: decimals?
        uint256 inputAmountWithFee = inputAmount        * (10000 - _currentFee);
        uint256 numerator          = inputAmountWithFee * outputReserve;
        uint256 denominator        = inputReserve       * 10000 + inputAmountWithFee;
        return numerator / denominator;
    }

    //========================================
    //
    function getPrice(address RTW_ofTokenToGet, address RTW_ofTokenToGive, uint128 amountToGive) external view override returns (uint256, uint8) 
    {
        require(RTW_ofTokenToGet != RTW_ofTokenToGive,                                              ERROR_SYMBOLS_SHOULD_BE_DIFFERENT        );
        require(RTW_ofTokenToGet != addressZero || RTW_ofTokenToGive != addressZero,                ERROR_SYMBOLS_SHOULD_HAVE_VALID_ADDRESSES);
        require(RTW_ofTokenToGet  == _symbol1.symbolRTW || RTW_ofTokenToGet  == _symbol2.symbolRTW, ERROR_SYMBOL_MISSING                     );
        require(RTW_ofTokenToGive == _symbol1.symbolRTW || RTW_ofTokenToGive == _symbol2.symbolRTW, ERROR_SYMBOL_MISSING                     );

        Symbol symbolGet  = RTW_ofTokenToGet  == _symbol1.symbolRTW ? _symbol1 : _symbol2; // 
        Symbol symbolGive = RTW_ofTokenToGive == _symbol1.symbolRTW ? _symbol1 : _symbol2; // 

        uint256 tokenReserve = symbolGet.amount;
        uint256 tokensToBuy = getPriceInternal(amountToGive, tokenReserve, symbolGive.amount);

        uint8 decimals = 0;
        if(symbolGet.decimals >= symbolGive.decimals)
        {
            decimals = symbolGet.decimals - symbolGive.decimals;
        }
        else 
        {
            uint8 pow = symbolGive.decimals - symbolGet.decimals;
            tokensToBuy = tokensToBuy * (10^pow);
        }

        return (tokensToBuy, decimals);
    }

    //========================================
    //
    function swapTokens(address tokenToGet, address tokenToGive, uint256 owner) external override
    {
        (uint256 liquidity, uint8 decimals) = getPairLiquidity();
        require(minimumLiquidity * 10^decimals < liquidity, 111);

        // TODO
    }
}

//================================================================================
//