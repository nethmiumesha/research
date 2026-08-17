pragma solidity 0.5.16;
import 'openzeppelin-solidity-2.3.0/contracts/ownership/Ownable.sol';
import 'openzeppelin-solidity-2.3.0/contracts/utils/ReentrancyGuard.sol';
import 'openzeppelin-solidity-2.3.0/contracts/math/SafeMath.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import './uniswap/IUniswapV2Router02.sol';
import './SafeToken.sol';
import './Strategy.sol';
contract StrategyWithdrawMinimizeTrading is Ownable, ReentrancyGuard, Strategy {
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
    function execute(address user, uint256 debt, bytes calldata data) external payable nonReentrant {
        (address fToken, uint256 minFToken) = abi.decode(data, (address, uint256));
        IUniswapV2Pair lpToken = IUniswapV2Pair(factory.getPair(fToken, weth));
        lpToken.approve(address(router), uint256(-1));
        router.removeLiquidityETH(fToken, lpToken.balanceOf(address(this)), 0, 0, address(this), now);
        address[] memory path = new address[](2);
        path[0] = fToken;
        path[1] = weth;
        fToken.safeApprove(address(router), 0);
        fToken.safeApprove(address(router), uint256(-1));
        uint256 balance = address(this).balance;
        if (debt > balance) {
            uint256 remainingDebt = debt.sub(balance);
            router.swapTokensForExactETH(remainingDebt, fToken.myBalance(), path, address(this), now);
        }
        uint256 remainingBalance = address(this).balance;
        SafeToken.safeTransferETH(msg.sender, remainingBalance);
        uint256 remainingFToken = fToken.myBalance();
        require(remainingFToken >= minFToken, 'insufficient farming tokens received');
        if (remainingFToken > 0) {
            fToken.safeTransfer(user, remainingFToken);
        }
    }
    function recover(address token, address to, uint256 value) external onlyOwner nonReentrant {
        token.safeTransfer(to, value);
    }
    function() external payable {}
}