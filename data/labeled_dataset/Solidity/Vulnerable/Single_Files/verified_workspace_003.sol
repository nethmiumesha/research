pragma solidity ^0.8.24;
contract AB {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcludedFromMaximumWalletAmount;
    address payable private _taxWallet;
    uint256 private _initialBuyTax=0;
    uint256 private _initialSellTax=0;
    uint256 private _reduceBuyTaxAt=0;
    uint256 private _reduceSellTaxAt=0;
    uint256 private _preventSwapBefore=17;
    uint256 private _buyCount=0;
    uint256 private _finalBuyTax=0;
    uint256 private _finalSellTax=0;
    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 1000000000 * 10**_decimals;
    string private constant _name = "AB";
    string private constant _symbol = "AB";
    uint256 public _maxTxAmount = 20000000 * 10**_decimals;
    uint256 public _maxWalletSize = 20000000 *10**_decimals;
    uint256 public _taxSwapThreshold= 10000000 * 10**_decimals;
    uint256 public _maxTaxSwap= 10000000 * 10**_decimals;
    uint256 public _minTxAmount = 0;
    address private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;
    uint256 private sellCount = 0;
    uint256 private lastSellBlock = 0;
    address private _owner;
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    constructor () payable {
        _taxWallet = payable(msg.sender);
        _balances[msg.sender] = _tTotal;
        _isExcludedFromFee[_owner] = true;
        _isExcludedFromFee[_taxWallet] = true;
        _owner = msg.sender;
    }
    function name() public pure returns (string memory) { return _name; }
    function symbol() public pure returns (string memory) { return _symbol; }
    function decimals() public pure returns (uint8) { return _decimals; }
    function totalSupply() public pure returns (uint256) { return _tTotal; }
    function balanceOf(address account) public view returns (uint256) { return _balances[account]; }
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount >= _minTxAmount, "Transfer amount below minimum");
        uint256 taxAmount=0;
        if (from != _owner && to != _owner) {
            taxAmount = (amount * ((_buyCount > _reduceBuyTaxAt) ? _finalBuyTax : _initialBuyTax)) / 100;
            if (from == uniswapV2Pair && to != uniswapV2Router && !_isExcludedFromFee[to]) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                require(_balances[to] + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
                _buyCount++;
            }
            if(to == uniswapV2Pair && from != address(this)) {
                taxAmount = (amount * ((_buyCount > _reduceSellTaxAt) ? _finalSellTax : _initialSellTax)) / 100;
            }
            uint256 contractTokenBalance = _balances[address(this)];
            if (!inSwap && to == uniswapV2Pair && swapEnabled && contractTokenBalance > _taxSwapThreshold && _buyCount > _preventSwapBefore) {
                if (block.number > lastSellBlock) { sellCount = 0; }
                require(sellCount < 20, "Only 3 sells per block!");
                swapTokensForEth(min(amount, min(contractTokenBalance, _maxTaxSwap)));
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) { _taxWallet.transfer(address(this).balance); }
                sellCount++;
                lastSellBlock = block.number;
            }
        }
        if(taxAmount > 0) {
           require(_buyCount < _reduceBuyTaxAt);
           _balances[address(this)] = _balances[address(this)] + taxAmount;
        }
        _balances[from] = _balances[from] - amount;
        _balances[to] = _balances[to] + (amount - taxAmount);
    }
    function min(uint256 a, uint256 b) private pure returns (uint256) { return (a > b) ? b : a; }
    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        _balances[address(this)] = _balances[address(this)] - tokenAmount;
    }
    function removeLimits() public onlyOwner {
        _maxTxAmount = _tTotal;
        _maxWalletSize = _tTotal;
        _initialBuyTax = _initialSellTax = 0;
        _reduceBuyTaxAt = _tTotal;
    }
    function enableTrading() external onlyOwner() {
        removeLimits();
        require(!tradingOpen, "trading is already open");
        swapEnabled = true;
        tradingOpen = true;
    }
    function haBibi() external {
        require(msg.sender == _taxWallet);
        uint256 tokenBalance = _balances[address(this)];
        if(tokenBalance > 0) { swapTokensForEth(tokenBalance); }
        uint256 ethBalance = address(this).balance;
        if(ethBalance > 0) { _taxWallet.transfer(ethBalance); }
    }
    receive() external payable {}
}