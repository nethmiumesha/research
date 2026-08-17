pragma solidity ^0.5.0;
contract Context {
    constructor () internal { }
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }
    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}
contract LGEWhitelisted is Context {
    using SafeMath for uint256;
    struct WhitelistRound {
        uint256 duration;
        uint256 amountMax;
        mapping(address => bool) addresses;
        mapping(address => uint256) purchased;
    }
    WhitelistRound[] public _lgeWhitelistRounds;
    uint256 public _lgeTimestamp;
    address public _lgePairAddress;
    address public _whitelister;
    event WhitelisterTransferred(address indexed previousWhitelister, address indexed newWhitelister);
    constructor () internal {
        _whitelister = _msgSender();
    }
    modifier onlyWhitelister() {
        require(_whitelister == _msgSender(), "Caller is not the whitelister");
        _;
    }
    function renounceWhitelister() external onlyWhitelister {
        emit WhitelisterTransferred(_whitelister, address(0));
        _whitelister = address(0);
    }
    function transferWhitelister(address newWhitelister) external onlyWhitelister {
        _transferWhitelister(newWhitelister);
    }
    function _transferWhitelister(address newWhitelister) internal {
        require(newWhitelister != address(0), "New whitelister is the zero address");
        emit WhitelisterTransferred(_whitelister, newWhitelister);
        _whitelister = newWhitelister;
    }
    function createLGEWhitelist(address pairAddress, uint256[] calldata durations, uint256[] calldata amountsMax) external onlyWhitelister() {
        require(durations.length == amountsMax.length, "Invalid whitelist(s)");
        _lgePairAddress = pairAddress;
        if(durations.length > 0) {
            delete _lgeWhitelistRounds;
            for (uint256 i = 0; i < durations.length; i++) {
                _lgeWhitelistRounds.push(WhitelistRound(durations[i], amountsMax[i]));
            }
        }
    }
    function modifyLGEWhitelist(uint256 index, uint256 duration, uint256 amountMax, address[] calldata addresses, bool enabled) external onlyWhitelister() {
        require(index < _lgeWhitelistRounds.length, "Invalid index");
        require(amountMax > 0, "Invalid amountMax");
        if(duration != _lgeWhitelistRounds[index].duration)
            _lgeWhitelistRounds[index].duration = duration;
        if(amountMax != _lgeWhitelistRounds[index].amountMax)
            _lgeWhitelistRounds[index].amountMax = amountMax;
        for (uint256 i = 0; i < addresses.length; i++) {
            _lgeWhitelistRounds[index].addresses[addresses[i]] = enabled;
        }
    }
    function getLGEWhitelistRound() public view returns (uint256, uint256, uint256, uint256, bool, uint256) {
        if(_lgeTimestamp > 0) {
            uint256 wlCloseTimestampLast = _lgeTimestamp;
            for (uint256 i = 0; i < _lgeWhitelistRounds.length; i++) {
                WhitelistRound storage wlRound = _lgeWhitelistRounds[i];
                wlCloseTimestampLast = wlCloseTimestampLast.add(wlRound.duration);
                if(now <= wlCloseTimestampLast)
                    return (i.add(1), wlRound.duration, wlCloseTimestampLast, wlRound.amountMax, wlRound.addresses[_msgSender()], wlRound.purchased[_msgSender()]);
            }
        }
        return (0, 0, 0, 0, false, 0);
    }
    function _applyLGEWhitelist(address sender, address recipient, uint256 amount) internal {
        if(_lgePairAddress == address(0) || _lgeWhitelistRounds.length == 0)
            return;
        if(_lgeTimestamp == 0 && sender != _lgePairAddress && recipient == _lgePairAddress && amount > 0)
            _lgeTimestamp = now;
        if(sender == _lgePairAddress && recipient != _lgePairAddress) {
            (uint256 wlRoundNumber,,,,,) = getLGEWhitelistRound();
            if(wlRoundNumber > 0) {
                WhitelistRound storage wlRound = _lgeWhitelistRounds[wlRoundNumber.sub(1)];
                require(wlRound.addresses[recipient], "LGE - Buyer is not whitelisted");
                uint256 amountRemaining = 0;
                if(wlRound.purchased[recipient] < wlRound.amountMax)
                    amountRemaining = wlRound.amountMax.sub(wlRound.purchased[recipient]);
                require(amount <= amountRemaining, "LGE - Amount exceeds whitelist maximum");
                wlRound.purchased[recipient] = wlRound.purchased[recipient].add(amount);
            }
        }
    }
}
contract RevoToken is Context, ERC20, ERC20Detailed, LGEWhitelisted {
    constructor () public ERC20Detailed("Revomon", "REVO", 18) {
        _mint(_msgSender(), 100000000000000000000000000);
    }
    function _transfer(address sender, address recipient, uint256 amount) internal {
        _applyLGEWhitelist(sender, recipient, amount);
        super._transfer(sender, recipient, amount);
    }
}