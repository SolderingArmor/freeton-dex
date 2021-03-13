pragma ton-solidity >= 0.38.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

//================================================================================
// Imports
import "../interfaces/ITTW_FT.sol";

//================================================================================
//
interface IRootTokenWallet 
{
    //========================================
    // Get
    //========================================
    //
    function getName()             external view returns (bytes);
    function getSymbol()           external view returns (bytes);
    function getDecimals()         external view returns (uint8);
    function getTotalSupply()      external view returns (uint128);
    function getRootPublicKey()    external view returns (uint256);
    function getRootOwnerAddress() external view returns (address);
    function getCode()             external view returns (TvmCell);

    /// @notice Calculate TTW address;
    ///         ZPK means Zero Public Key, that means an internal message from contract to contract;
    ///
    /// @param walletPublicKey - public key of the owner;
    /// @param ownerAddress    - address    of the owner;
    //
    function getWalletAddress   (uint256 walletPublicKey, address ownerAddress) external view             returns (address, uint256, address);
    function getWalletAddressZPK(uint256 walletPublicKey, address ownerAddress) external view responsible returns (address, uint256, address);
    
    /// @notice Get Token specific details;
    ///         ZPK means Zero Public Key, that means an internal message from contract to contract;
    //
    function getTokenDetails()    external view             returns (bytes, bytes, uint8);
    function getTokenDetailsZPK() external view responsible returns (bytes, bytes, uint8);

    //========================================
    // Management
    //
    /// @notice Deploy TTW and mint Tokens to it at the same time; Can be called only by Root owner;
    ///         ZPK means Zero Public Key, that means an internal message from contract to contract;
    ///
    /// @param tokens          - amount of tokens to mint;
    /// @param grams           - amount of grams to send dirung creation;
    /// @param walletPublicKey - public key of the owner;
    /// @param ownerAddress    - address    of the owner;
    //
    function deployWallet        (uint128 tokens, uint128 grams, uint256 walletPublicKey, address ownerAddress) external             returns (address, uint128, uint128, uint256, address);
    function deployWalletZPK     (uint128 tokens, uint128 grams, uint256 walletPublicKey, address ownerAddress) external responsible returns (address, uint128, uint128, uint256, address);
    
    //========================================
    // Management
    //
    /// @notice Deploy empty TTW; Can be called by anyone;
    ///         ZPK means Zero Public Key, that means an internal message from contract to contract;
    ///
    /// @param grams           - amount of grams to send dirung creation;
    /// @param walletPublicKey - public key of the owner;
    /// @param ownerAddress    - address    of the owner;
    //
    function deployEmptyWallet   (uint128 grams, uint256 walletPublicKey, address ownerAddress) external             returns (address, uint128, uint256, address);
    function deployEmptyWalletZPK(uint128 grams, uint256 walletPublicKey, address ownerAddress) external responsible returns (address, uint128, uint256, address);

    //========================================
    //
    /// @notice Mint Tokens to a specific TTW; Can be called only by Root owner;
    ///         ZPK means Zero Public Key, that means an internal message from contract to contract;
    ///
    /// @param tokens - amount of tokens to mint;
    /// @param to     - address of the TTW;
    //
    function mint   (uint128 tokens, address to) external             returns (uint, uint128, address);
    function mintZPK(uint128 tokens, address to) external responsible returns (uint, uint128, address);
}

//================================================================================
//