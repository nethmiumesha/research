pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Lockable.sol";
import "./interfaces/WETH9.sol";
interface PolygonIERC20 is IERC20 {
    function withdraw(uint256 amount) external;
}
interface MaticToken {
    function withdraw(uint256 amount) external payable;
}
contract PolygonTokenBridger is Lockable {
    using SafeERC20 for PolygonIERC20;
    using SafeERC20 for IERC20;
    MaticToken public constant maticToken = MaticToken(0x0000000000000000000000000000000000001010);
    address public immutable destination;
    WETH9 public immutable l1Weth;
    constructor(address _destination, WETH9 _l1Weth) {
        destination = _destination;
        l1Weth = _l1Weth;
    }
    function send(
        PolygonIERC20 token,
        uint256 amount,
        bool isMatic
    ) public nonReentrant {
        token.safeTransferFrom(msg.sender, address(this), amount);
        token.withdraw(amount);
        if (isMatic) maticToken.withdraw{ value: amount }(amount);
    }
    function retrieve(IERC20 token) public nonReentrant {
        token.safeTransfer(destination, token.balanceOf(address(this)));
    }
    receive() external payable {
        if (functionCallStackOriginatesFromOutsideThisContract()) l1Weth.deposit{ value: address(this).balance }();
    }
}