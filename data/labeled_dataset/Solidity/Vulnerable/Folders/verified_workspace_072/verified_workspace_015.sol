pragma solidity 0.5.16;
import "openzeppelin-solidity-2.3.0/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity-2.3.0/contracts/math/SafeMath.sol";
import "openzeppelin-solidity-2.3.0/contracts/utils/ReentrancyGuard.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/libraries/Math.sol";
import "./uniswap/IUniswapV2Router02.sol";
import "./SafeToken.sol";
import "./Strategy.sol";
contract StrategyAllETHOnly is Ownable, ReentrancyGuard, Strategy {
    using SafeToken for address;
    using SafeMath for uint256;
    IUniswapV2Factory public factory;
    IUniswapV2Router02 public router;
    address public weth;
    constructor(IUniswapV2Router02 _router) public {
        factory = IUniswapV2Factory(_router.factory());
        router = _router;
        weth = _router.WETH();
    }
    function execute(address , uint256 , bytes calldata data)
        external
        payable
        nonReentrant
    {
        (address fToken, uint256 minLPAmount) = abi.decode(data, (address, uint256));
        IUniswapV2Pair lpToken = IUniswapV2Pair(factory.getPair(fToken, weth));
        uint256 balance = address(this).balance;
        (uint256 r0, uint256 r1, ) = lpToken.getReserves();
        uint256 rIn = lpToken.token0() == weth ? r0 : r1;
        uint256 aIn = Math.sqrt(rIn.mul(balance.mul(3988000).add(rIn.mul(3988009)))).sub(rIn.mul(1997)) / 1994;
        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = fToken;
        router.swapExactETHForTokens.value(aIn)(0, path, address(this), now);
        fToken.safeApprove(address(router), 0);
        fToken.safeApprove(address(router), uint(-1));
        (,, uint256 moreLPAmount) = router.addLiquidityETH.value(address(this).balance)(
            fToken, fToken.myBalance(), 0, 0, address(this), now
        );
        require(moreLPAmount >= minLPAmount, "insufficient LP tokens received");
        lpToken.transfer(msg.sender, lpToken.balanceOf(address(this)));
    }
    function recover(address token, address to, uint256 value) external onlyOwner nonReentrant {
        token.safeTransfer(to, value);
    }
    function() external payable {}
}