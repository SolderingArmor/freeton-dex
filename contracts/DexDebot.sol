pragma ton-solidity >=0.38.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

//================================================================================
//
import "DexFactory.sol";
import "SymbolPair.sol";
import "../interfaces/IDebot.sol";
import "../interfaces/ITerminal.sol";
import "../interfaces/IAddressInput.sol";

//================================================================================
//
contract DexDebot is Debot 
{
    address dexAddress;
    
    /// @notice Entry point function for DeBot.
    function start() public override 
    {
        // print string to user.
        Terminal.print(0, "Welcome to DEX DeBot!"); 
        Terminal.print(0, "Please, enter DexFactory Address: ");
        AddressInput.select(tvm.functionId(onDexAddress));
    }

    function _onDexAddress() public 
    {
        Terminal.print(0, "Choose what you want to do:");
        Terminal.print(0, "1) Get provider fee");
        Terminal.print(0, "2) Exit");
        Terminal.inputUint(tvm.functionId(onMainMenu), "Enter your choice: ");
    }

    function onDexAddress(address value) public 
    {
        dexAddress = value;
        _onDexAddress();
    }

    function onProviderFee(uint128 fee) public
    {
        Terminal.print(0, format("Current fee: \"{}\"", fee));
        _onDexAddress();
    }

    function onMainMenu(uint256 value) public
    {
        if(value < 1 || value > 2)
        {
            Terminal.print(0, "Wrong input!");
            _onDexAddress();
        }

        if(value == 1)
        {
            optional(uint256) pk;
            DexFactory(dexAddress).getProviderFee{
                abiVer: 2,
                extMsg: true,
                sign: false,
                time: uint64(now),
                expire: 0,
                pubkey: pk,
                callbackId: tvm.functionId(onProviderFee),
                onErrorId: 0
            }();

        }
        else if(value == 2)
        {

        }
    }

    // @notice Define DeBot version and title here.
    function getVersion() public override returns (string name, uint24 semver) 
    {
        (name, semver) = ("Dex DeBot", _version(0, 1, 0));
    }

    function _version(uint24 major, uint24 minor, uint24 fix) private pure inline returns (uint24) 
    {
        return (major << 16) | (minor << 8) | (fix);
    }

}

//================================================================================
//