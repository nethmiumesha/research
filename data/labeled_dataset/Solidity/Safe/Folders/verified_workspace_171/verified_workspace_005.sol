pragma solidity 0.8.6;
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IHegicStakeAndCover.sol";
import "hardhat/console.sol";
contract HegicStakeAndCover is IHegicStakeAndCover, AccessControl {
    IERC20 public immutable hegicToken;
    IERC20 public immutable baseToken;
    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public startBalance;
    address internal unlockedTokenRecipient;
    bool public withdrawalsEnabled;
    uint256 public totalBalance;
    bytes32 public constant HEGIC_POOL_ROLE = keccak256("HEGIC_POOL_ROLE");
    constructor(IERC20 _hegic, IERC20 _baseToken) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        hegicToken = _hegic;
        baseToken = _baseToken;
        unlockedTokenRecipient = msg.sender;
    }
    function transfer(address to, uint256 amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        baseToken.transfer(to, amount);
    }
    function availableBalance() external view override returns (uint256) {
        return baseToken.balanceOf(address(this));
    }
    function payOut(uint256 amount)
        external
        override
        onlyRole(HEGIC_POOL_ROLE)
    {
        baseToken.transfer(msg.sender, amount);
    }
    function saveFreeTokens() external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 amount = hegicToken.balanceOf(address(this)) - totalBalance;
        totalBalance += amount;
        balanceOf[unlockedTokenRecipient] += amount;
    }
    function shareOf(address holder) public view returns (uint256) {
        return
            (baseToken.balanceOf(address(this)) * balanceOf[holder]) /
            totalBalance;
    }
    function trasferShare(address account, uint256 amount) external {
        require(profitOf(msg.sender) == 0);
        require(profitOf(account) == 0);
        balanceOf[msg.sender] -= amount;
        balanceOf[account] += amount;
        startBalance[msg.sender] = shareOf(msg.sender);
        startBalance[account] = shareOf(account);
    }
    function profitOf(address account)
        public
        view
        returns (uint256 profitAmount)
    {
        return
            (balanceOf[account] * baseToken.balanceOf(address(this))) /
            totalBalance -
            startBalance[account];
    }
    function withdraw(uint256 amount) external {
        require(
            withdrawalsEnabled,
            "HegicStakeAndCover: Withdrawals are currently disabled"
        );
        _withdraw(msg.sender, msg.sender, amount);
    }
    function setWithdrawalsEnabled(bool value)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        withdrawalsEnabled = value;
    }
    function claimProfit() public returns (uint256 profit) {
        profit = profitOf(msg.sender);
        require(profit > 0, "HegicStakeAndCover: The claimable profit is zero");
        uint256 profitShare =
            (profit * totalBalance) / baseToken.balanceOf(address(this));
        _withdraw(msg.sender, unlockedTokenRecipient, profitShare);
    }
    function _withdraw(
        address account,
        address hegicDestination,
        uint256 amount
    ) internal {
        uint256 liquidityShare =
            (amount * baseToken.balanceOf(address(this))) / totalBalance;
        balanceOf[account] -= amount;
        startBalance[account] =
            (balanceOf[account] * baseToken.balanceOf(address(this))) /
            totalBalance;
        totalBalance -= amount;
        hegicToken.transfer(hegicDestination, amount);
        baseToken.transfer(account, liquidityShare);
        emit Withdrawn(msg.sender, hegicDestination, amount, liquidityShare);
    }
    function provide(uint256 amount) external {
        if (profitOf(msg.sender) > 0) claimProfit();
        uint256 liquidityShare =
            (amount * baseToken.balanceOf(address(this))) / totalBalance;
        balanceOf[msg.sender] += amount;
        startBalance[msg.sender] = shareOf(msg.sender);
        totalBalance += amount;
        hegicToken.transferFrom(msg.sender, address(this), amount);
        baseToken.transferFrom(msg.sender, address(this), liquidityShare);
        emit Provided(msg.sender, amount, liquidityShare);
    }
}