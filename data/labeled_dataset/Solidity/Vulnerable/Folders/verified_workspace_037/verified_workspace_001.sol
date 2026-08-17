pragma solidity ^0.8.6;
contract Lockup {
    address payable foilWallet;
    mapping(address => mapping(uint256 => uint256)) public deposits;
    IERC20 public usdt;
    event Deposit(address userAddress, uint256 indexed side, uint256 amount);
    event Withdraw(uint256 amountAfterPercent);
    constructor(address payable _foilWallet, address _usdt) {
        require(_foilWallet != address(0), "The wallet address can not zero.");
        require(_usdt != address(0), "The USDT address can not zero.");
        foilWallet = _foilWallet;
        usdt = IERC20(_usdt);
    }
    function deposit(uint256 amount, uint256 side)
        external
        payable
        returns (bool)
    {
        require(msg.value == amount);
        deposits[msg.sender][side] = deposits[msg.sender][side] + amount;
        emit Deposit(msg.sender, side, amount);
        return true;
    }
    receive() external payable {}
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
    function withdraw(uint256 percentage, uint256 side) external {
        uint256 amount = deposits[msg.sender][side];
        require(amount > 0, "Can not withdraw");
        deposits[msg.sender][side] = deposits[msg.sender][side] - (amount * percentage);
        uint256 amountAfterPercent = (amount * percentage) / 1e4;
        if (side == 1) {
            require(
                usdt.transfer(foilWallet, amountAfterPercent),
                "Insufficient!"
            );
        } else {
            foilWallet.transfer(amountAfterPercent);
        }
        emit Withdraw(amountAfterPercent);
    }
}