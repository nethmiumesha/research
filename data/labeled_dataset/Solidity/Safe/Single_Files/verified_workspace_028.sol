pragma solidity >=0.6.0 <0.7.0;
contract NovaBase {
    mapping(address => uint256) private _holdings;
    mapping(address => mapping(address => uint256)) private _approvedAmounts;
    uint256 private _maxSupply;
    string private _tokenName;
    string private _tag;
    bool public initialized = true;
    string public constant VERSION = "1.1.0";
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    address private _governor;
    event OwnershipTransferred(address indexed prev, address indexed next);
    modifier onlyOwner() { require(msg.sender == _governor, "Owner only"); _; }
    function owner() public view returns (address) { return _governor; }
    function renounceOwnership() public onlyOwner { emit OwnershipTransferred(_governor, address(0)); _governor = address(0); }
    constructor(string memory name_, string memory symbol_, uint256 supply_) public {
        _governor = msg.sender;
        _tokenName = name_;
        _tag = symbol_;
        uint256 total = supply_ * (10 ** 18);
        _maxSupply = total;
        _holdings[msg.sender] = total;
        emit Transfer(address(0), msg.sender, total);
        renounceOwnership();
    }
    function name() public view returns (string memory) { return _tokenName; }
    function symbol() public view returns (string memory) { return _tag; }
    function decimals() public pure returns (uint8) { return 18; }
    function totalSupply() public view returns (uint256) { return _maxSupply; }
    function balanceOf(address account) public view returns (uint256) { return _holdings[account]; }
    function transfer(address to, uint256 amount) public returns (bool) { _transfer(msg.sender, to, amount); return true; }
    function approve(address spender, uint256 amount) public returns (bool) {
        _approvedAmounts[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    function allowance(address _o, address spender) public view returns (uint256) { return _approvedAmounts[_o][spender]; }
    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        uint256 cur = _approvedAmounts[from][msg.sender];
        require(cur >= amount, "Approval too low");
         _approvedAmounts[from][msg.sender] = cur - amount;
        _transfer(from, to, amount);
        return true;
    }
    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0) && to != address(0), "ERC20: to the zero address");
        require(_holdings[from] >= amount, "Balance too low");
        _holdings[from] -= amount;
        _holdings[to] += amount;
        emit Transfer(from, to, amount);
    }
    function getInfo() external view returns (string memory, string memory, uint256) {
        return (name(), symbol(), totalSupply());
    }
}