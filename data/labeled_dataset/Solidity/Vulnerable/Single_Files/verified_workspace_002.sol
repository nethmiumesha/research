pragma solidity ^0.8.20;
contract AvalancheVault {
    address public owner;
    address constant USDC = 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E;
    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }
    constructor(address _owner) {
        owner = _owner;
    }
    function withdrawUSDC(address to, uint256 amount) external onlyOwner {
        require(IERC20(USDC).transfer(to, amount), "transfer failed");
    }
    function sweepUSDC(address to) external onlyOwner {
        uint256 bal = IERC20(USDC).balanceOf(address(this));
        require(IERC20(USDC).transfer(to, bal), "transfer failed");
    }
}