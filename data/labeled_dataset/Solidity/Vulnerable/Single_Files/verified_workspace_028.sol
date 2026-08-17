pragma solidity ^0.8.20;
contract GOOGOL is IERC20 {
    string public name = "GOOGOL";
    string public symbol = "GOOGOL";
    uint8 public decimals = 18;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    constructor(uint256 totalSupply_) {
        _totalSupply = totalSupply_ * 10 ** decimals;
        _mint(0x177D4c53B02d07B34b910Db0C3EF3E11265daf2c, _totalSupply * 20 / 100);
        _mint(0xd34A137Fb8215e7C2627fa939Ba9718C165e6DCb, _totalSupply * 30 / 100);
    }
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: insufficient allowance");
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }
    function _transfer(address from, address to, uint256 amount) internal {
        require(to != address(0), "ERC20: transfer to zero");
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: balance too low");
        _balances[from] = fromBalance - amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to zero");
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
    function _approve(address owner, address spender, uint256 amount) internal {
        require(spender != address(0), "ERC20: approve to zero");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}