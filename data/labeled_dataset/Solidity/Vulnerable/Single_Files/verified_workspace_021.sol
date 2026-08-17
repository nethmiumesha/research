pragma solidity ^0.8.19;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _transferOwnership(_msgSender());
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint256) external;
}
interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}
interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
interface ISwapRouter {
    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);
}
contract DividendVault is Ownable {
    IERC20 public immutable XAUT;
    address public immutable eraToken;
    uint256 constant internal magnitude = 2**128;
    uint256 internal magnifiedDividendPerShare;
    uint256 public totalDividendsDistributed;
    mapping(address => int256) internal magnifiedDividendCorrections;
    mapping(address => uint256) internal withdrawnDividends;
    mapping(address => uint256) public holderBalance;
    uint256 public totalMirroredSupply;
    event DividendsDeposited(uint256 amount);
    event DividendClaimed(address indexed to, uint256 amount);
    constructor(address _rewardToken) {
        XAUT = IERC20(_rewardToken);
        eraToken = msg.sender;
    }
    modifier onlyToken() {
        require(msg.sender == eraToken, "Only ERA token can call this");
        _;
    }
    function depositDividends(uint256 amount) external onlyToken {
        if (totalMirroredSupply > 0 && amount > 0) {
            magnifiedDividendPerShare = magnifiedDividendPerShare + ((amount * magnitude) / totalMirroredSupply);
            totalDividendsDistributed += amount;
            emit DividendsDeposited(amount);
        }
    }
    function setBalance(address account, uint256 newBalance) external onlyToken {
        int256 _magCorrection = int256(magnifiedDividendPerShare * newBalance);
        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
            + int256(magnifiedDividendPerShare * holderBalance[account]);
        holderBalance[account] = newBalance;
        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account] - _magCorrection;
    }
    function updateSupply(uint256 newSupply) external onlyToken {
        totalMirroredSupply = newSupply;
    }
    function claim() external {
        uint256 _withdrawable = withdrawableDividendOf(msg.sender);
        require(_withdrawable > 0, "No dividends to claim");
        withdrawnDividends[msg.sender] += _withdrawable;
        require(XAUT.transfer(msg.sender, _withdrawable), "Transfer failed");
        emit DividendClaimed(msg.sender, _withdrawable);
    }
    function withdrawableDividendOf(address _owner) public view returns(uint256) {
        return accumulativeDividendOf(_owner) - withdrawnDividends[_owner];
    }
    function accumulativeDividendOf(address _owner) public view returns(uint256) {
        return uint256(int256(magnifiedDividendPerShare * holderBalance[_owner]) + magnifiedDividendCorrections[_owner]) / magnitude;
    }
    function rescueTokens(address _token) external onlyOwner {
        require(_token != address(XAUT), "Cannot withdraw dividend token");
        IERC20(_token).transfer(msg.sender, IERC20(_token).balanceOf(address(this)));
    }
}
contract ERA is IERC20, Ownable {
    string public constant name = "test22";
    string public constant symbol = "TSTE";
    uint8 public constant decimals = 18;
    uint256 private _totalSupply = 100000000 * 10**18;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    IUniswapV2Router02 public uniswapV2Router;
    ISwapRouter public uniswapV3Router;
    address public uniswapV2Pair;
    DividendVault public dividendVault;
    address public constant XAUT_ADDRESS = 0x68749665fF8D2D112fA2113446409fB57f21fF3F;
    address public constant USDT_ADDRESS = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant V3_ROUTER_ADDRESS = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address public marketingWallet;
    address public devWallet;
    address public charityWallet;
    bool private swapping;
    uint256 public swapTokensAtAmount = 1000 * 10**18;
    uint256 public rewardFee = 7;
    uint256 public marketingFee = 1;
    uint256 public devFee = 1;
    uint256 public charityFee = 1;
    uint256 public totalFee = 10;
    mapping(address => bool) public isExcludedFromFees;
    mapping(address => bool) public isExcludedFromDividends;
    uint256 public totalExcludedDividendBalance;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeFromDividends(address indexed account, bool isExcluded);
    event FeesUpdated(uint256 reward, uint256 marketing, uint256 dev, uint256 charity);
    constructor(address _marketing, address _dev, address _charity) {
        marketingWallet = _marketing;
        devWallet = _dev;
        charityWallet = _charity;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
        dividendVault = new DividendVault(XAUT_ADDRESS);
        dividendVault.transferOwnership(msg.sender);
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), WETH_ADDRESS);
        uniswapV3Router = ISwapRouter(V3_ROUTER_ADDRESS);
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(marketingWallet, true);
        excludeFromFees(address(dividendVault), true);
        isExcludedFromDividends[uniswapV2Pair] = true;
        isExcludedFromDividends[address(this)] = true;
        isExcludedFromDividends[address(dividendVault)] = true;
        IERC20(WETH_ADDRESS).approve(V3_ROUTER_ADDRESS, type(uint256).max);
        dividendVault.updateSupply(_totalSupply);
    }
    receive() external payable {}
    function totalSupply() public view override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address owner, address spender) public view override returns (uint256) { return _allowances[owner][spender]; }
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function excludeFromFees(address account, bool excluded) public onlyOwner {
        isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }
    function excludeFromDividends(address account, bool excluded) external onlyOwner {
        require(isExcludedFromDividends[account] != excluded, "Account already has this status");
        isExcludedFromDividends[account] = excluded;
        if (excluded) {
            totalExcludedDividendBalance += _balances[account];
            if(address(dividendVault) != address(0)) {
                try dividendVault.setBalance(account, 0) {} catch {}
            }
        } else {
            totalExcludedDividendBalance -= _balances[account];
            if(address(dividendVault) != address(0)) {
                try dividendVault.setBalance(account, _balances[account]) {} catch {}
            }
        }
        if(address(dividendVault) != address(0)) {
            try dividendVault.updateSupply(_totalSupply - totalExcludedDividendBalance) {} catch {}
        }
        emit ExcludeFromDividends(account, excluded);
    }
    function setFees(uint256 _reward, uint256 _marketing, uint256 _dev, uint256 _charity) external onlyOwner {
        rewardFee = _reward;
        marketingFee = _marketing;
        devFee = _dev;
        charityFee = _charity;
        totalFee = _reward + _marketing + _dev + _charity;
        require(totalFee <= 10, "Total fee cannot exceed 10%");
        emit FeesUpdated(_reward, _marketing, _dev, _charity);
    }
    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        if(amount == 0) {
            emit Transfer(from, to, 0);
            return;
        }
        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;
        if (canSwap && !swapping && from != uniswapV2Pair && !isExcludedFromFees[from] && !isExcludedFromFees[to]) {
            swapping = true;
            swapAndDistribute(swapTokensAtAmount);
            swapping = false;
        }
        uint256 senderBalance = _balances[from];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        if(isExcludedFromDividends[from]) {
            totalExcludedDividendBalance -= amount;
        }
        _balances[from] = senderBalance - amount;
        uint256 amountReceived = amount;
        bool takeFee = !(isExcludedFromFees[from] || isExcludedFromFees[to]);
        if (takeFee) {
            uint256 fees = (amount * totalFee) / 100;
            amountReceived = amount - fees;
            _balances[address(this)] += fees;
            if(isExcludedFromDividends[address(this)]) {
                totalExcludedDividendBalance += fees;
            }
            emit Transfer(from, address(this), fees);
        }
        _balances[to] += amountReceived;
        if(isExcludedFromDividends[to]) {
            totalExcludedDividendBalance += amountReceived;
        }
        emit Transfer(from, to, amountReceived);
        if(address(dividendVault) != address(0)) {
            if(!isExcludedFromDividends[from]) try dividendVault.setBalance(from, _balances[from]) {} catch {}
            if(!isExcludedFromDividends[to]) try dividendVault.setBalance(to, _balances[to]) {} catch {}
            if(takeFee && !isExcludedFromDividends[address(this)]) try dividendVault.setBalance(address(this), _balances[address(this)]) {} catch {}
            try dividendVault.updateSupply(_totalSupply - totalExcludedDividendBalance) {} catch {}
        }
    }
    function swapAndDistribute(uint256 tokens) private {
        uint256 initialETH = address(this).balance;
        swapTokensForEth(tokens);
        uint256 newETH = address(this).balance - initialETH;
        if(totalFee == 0) return;
        uint256 opsFees = marketingFee + devFee + charityFee;
        uint256 opsPart = 0;
        if(totalFee > 0) {
           opsPart = (newETH * opsFees) / totalFee;
        }
        uint256 rewardPart = newETH - opsPart;
        if(opsFees > 0) {
            uint256 marketingPart = (opsPart * marketingFee) / opsFees;
            uint256 devPart = (opsPart * devFee) / opsFees;
            uint256 charityPart = opsPart - marketingPart - devPart;
            if(marketingFee > 0) {
                (bool success, ) = payable(marketingWallet).call{value: marketingPart}("");
                require(success, "Mkt Transfer Failed");
            }
            if(devFee > 0) {
                (bool success, ) = payable(devWallet).call{value: devPart}("");
                require(success, "Dev Transfer Failed");
            }
            if(charityFee > 0) {
                (bool success, ) = payable(charityWallet).call{value: charityPart}("");
                require(success, "Charity Transfer Failed");
            }
        }
        if(rewardPart > 0) {
            swapEthForXautV3(rewardPart);
        }
    }
    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount, 0, path, address(this), block.timestamp
        );
    }
    function swapEthForXautV3(uint256 ethAmount) private {
        IWETH(WETH_ADDRESS).deposit{value: ethAmount}();
        bytes memory path = abi.encodePacked(
            WETH_ADDRESS,
            uint24(500),
            USDT_ADDRESS,
            uint24(3000),
            XAUT_ADDRESS
        );
        ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
            path: path,
            recipient: address(dividendVault),
            deadline: block.timestamp,
            amountIn: ethAmount,
            amountOutMinimum: 0
        });
        uint256 balanceBefore = IERC20(XAUT_ADDRESS).balanceOf(address(dividendVault));
        try uniswapV3Router.exactInput(params) {
            uint256 balanceAfter = IERC20(XAUT_ADDRESS).balanceOf(address(dividendVault));
            if(balanceAfter > balanceBefore) {
                uint256 newDividends = balanceAfter - balanceBefore;
                dividendVault.depositDividends(newDividends);
            }
        } catch {
        }
    }
    function rescueStuckTokens(address _token) external onlyOwner {
        require(_token != XAUT_ADDRESS, "Cannot withdraw dividend token");
        IERC20(_token).transfer(msg.sender, IERC20(_token).balanceOf(address(this)));
    }
    function rescueStuckETH() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "ETH Transfer failed");
    }
    function getClaimableXAUT(address account) external view returns (uint256) {
        return dividendVault.withdrawableDividendOf(account);
    }
    function claimXAUT() external {
        dividendVault.claim();
    }
}