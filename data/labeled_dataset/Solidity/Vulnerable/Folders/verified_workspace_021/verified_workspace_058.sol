pragma solidity ^0.5.16;
import "./Owned.sol";
import "./interfaces/IAddressResolver.sol";
import "./interfaces/IEtherWrapper.sol";
import "./interfaces/ISynth.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IERC20.sol";
import "./MixinResolver.sol";
import "./interfaces/IEtherWrapper.sol";
contract NativeEtherWrapper is Owned, MixinResolver {
    bytes32 private constant CONTRACT_ETHER_WRAPPER = "EtherWrapper";
    bytes32 private constant CONTRACT_SYNTHSETH = "SynthsETH";
    constructor(address _owner, address _resolver) public Owned(_owner) MixinResolver(_resolver) {}
    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        bytes32[] memory addresses = new bytes32[](2);
        addresses[0] = CONTRACT_ETHER_WRAPPER;
        addresses[1] = CONTRACT_SYNTHSETH;
        return addresses;
    }
    function etherWrapper() internal view returns (IEtherWrapper) {
        return IEtherWrapper(requireAndGetAddress(CONTRACT_ETHER_WRAPPER));
    }
    function weth() internal view returns (IWETH) {
        return etherWrapper().weth();
    }
    function synthsETH() internal view returns (IERC20) {
        return IERC20(requireAndGetAddress(CONTRACT_SYNTHSETH));
    }
    function mint() public payable {
        uint amount = msg.value;
        require(amount > 0, "msg.value must be greater than 0");
        weth().deposit.value(amount)();
        weth().approve(address(etherWrapper()), amount);
        etherWrapper().mint(amount);
        synthsETH().transfer(msg.sender, synthsETH().balanceOf(address(this)));
        emit Minted(msg.sender, amount);
    }
    function burn(uint amount) public {
        require(amount > 0, "amount must be greater than 0");
        IWETH weth = weth();
        synthsETH().transferFrom(msg.sender, address(this), amount);
        synthsETH().approve(address(etherWrapper()), amount);
        etherWrapper().burn(amount);
        weth.withdraw(weth.balanceOf(address(this)));
        msg.sender.call.value(address(this).balance)("");
        emit Burned(msg.sender, amount);
    }
    function() external payable {
    }
    event Minted(address indexed account, uint amount);
    event Burned(address indexed account, uint amount);
}