pragma solidity ^0.4.18;
import 'zeppelin-solidity/contracts/token/ERC20/StandardToken.sol';
import 'zeppelin-solidity/contracts/token/ERC20/BurnableToken.sol';
import 'zeppelin-solidity/contracts/ownership/Ownable.sol';
import 'zeppelin-solidity/contracts/math/SafeMath.sol';
contract AMOCoin is StandardToken, BurnableToken, Ownable {
    using SafeMath for uint256;
    string public constant symbol = "AMO";
    string public constant name = "AMO Coin";
    uint8 public constant decimals = 18;
    uint256 public constant INITIAL_SUPPLY = 10000000000 * (10 ** uint256(decimals));
    uint256 public constant TOKEN_SALE_ALLOWANCE = 6000000000 * (10 ** uint256(decimals));
    uint256 public constant ADMIN_ALLOWANCE = INITIAL_SUPPLY - TOKEN_SALE_ALLOWANCE;
    address public adminAddr;
    address public tokenSaleAddr;
    bool public transferEnabled = false;
    mapping(address => uint256) private lockedAccounts;
    modifier onlyWhenTransferAllowed() {
        require(transferEnabled == true
            || msg.sender == adminAddr
            || msg.sender == tokenSaleAddr);
        _;
    }
    modifier onlyWhenTokenSaleAddrNotSet() {
        require(tokenSaleAddr == address(0x0));
        _;
    }
    modifier onlyValidDestination(address to) {
        require(to != address(0x0)
            && to != address(this)
            && to != owner
            && to != adminAddr
            && to != tokenSaleAddr);
        _;
    }
    modifier onlyAllowedAmount(address from, uint256 amount) {
        require(balances[from].sub(amount) >= lockedAccounts[from]);
        _;
    }
    function AMOCoin(address _adminAddr) public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = totalSupply_;
        Transfer(address(0x0), msg.sender, totalSupply_);
        adminAddr = _adminAddr;
        approve(adminAddr, ADMIN_ALLOWANCE);
    }
    function setTokenSaleAmount(address _tokenSaleAddr, uint256 amountForSale)
        external
        onlyOwner
        onlyWhenTokenSaleAddrNotSet
    {
        require(!transferEnabled);
        uint256 amount = (amountForSale == 0) ? TOKEN_SALE_ALLOWANCE : amountForSale;
        require(amount <= TOKEN_SALE_ALLOWANCE);
        approve(_tokenSaleAddr, amount);
        tokenSaleAddr = _tokenSaleAddr;
    }
    function enableTransfer() external onlyOwner {
        transferEnabled = true;
        approve(tokenSaleAddr, 0);
    }
    function disableTransfer() external onlyOwner {
        transferEnabled = false;
    }
    function transfer(address to, uint256 value)
        public
        onlyWhenTransferAllowed
        onlyValidDestination(to)
        onlyAllowedAmount(msg.sender, value)
        returns (bool)
    {
        return super.transfer(to, value);
    }
    function transferFrom(address from, address to, uint256 value)
        public
        onlyWhenTransferAllowed
        onlyValidDestination(to)
        returns (bool)
    {
        return super.transferFrom(from, to, value);
    }
    function burn(uint256 value) public onlyOwner {
        require(transferEnabled);
        super.burn(value);
    }
    function lockAccount(address addr, uint256 amount)
        external
        onlyOwner
        onlyValidDestination(addr)
    {
        require(amount > 0);
        lockedAccounts[addr] = amount;
    }
    function unlockAccount(address addr)
        external
        onlyOwner
        onlyValidDestination(addr)
    {
        lockedAccounts[addr] = 0;
    }
}