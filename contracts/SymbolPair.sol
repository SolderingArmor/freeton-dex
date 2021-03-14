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
    uint256 constant minimumLiquidity = 10**3;                  //
    uint256 public  _totalLiquidity   = 0; // here it's the sum of all user liquidities, times 10**_localDecimals
    
    // Errors
    uint constant ERROR_SENDER_IS_NOT_MY_FACTORY            = 200;
    uint constant ERROR_SYMBOLS_SHOULD_BE_DIFFERENT         = 201;
    uint constant ERROR_SYMBOLS_SHOULD_HAVE_VALID_ADDRESSES = 202;
    uint constant ERROR_SYMBOL_MISSING                      = 203;
    uint constant ERROR_EMPTY_PUBKEY                        = 204;
    uint constant ERROR_SENDER_IS_NOT_RTW                   = 205;
    uint constant ERROR_CAN_NOT_WITHDRAW_0_LIQUIDITY        = 206;
    uint constant ERROR_NOT_ENOUGH_LIQUIDITY                = 207;
    
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
        require(msg.sender == _factoryAddress, ERROR_SENDER_IS_NOT_MY_FACTORY);
        _;
    }

    //========================================
    // Mappings
    mapping(uint256 => uint256)               _userLiquidity;           // (PubKey => LiquidityTokens number) mapping, amount that was provided by users;
    mapping(uint256 => manageLiquidityStatus) _depositLiquidityStatus;  //
    mapping(uint256 => manageLiquidityStatus) _withdrawLiquidityStatus; //
    mapping(uint256 => swapTokenStatus)       _swapTokenStatus;         //
    
    //========================================
    //
    /// @dev TODO: here "external" was purposely changed to "public", otherwise you get the following error:
    ///      Error: Undeclared identifier. "callbackDeployEmptyWallet" is not (or not yet) visible at this point.
    ///      The fix is coming: https://github.com/tonlabs/TON-Solidity-Compiler/issues/36
    function callbackDeployEmptyWallet(address newWalletAddress, uint128 grams, uint256 walletPublicKey, address ownerAddress) public override
    {
        require(msg.sender == _symbol1.symbolRTW || msg.sender == _symbol2.symbolRTW, ERROR_SENDER_IS_NOT_RTW);
        tvm.accept();

        if(msg.sender == _symbol1.symbolRTW) {    _symbol1.symbolTTW = newWalletAddress;    return;    }
        if(msg.sender == _symbol2.symbolRTW) {    _symbol2.symbolTTW = newWalletAddress;    return;    } 
    }

    /// @dev TODO: here "external" was purposely changed to "public", otherwise you get the following error:
    ///      Error: Undeclared identifier. "callbackSendTokensWithResolve" is not (or not yet) visible at this point.
    ///      The fix is coming: https://github.com/tonlabs/TON-Solidity-Compiler/issues/36
    function callbackSendTokensWithResolve(uint errorCode, uint128 tokens, uint128 grams, uint256 pubKeyToResolve) public override 
    {
        // we will purposely do nothing here, just grab our change
    }

    /// @dev TODO: here "external" was purposely changed to "public", otherwise you get the following error:
    ///      Error: Undeclared identifier. "callbackGetTTWAddressForSwap" is not (or not yet) visible at this point.
    ///      The fix is coming: https://github.com/tonlabs/TON-Solidity-Compiler/issues/36
    function callbackSwapGetTTWAddress(address targetAddress, uint256 walletPublicKey, address ownerAddress) public override 
    {
        // we will purposely do nothing here, just grab our change
    }

    /// @dev TODO: here "external" was purposely changed to "public", otherwise you get the following error:
    ///      Error: Undeclared identifier. "callbackSwapGetTransferResult" is not (or not yet) visible at this point.
    ///      The fix is coming: https://github.com/tonlabs/TON-Solidity-Compiler/issues/36
    function callbackSwapGetTransferResult(uint errorCode, uint128 tokens, address to) public override 
    {
        tvm.accept();
        tvm.accept();
        
        uint256 publicKey = 0;
        for((uint256 pk, swapTokenStatus status) : _swapTokenStatus)
        {
            if(status.symbol1TTW == msg.sender && status.symbol1Requested == tokens)
            {
                publicKey = pk;
                break;
            }
            if(status.symbol2TTW == msg.sender && status.symbol2Requested == tokens)
            {
                publicKey = pk;
                break;
            }
        }

        if(_swapTokenStatus[publicKey].direction == true) // true means "get symbol1 and give symbol2", false means "give symbol1 and get symbol2"
        {
            // TODO: adjust price
            _swapTokenStatus[publicKey].symbol2Error     = errorCode;
            _swapTokenStatus[publicKey].symbol2Processed = tokens;
            if(errorCode == 0)
            {
                ITonTokenWallet(_symbol1.symbolRTW).sendTokensResolveAddress{value: 0.1 ton}(_swapTokenStatus[publicKey].symbol1Requested, 0, publicKey);
                _swapTokenStatus[publicKey].symbol1Processed = _swapTokenStatus[publicKey].symbol1Requested;
                _symbol1.amount -= _swapTokenStatus[publicKey].symbol1Requested;
                _symbol2.amount += tokens;
            }
        }
        else
        {
            // TODO: adjust price
            _swapTokenStatus[publicKey].symbol1Error     = errorCode;
            _swapTokenStatus[publicKey].symbol1Processed = tokens;
            if(errorCode == 0)
            {
                ITonTokenWallet(_symbol2.symbolRTW).sendTokensResolveAddress{value: 0.1 ton}(_swapTokenStatus[publicKey].symbol2Requested, 0, publicKey);
                _swapTokenStatus[publicKey].symbol2Processed = _swapTokenStatus[publicKey].symbol2Requested;
                _symbol2.amount -= _swapTokenStatus[publicKey].symbol2Requested;
                _symbol1.amount += tokens;
            }
        }
        
        _swapTokenStatus[publicKey].done = true;
    }

    //========================================
    //
    /// @dev TODO: here "external" was purposely changed to "public", otherwise you get the following error:
    ///      Error: Undeclared identifier. "callbackDepositGetTTWAddress" is not (or not yet) visible at this point.
    ///      The fix is coming: https://github.com/tonlabs/TON-Solidity-Compiler/issues/36
    function callbackDepositGetTTWAddress(address targetAddress, uint256 walletPublicKey, address ownerAddress) public override 
    {
        // we will purposely do nothing here, just grab our change
    }

    /// @dev TODO: here "external" was purposely changed to "public", otherwise you get the following error:
    ///      Error: Undeclared identifier. "callbackSwapGetTransferResult" is not (or not yet) visible at this point.
    ///      The fix is coming: https://github.com/tonlabs/TON-Solidity-Compiler/issues/36
    function _finalizeLiquidity(uint256 publicKey) internal 
    {
        tvm.accept();
        
        if(_depositLiquidityStatus[publicKey].symbol1Error > 0 || _depositLiquidityStatus[publicKey].symbol2Error > 0)
        {
            _depositLiquidityStatus[publicKey].done = true;

            // return TOKENS BACK!
            if(_depositLiquidityStatus[publicKey].symbol1ToProcess > 0)
            {
                ITonTokenWallet(_symbol1.symbolTTW).sendTokensResolveAddress{value: 0.1 ton}(_depositLiquidityStatus[publicKey].symbol1ToProcess, 0, publicKey);
            }
            if(_depositLiquidityStatus[publicKey].symbol2ToProcess > 0)
            {
                ITonTokenWallet(_symbol2.symbolTTW).sendTokensResolveAddress{value: 0.1 ton}(_depositLiquidityStatus[publicKey].symbol2ToProcess, 0, publicKey);
            }
            
            return;
        }

        if(_depositLiquidityStatus[publicKey].symbol1ToProcess > 0 && _depositLiquidityStatus[publicKey].symbol2ToProcess > 0)
        {
            // TODO: paste calculations here
            uint128 finalAmount1 = 0;
            uint128 finalAmount2 = 0;

            (uint256 ratio, uint8 ratioDecimals) = getPairRatio(true);
            if(ratio == 0)
            {
                finalAmount1 = _depositLiquidityStatus[publicKey].symbol1ToProcess;
                finalAmount2 = _depositLiquidityStatus[publicKey].symbol2ToProcess;
            }
            else
            {
                //========================================
                //
                uint256 amount2from1 = (uint256(_depositLiquidityStatus[publicKey].symbol1ToProcess) * 10**uint256(_localDecimals));
                        amount2from1 /= ratio;
                uint8 newPrecision2 = _symbol1.decimals + ratioDecimals - _localDecimals;
                if(_symbol2.decimals > newPrecision2)
                {
                    amount2from1 = amount2from1 * 10**uint256(_symbol2.decimals - newPrecision2);
                }
                else
                {
                    amount2from1 = amount2from1 / 10**uint256(newPrecision2 - _symbol2.decimals);
                }

                //========================================
                //
                (uint256 ratioReverse, uint8 ratioReverseDecimals) = getPairRatio(false);

                uint256 amount1from2 = (uint256(_depositLiquidityStatus[publicKey].symbol2ToProcess) * 10**uint256(_localDecimals));
                        amount1from2 /= ratioReverse;
                uint8 newPrecision1 = _symbol2.decimals + ratioReverseDecimals - _localDecimals;
                if(_symbol1.decimals > newPrecision1)
                {
                    amount1from2 = amount1from2 * 10**uint256(_symbol1.decimals - newPrecision1);
                }
                else
                {
                    amount1from2 = amount1from2 / 10**uint256(newPrecision1 - _symbol1.decimals);
                }

                //========================================
                //
                if(amount2from1 <= uint256(_depositLiquidityStatus[publicKey].symbol2ToProcess))
                {
                    finalAmount1 = _depositLiquidityStatus[publicKey].symbol1ToProcess;
                    finalAmount2 = uint128(amount2from1);
                }
                else
                {
                    finalAmount1 = uint128(amount1from2);
                    finalAmount2 = _depositLiquidityStatus[publicKey].symbol2ToProcess;
                }
            }

            _depositLiquidityStatus[publicKey].symbol1Processed = finalAmount1;
            _depositLiquidityStatus[publicKey].symbol2Processed = finalAmount2;
            _depositLiquidityStatus[publicKey].done = true;

            uint256 liquidityRatio = 0;
            uint256 newLiquidity   = 0;
            if(_symbol1.amount == 0)
            {
                if(_localDecimals >= _symbol1.decimals)
                {
                    newLiquidity = finalAmount1 * 10**(uint256(_localDecimals - _symbol1.decimals));
                }
                else
                {
                    newLiquidity = finalAmount1 / 10**(uint256(_symbol1.decimals - _localDecimals));
                }

                _userLiquidity[publicKey] = newLiquidity;
                _totalLiquidity = newLiquidity;            
            }
            else
            {
                liquidityRatio = (_symbol1.amount * 10**uint256(_localDecimals)) / finalAmount1;
                newLiquidity    = _totalLiquidity * 10**uint256(_localDecimals) / liquidityRatio;
                
                _userLiquidity[publicKey] += newLiquidity;
                _totalLiquidity += newLiquidity;
            }
            
            _symbol1.amount += finalAmount1;
            _symbol2.amount += finalAmount2;

            // RETURN CHANGE
            if(_depositLiquidityStatus[publicKey].symbol1Processed != _depositLiquidityStatus[publicKey].symbol1Requested)
            {
                uint128 diff = _depositLiquidityStatus[publicKey].symbol1Requested - _depositLiquidityStatus[publicKey].symbol1Processed;
                ITonTokenWallet(_symbol1.symbolTTW).sendTokensResolveAddress{value: 0.1 ton}(diff, 0, publicKey);
            }
            if(_depositLiquidityStatus[publicKey].symbol2Processed != _depositLiquidityStatus[publicKey].symbol2Requested)
            {
                uint128 diff = _depositLiquidityStatus[publicKey].symbol2Requested - _depositLiquidityStatus[publicKey].symbol2Processed;
                ITonTokenWallet(_symbol2.symbolTTW).sendTokensResolveAddress{value: 0.1 ton}(diff, 0, publicKey);
            }
        }
    }

    function callbackDepositGetTransferResult2(uint errorCode, uint128 tokens, address to) public override 
    {
        tvm.accept();
        
        for((uint256 pk, manageLiquidityStatus status) : _depositLiquidityStatus)
        {
            if(status.symbol2TTW == msg.sender)//  && status.symbol2Requested == tokens)
            {
                _depositLiquidityStatus[pk].symbol2ToProcess = tokens;
                _depositLiquidityStatus[pk].symbol2Error     = errorCode;
                _finalizeLiquidity(pk);
                return;
            }
        }
    }
    
    function callbackDepositGetTransferResult(uint errorCode, uint128 tokens, address to) public override 
    {
        tvm.accept();
        
        uint256 pubkey = 0;
        for((uint256 pk, manageLiquidityStatus status) : _depositLiquidityStatus)
        {
            if(status.symbol1TTW == msg.sender)// && status.symbol1Requested == tokens)
            {
                pubkey = pk;
                break;
            }
        }
        if(pubkey > 0)
        {
            _depositLiquidityStatus[pubkey].symbol1ToProcess = tokens;
            _depositLiquidityStatus[pubkey].symbol1Error     = errorCode;

            ITonTokenWallet(_depositLiquidityStatus[pubkey].symbol2TTW).sendMyTokensUsingAllowanceZPK{value: 1 ton, callback: callbackDepositGetTransferResult2}(_depositLiquidityStatus[pubkey].symbol2Requested, _symbol2.symbolTTW);
        }
    }

    //========================================
    //
    constructor() public
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
    /// @dev TODO: here "external" was purposely changed to "public", otherwise you get the following error:
    ///      Error: Undeclared identifier. "getPairRatio" is not (or not yet) visible at this point.
    ///      The fix is coming: https://github.com/tonlabs/TON-Solidity-Compiler/issues/36
    function getPairRatio(bool firstFirst) public view override returns (uint256, uint8)
    {
        Symbol symbol1 = firstFirst ? _symbol1 : _symbol2;
        Symbol symbol2 = firstFirst ? _symbol2 : _symbol1;

        // Empty
        if(symbol1.amount == 0 || symbol2.amount == 0)
        {
            return (0, 0);
        }
        
        uint256 ratio    = symbol1.amount;
        uint8   decimals = _localDecimals + symbol2.decimals - symbol1.decimals;

        ratio = ratio * uint256(10**uint256(_localDecimals));
        ratio = ratio / uint256(symbol2.amount);

        return (ratio, decimals);
    }

    //========================================
    // TODO: need to add "maximum slippage" to prevent a Liquidity provider to provide Liquidity having a bad ratio
    // TODO: Current limitations: only Public Key owners can deposit and withdraw liquidity;
    //       their TIP-3 address will be calculated from their Public Key;
    function depositLiquidity(uint128 amount1, uint128 amount2, address ttwToken1, address ttwToken2) external override
    {
        tvm.accept();

        // Check if this user has unfinished deposits
        if(_depositLiquidityStatus[msg.pubkey()].dtRequested != 0)
        {
            delete _depositLiquidityStatus[msg.pubkey()];
        }

        // Request depositing
        _depositLiquidityStatus[msg.pubkey()].dtRequested      = now;
        _depositLiquidityStatus[msg.pubkey()].symbol1TTW       = ttwToken1;
        _depositLiquidityStatus[msg.pubkey()].symbol1Requested = amount1;
        _depositLiquidityStatus[msg.pubkey()].symbol2TTW       = ttwToken2;
        _depositLiquidityStatus[msg.pubkey()].symbol2Requested = amount2;

        ITonTokenWallet(ttwToken1).sendMyTokensUsingAllowanceZPK{value: 1 ton, callback: callbackDepositGetTransferResult}(amount1, _symbol1.symbolTTW);
    }

    //========================================
    // TODO: Current limitations: only Public Key owners can deposit and withdraw liquidity;
    //       their TIP-3 address will be calculated from their Public Key;
    function withdrawLiquidity(uint256 amountLiquidity) external override 
    {
        require(msg.pubkey()   != 0,                             ERROR_EMPTY_PUBKEY                );
        require(amountLiquidity > 0,                             ERROR_CAN_NOT_WITHDRAW_0_LIQUIDITY);
        require(_userLiquidity[msg.pubkey()] >= amountLiquidity, ERROR_NOT_ENOUGH_LIQUIDITY        );

        tvm.accept();

        // OUR _totalLiquidity       has "_symbol1.decimals + _symbol2.decimals" precision
        //     _userLiquidity[] also has "_symbol1.decimals + _symbol2.decimals" precision
        // We purposely multiply all the values by "10**_localDecimals" to have better precision when dividing to get ratio;
        // About every Symbol custom precision - we do not need to care about it;

        uint256 ratio = (_totalLiquidity * 10**uint256(_localDecimals)) / uint256(amountLiquidity);
        uint256 amountSymbol1 = (uint256(_symbol1.amount) * 10**uint256(_localDecimals)) / ratio;
        uint256 amountSymbol2 = (uint256(_symbol2.amount) * 10**uint256(_localDecimals)) / ratio;

        // Symbol1
        //if(_symbol1.symbolType == SymbolType.TonCrystal) { } // CURENTLY NOT IMPLEMENTED
        if(_symbol1.symbolType == SymbolType.Tip3)         {    ITonTokenWallet(_symbol1.symbolTTW).sendTokensResolveAddressZPK{value: 1 ton, callback: callbackSendTokensWithResolve}(uint128(amountSymbol1), 1 ton, msg.pubkey());  }
        //if(_symbol1.symbolType == SymbolType.Erc20)      { } // CURENTLY NOT IMPLEMENTED

        // Symbol2
        //if(_symbol2.symbolType == SymbolType.TonCrystal) { } // CURENTLY NOT IMPLEMENTED
        if(_symbol2.symbolType == SymbolType.Tip3)         {    ITonTokenWallet(_symbol2.symbolTTW).sendTokensResolveAddressZPK{value: 1 ton, callback: callbackSendTokensWithResolve}(uint128(amountSymbol2), 1 ton, msg.pubkey());  }
        //if(_symbol2.symbolType == SymbolType.Erc20)      { } // CURENTLY NOT IMPLEMENTED

        _symbol1.amount              -= amountSymbol1;
        _symbol2.amount              -= amountSymbol2;
        _totalLiquidity              -= amountLiquidity;
        _userLiquidity[msg.pubkey()] -= amountLiquidity;

    }

    //========================================
    /// @dev TODO: here "external" was purposely changed to "public", otherwise you get the following error:
    ///      Error: Undeclared identifier. "getPairLiquidity" is not (or not yet) visible at this point.
    ///      The fix is coming: https://github.com/tonlabs/TON-Solidity-Compiler/issues/36
    function getPairLiquidity() public view override returns (uint256, uint8) 
    {
        uint256 amount   = _symbol1.amount   * _symbol2.amount;
        uint8   decimals = _symbol1.decimals + _symbol2.decimals;

        return (amount, decimals);
    }

    //========================================
    //
    function getUserLiquidity(uint256 ownerPubKey) external view override returns (uint256, uint8) 
    {
        return (_userLiquidity[ownerPubKey], _localDecimals);
    }

    function getUserTotalLiquidity() external view override returns (uint256, uint8)
    {
        return (_totalLiquidity, _localDecimals);
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
    function getPrice(address RTW_ofTokenToGet, address RTW_ofTokenToGive, uint128 amountToGive) public view override returns (uint256, uint8) 
    {
        require(RTW_ofTokenToGet != RTW_ofTokenToGive,                                              ERROR_SYMBOLS_SHOULD_BE_DIFFERENT        );
        require(RTW_ofTokenToGet != addressZero && RTW_ofTokenToGive != addressZero,                ERROR_SYMBOLS_SHOULD_HAVE_VALID_ADDRESSES);
        require(RTW_ofTokenToGet  == _symbol1.symbolRTW || RTW_ofTokenToGet  == _symbol2.symbolRTW, ERROR_SYMBOL_MISSING                     );
        require(RTW_ofTokenToGive == _symbol1.symbolRTW || RTW_ofTokenToGive == _symbol2.symbolRTW, ERROR_SYMBOL_MISSING                     );

        Symbol symbolGet  = (RTW_ofTokenToGet  == _symbol1.symbolRTW ? _symbol1 : _symbol2); // 
        Symbol symbolGive = (RTW_ofTokenToGive == _symbol1.symbolRTW ? _symbol1 : _symbol2); // 

        uint256 tokenReserve = symbolGet.amount;

        uint256 tokensToBuy = getPriceInternal(amountToGive, tokenReserve, symbolGive.amount);

        return (tokensToBuy, symbolGet.decimals);
    }

    //========================================
    // TODO: need to add "maximum slippage" to prevent a Liquidity provider to provide Liquidity having a bad ratio
    function swapTokens(address tokenToGet, address tokenToGive, uint128 amountToGive, address ttwTokenToGet, address ttwTokenToGive) external override
    {
        require(msg.pubkey() != 0, ERROR_EMPTY_PUBKEY);
        
        tvm.accept();

        (uint256 tmpLiquidity, uint8 tmpDecimals) = getPairLiquidity();
        require(minimumLiquidity * 10**uint256(tmpDecimals) < tmpLiquidity, ERROR_NOT_ENOUGH_LIQUIDITY);

        delete _swapTokenStatus[msg.pubkey()];

        // TODO
        (uint256 price, uint8 decimals) = getPrice(tokenToGet, tokenToGive, amountToGive);

        _swapTokenStatus[msg.pubkey()].dtRequested      = now;
        _swapTokenStatus[msg.pubkey()].direction        = (tokenToGet == _symbol1.symbolRTW); // true means "get symbol1 and give symbol2", false means "give symbol1 and get symbol2"
        _swapTokenStatus[msg.pubkey()].symbol1Requested = (tokenToGet == _symbol1.symbolRTW ? uint128(price) : uint128(amountToGive));
        _swapTokenStatus[msg.pubkey()].symbol1TTW       = (tokenToGet == _symbol1.symbolRTW ? ttwTokenToGet : ttwTokenToGive);
        _swapTokenStatus[msg.pubkey()].symbol2Requested = (tokenToGet == _symbol1.symbolRTW ? uint128(amountToGive) : uint128(price));
        _swapTokenStatus[msg.pubkey()].symbol1TTW       = (tokenToGet == _symbol1.symbolRTW ? ttwTokenToGive : ttwTokenToGet);
        _swapTokenStatus[msg.pubkey()].done = false;

        if(tokenToGet == _symbol1.symbolRTW)
        {
            ITonTokenWallet(ttwTokenToGive).sendMyTokensUsingAllowanceZPK{value: 1 ton, callback: callbackSwapGetTransferResult}(_swapTokenStatus[msg.pubkey()].symbol2Requested, _symbol2.symbolTTW);
        }
        else
        {
            ITonTokenWallet(ttwTokenToGive).sendMyTokensUsingAllowanceZPK{value: 1 ton, callback: callbackSwapGetTransferResult}(_swapTokenStatus[msg.pubkey()].symbol1Requested, _symbol1.symbolTTW);
        }

        //address RTW = (_swapTokenStatus[msg.pubkey()].direction ? _symbol2.symbolRTW : _symbol1.symbolRTW ); 
        //IRootTokenWallet(RTW).getWalletAddressZPK{value: 1 ton, callback: callbackSwapGetTTWAddress}(msg.pubkey(), addressZero);

    }
}

//================================================================================
//