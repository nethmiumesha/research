pragma solidity 0.8.26;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
            unchecked {
                _approve(sender, _msgSender(), currentAllowance - amount);
            }
        }
        _transfer(sender, recipient, amount);
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }
        return true;
    }
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(sender, recipient, amount);
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        _afterTokenTransfer(sender, recipient, amount);
    }
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
        _afterTokenTransfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
        _afterTokenTransfer(account, address(0), amount);
    }
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}
abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    constructor() {
        _status = _NOT_ENTERED;
    }
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}
interface IEcoFund {
    function sendReward(address user, uint256 amount) external;
}
contract AICoinClaw is ERC20, Ownable, ReentrancyGuard {
    uint256 private constant DECIMALS_FACTOR = 10**18;
    uint256 private  baseMintRate = 20000 * DECIMALS_FACTOR;
    uint256 private constant minContribution = 0.1 ether;
    bool public isPublicSaleActive = true;
    mapping(address => uint256) private userTotalContributions;
    mapping(address => bool) public liquidityProviders;
    uint256[] private contributionMilestones = [5 ether, 10 ether, 20 ether];
    uint256[] private milestoneRewards = [50000, 200000, 500000];
    mapping(address => uint256) private userClaimedMilestoneRewards;
    address public ecoFundContract;
    uint256 private mintEventCounter;
    event RewardDistributionFailed(address user, uint256 amount);
    event TokensMinted(uint256 indexed  eventId, address indexed  sender, uint256 indexed  value);
    event PublicSaleDisabled(uint256 timestamp);
    event LiquidityProviderAdded(address indexed provider);
    event LiquidityProviderRemoved(address indexed provider);
    constructor () ERC20("AI CoinClaw", "ACC")
    {
        _mint(address(this), 1e9 * DECIMALS_FACTOR);
       mintEventCounter = 0;
    }
    receive() external payable {}
    function tokensMinted() external payable nonReentrant {
        require(isPublicSaleActive, "Public sale has ended");
        require(owner() != address(0), "Owner address is zero, operation not allowed");
        require(msg.value >= minContribution, "Insufficient ETH sent");
        uint256 mintQuantity = (msg.value * baseMintRate) / minContribution;
        address contractAddress = address(this);
        require(balanceOf(contractAddress) >= mintQuantity, "Owner does not have enough tokens");
        super._transfer(contractAddress, msg.sender, mintQuantity);
        userTotalContributions[msg.sender] = userTotalContributions[msg.sender] + msg.value;
        mintEventCounter ++;
        emit TokensMinted(mintEventCounter, msg.sender, msg.value);
        checkAndReward(msg.sender);
    }
    function checkAndReward(address user) internal {
        uint256 totalReward = 0;
        uint256 userDeposit = userTotalContributions[user];
        for (uint8 level = 1; level <= 3; level++) {
            uint256 threshold = contributionMilestones[level - 1];
            uint256 reward = milestoneRewards[level - 1] * DECIMALS_FACTOR;
            if (userDeposit >= threshold) {
                totalReward = reward;
            } else {
                break;
            }
        }
        uint256 claimedReward = userClaimedMilestoneRewards[user];
        if (totalReward > claimedReward) {
            uint256 rewardToSend = totalReward - claimedReward;
            userClaimedMilestoneRewards[user] = totalReward;
            if (ecoFundContract != address(0)) {
                try IEcoFund(ecoFundContract).sendReward(user, rewardToSend) {
                } catch {
                    userClaimedMilestoneRewards[user] = claimedReward;
                    emit RewardDistributionFailed(user, rewardToSend);
                }
            } else {
                userClaimedMilestoneRewards[user] = claimedReward;
                emit RewardDistributionFailed(user, rewardToSend);
            }
        }
    }
    function setEcoFundContract(address _ecoFundContract) external onlyOwner {
        require(_ecoFundContract != address(0), "Invalid eco fund address");
        ecoFundContract = _ecoFundContract;
    }
    function batchDistributeTokens(address[] memory recipients, uint256 amount) external onlyOwner{
        require(owner() != address(0), "Owner address is zero, operation not allowed");
        require(recipients.length <= 200, "Too many recipients");
        for (uint i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Invalid recipient address");
            super._transfer(address(this), recipients[i], amount);
        }
    }
    function disablePublicSale() external onlyOwner{
        require(isPublicSaleActive, "Public sale has ended");
        isPublicSaleActive = false;
        emit PublicSaleDisabled(block.timestamp);
    }
    function isAddressContract(address _addr) internal view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }
    function _transfer(address from,address to,uint256 amount) internal  override {
        require(from != address(0), "ERC20: transfer from the zero address");
         if (isUnauthorizedLiquidityAddition(to)) {
            revert("Only whitelisted addresses can add liquidity before public sale ends.");
        }
        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
        super._transfer(from, to, amount);
    }
    function isUnauthorizedLiquidityAddition(address to) internal view returns (bool) {
        return isAddressContract(to) && (!liquidityProviders[to] && isPublicSaleActive);
    }
    function addLiquidityProvider(address _addr) external onlyOwner {
        require(_addr != address(0), "Invalid address");
        liquidityProviders[_addr] = true;
        emit LiquidityProviderAdded(_addr);
    }
    function removeLiquidityProvider(address _addr) external onlyOwner {
        require(_addr != address(0), "Invalid address");
        liquidityProviders[_addr] = false;
        emit LiquidityProviderRemoved(_addr);
    }
    function getUserTotalContribution(address user) external view returns (uint256) {
        return userTotalContributions[user];
    }
    function recoverStuckAssets(address tokenAddress, uint256 amount, address to) external onlyOwner {
        require(to != address(0), "Invalid recipient address");
        if (tokenAddress == address(0)) {
            require(amount <= address(this).balance, "Insufficient contract balance");
            (bool success, ) = payable(to).call{value: amount}("");
            require(success, "ETH transfer failed");
            return;
        }
        IERC20 token = IERC20(tokenAddress);
        uint256 contractBalance = token.balanceOf(address(this));
        require(amount <= contractBalance, "Insufficient balance in contract");
        bool tokenSuccess = token.transfer(to, amount);
        require(tokenSuccess, "Token transfer failed");
    }
}