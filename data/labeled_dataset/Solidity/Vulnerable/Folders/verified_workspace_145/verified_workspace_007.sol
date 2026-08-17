pragma solidity ^0.8.24;
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract PaymentEscrow is AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    address public immutable factory;
    uint256 public immutable timeout;
    uint256 public immutable createdAt;
    address public immutable token;
    uint256 public immutable expectedAmount;
    constructor(address _factory, uint256 _timeout, address _token, uint256 _expectedAmount) {
        factory = _factory;
        timeout = _timeout;
        createdAt = block.timestamp;
        token = _token;
        expectedAmount = _expectedAmount;
        _grantRole(DEFAULT_ADMIN_ROLE, _factory);
        _grantRole(ADMIN_ROLE, _factory);
    }
    function version() public pure returns (string memory) {
        return "1.0.3";
    }
    receive() external payable {}
    function getExpectedAmount() external view returns (uint256) {
        return expectedAmount;
    }
    function getCurrentBalance() external view returns (uint256) {
        if (token == address(0)) {
            return address(this).balance;
        } else {
            return IERC20(token).balanceOf(address(this));
        }
    }
    function getTimeout() external view returns (uint256) {
        return timeout;
    }
    function canSweep() external view returns (bool) {
        return block.timestamp >= createdAt + timeout;
    }
    function forwardToAdmin() external onlyRole(ADMIN_ROLE) {
        require(block.timestamp >= createdAt + timeout, "Refund window still open");
        if (token == address(0)) {
            payable(factory).transfer(address(this).balance);
        } else {
            IERC20(token).transfer(factory, IERC20(token).balanceOf(address(this)));
        }
    }
    function refund(address payable to) external onlyRole(ADMIN_ROLE) {
        require(block.timestamp < createdAt + timeout, "Refund window closed");
        if (token == address(0)) {
            to.transfer(address(this).balance);
        } else {
            IERC20(token).transfer(to, IERC20(token).balanceOf(address(this)));
        }
    }
}