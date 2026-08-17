pragma solidity =0.7.6;
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
interface IUniswapV3FlashCallback {
    function uniswapV3FlashCallback(
        uint256 fee0,
        uint256 fee1,
        bytes calldata data
    ) external;
}
contract MockUniswapV3Pool {
    using SafeMath for uint256;
    address public token0;
    address public token1;
    uint256 public fee;
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }
    struct Slot0 {
        uint160 sqrtPriceX96;
        int24 tick;
        uint16 observationIndex;
        uint16 observationCardinality;
        uint16 observationCardinalityNext;
        uint8 feeProtocol;
        bool unlocked;
    }
    Slot0 public slot0;
    function setPoolTokens(address _token0, address _token1) external {
        token0 = _token0;
        token1 = _token1;
    }
    function setSlot0Data(uint160 _sqrtPriceX96, int24 _tick) external {
        slot0.sqrtPriceX96 = _sqrtPriceX96;
        slot0.tick = _tick;
    }
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external {
        uint256 fee0 = 0;
        uint256 fee1 = 0;
        uint256 balance0Before = ERC20(token0).balanceOf(address(this));
        uint256 balance1Before = ERC20(token1).balanceOf(address(this));
        if (amount0 > 0) ERC20(token0).transfer(recipient, amount0);
        if (amount1 > 0) ERC20(token1).transfer(recipient, amount1);
        IUniswapV3FlashCallback(msg.sender).uniswapV3FlashCallback(fee0, fee1, data);
        uint256 balance0After = ERC20(token0).balanceOf(address(this));
        uint256 balance1After = ERC20(token1).balanceOf(address(this));
        require(balance0Before.add(fee0) <= balance0After, "F0");
        require(balance1Before.add(fee1) <= balance1After, "F1");
    }
    function computeAddress(
        address,
        PoolKey memory
    ) internal view returns (address pool) {
        return address(this);
    }
}