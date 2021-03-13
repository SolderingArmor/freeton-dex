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

    function getWalletAddress   (uint256 walletPublicKey, address ownerAddress) external view             returns (address, uint256, address);
    function getWalletAddressZPK(uint256 walletPublicKey, address ownerAddress) external view responsible returns (address, uint256, address);
    
    function getTokenDetails()    external             returns (bytes, bytes, uint8);
    function getTokenDetailsZPK() external responsible returns (bytes, bytes, uint8);

    //========================================
    // Management
    function deployWallet        (uint128 tokens, uint128 grams, uint256 walletPublicKey, address ownerAddress) external             returns (address, uint128, uint128, uint256, address);
    function deployWalletZPK     (uint128 tokens, uint128 grams, uint256 walletPublicKey, address ownerAddress) external responsible returns (address, uint128, uint128, uint256, address);
    function deployEmptyWallet   (                uint128 grams, uint256 walletPublicKey, address ownerAddress) external             returns (address,          uint128, uint256, address);
    function deployEmptyWalletZPK(                uint128 grams, uint256 walletPublicKey, address ownerAddress) external responsible returns (address,          uint128, uint256, address);

    //========================================
    // Root stuff
    function mint   (uint128 tokens, address to) external             returns (uint, uint128, address);
    function mintZPK(uint128 tokens, address to) external responsible returns (uint, uint128, address);
}

//================================================================================
//