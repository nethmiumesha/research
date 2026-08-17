pragma solidity ^0.8.4;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../external/Decimal.sol";
import "@uniswap/lib/contracts/libraries/FixedPoint.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract MockUniswapV2PairLiquidity {
    using SafeMath for uint256;
    using Decimal for Decimal.D256;
    uint112 private reserve0;
    uint112 private reserve1;
    uint256 private liquidity;
    address public token0;
    address public token1;
    constructor(address _token0, address _token1) {
        token0 = _token0;
        token1 = _token1;
    }
    function getReserves() external view returns (uint112, uint112, uint32) {
        return (reserve0, reserve1, 0);
    }
    function mint(address to) public returns (uint) {
        _mint(to, liquidity);
        return liquidity;
    }
    function mintAmount(address to, uint256 _liquidity) public payable {
        _mint(to, _liquidity);
    }
    function set(uint112 newReserve0, uint112 newReserve1, uint256 newLiquidity) external payable {
        reserve0 = newReserve0;
        reserve1 = newReserve1;
        liquidity = newLiquidity;
        mint(msg.sender);
    }
    function setReserves(uint112 newReserve0, uint112 newReserve1) external {
        reserve0 = newReserve0;
        reserve1 = newReserve1;
    }
    function faucet(address account, uint256 amount) external returns (bool) {
        _mint(account, amount);
        return true;
    }
    function burnEth(address to, Decimal.D256 memory ratio) public returns(uint256 amountEth, uint256 amount1) {
        uint256 balanceEth = address(this).balance;
        amountEth = ratio.mul(balanceEth).asUint256();
        payable(to).transfer(amountEth);
        uint256 balance1 = reserve1;
        amount1 = ratio.mul(balance1).asUint256();
        IERC20(token1).transfer(to, amount1);
    }
    function withdrawFei(address to, uint256 amount) public {
        IERC20(token1).transfer(to, amount);
    }
    function burnToken(address to, Decimal.D256 memory ratio) public returns(uint256 amount0, uint256 amount1) {
        uint256 balance0 = reserve0;
        amount0 = ratio.mul(balance0).asUint256();
        IERC20(token0).transfer(to, amount0);
        uint256 balance1 = reserve1;
        amount1 = ratio.mul(balance1).asUint256();
        IERC20(token1).transfer(to, amount1);
    }
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata) external {
        if (amount0Out != 0) {
            IERC20(token0).transfer(to, amount0Out);
        }
        if (amount1Out != 0) {
            IERC20(token1).transfer(to, amount1Out);
        }
    }
    function sync() external { }
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
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
    }
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
    }
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
    }
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
    }
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}