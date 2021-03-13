pragma ton-solidity >= 0.38.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

//================================================================================
//
import "../interfaces/ISymbolPair.sol";

//================================================================================
//
interface IDexFactory
{
    //========================================
    // Callbacks
    //
    function callback_VerifyTokenDetails(bytes name, bytes symbol, uint8 decimals) external;
    
    //========================================
    // Management
    //
    /// @notice Sets new DEX owner;
    ///
    /// @param newOwner - new DEX owner; 
    //
    function setOwner(uint256 newOwner) external;

    /// @notice When Governance reaches decentralization there's no need fot the owner anymore, thus he can be disabled leaving the Governance one and only;
    //
    function disableOwner() external;

    /// @notice Sets new DEX Governance;
    ///
    /// @param newGoverenance - new DEX Governance address; 
    //
    function setGovernance(address newGoverenance) external;
    
    /// @notice Adds a new Symbol to DEX; Can be called by anyone (not only Owner or Governance);
    ///         When called, new Symbol will be added and then verified automatically;
    ///         NOTE: currently DexFactory uses its own funds (tvm.accept()) to manage this function, thus
    ///               one can perform an attack and spend all the funds of the contract; it is made for
    ///               simplicity of DEX Stage 1 Implementation;
    ///         TODO: add TTL to temporary entries to stop DexFactory contract from growing; 
    ///
    /// @param symbolAddressRTW - RTW address of the Symbol (wallet); 
    /// @param symbolType       - Type of the fungible token to add, see ISymbolPair for details; 
    //
    function addSymbol(address symbolAddressRTW, SymbolType symbolType) external;

    /// @notice Adds a new SymbolPair to DEX; Both Symbols must be added beforehead; Order of the Symbols doesn't matter;
    ///
    /// @param symbol1RTW - RTW address of the Symbol (wallet);
    /// @param symbol2RTW - RTW address of the Symbol (wallet);
    //
    function addPair(address symbol1RTW, address symbol2RTW) external;
    
    /// @notice Sets the fee that Liquidity Providers ger from each trade; 1% = 100; 100% = 10000;
    ///
    /// @param fee - Fee value; default 3% = 30;
    //
    function setProviderFee(uint16 fee) external;

    /// @notice Sets custom fee for a specific SymbolPair; Order of the Symbols doesn't matter;
    ///
    /// @param symbol1RTW - RTW address of the Symbol (wallet);
    /// @param symbol2RTW - RTW address of the Symbol (wallet);
    /// @param isCustom   - If the fee is custom, when FALSE, see is set to be the same as common Provider fee;
    /// @param fee        - Fee value; default 3% = 30;
    //
    function setProviderFeeCustom(address symbol1RTW, address symbol2RTW, bool isCustom, uint16 fee) external;

    //========================================
    // Get/Set
    //
    /// @notice Gets current Liquidity Provider fee; For a custom fee please call SymbolPair directly;
    //
    function getProviderFee() external view returns (uint128);
    
    /// @notice Checks if the Symbol exists in DexFactory;
    ///
    /// @param symbolRTW - RTW address of the Symbol (wallet);
    //
    function SymbolExists(address symbolRTW) external view returns (bool);

    /// @notice Returns address of a specific SymbolPair contract, (0, 0) on fail; Order of the Symbols doesn't matter;
    ///
    /// @param symbol1RTW - RTW address of the Symbol (wallet);
    /// @param symbol2RTW - RTW address of the Symbol (wallet);
    //
    function getPair(address symbol1RTW, address symbol2RTW) external view returns (address);

    /// @notice Returns addresses of all SymbolPairs contracts;
    //
    function getAllPairs() external view returns (address[]);
}

//================================================================================
//