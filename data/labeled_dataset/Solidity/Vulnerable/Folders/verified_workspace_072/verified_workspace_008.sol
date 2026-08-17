pragma solidity 0.5.16;
import "openzeppelin-solidity-2.3.0/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity-2.3.0/contracts/math/SafeMath.sol";
import "openzeppelin-solidity-2.3.0/contracts/utils/ReentrancyGuard.sol";
import "openzeppelin-solidity-2.3.0/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/libraries/Math.sol";
import "./uniswap/IUniswapV2Router02.sol";
import "./Strategy.sol";
import "./SafeToken.sol";
import "./Goblin.sol";
import "./interfaces/IMasterChef.sol";
contract MasterChefPoolRewardPairGoblin is Ownable, ReentrancyGuard, Goblin {
    using SafeToken for address;
    using SafeMath for uint256;
    event Reinvest(address indexed caller, uint256 reward, uint256 bounty);
    event AddShare(uint256 indexed id, uint256 share);
    event RemoveShare(uint256 indexed id, uint256 share);
    event Liquidate(uint256 indexed id, uint256 wad);
    IMasterChef public masterChef;
    IUniswapV2Factory public factory;
    IUniswapV2Router02 public router;
    IUniswapV2Pair public lpToken;
    address public weth;
    address public rewardToken;
    address public operator;
    uint256 public constant pid = 12;
    mapping(uint256 => uint256) public shares;
    mapping(address => bool) public okStrats;
    uint256 public totalShare;
    Strategy public addStrat;
    Strategy public liqStrat;
    uint256 public reinvestBountyBps;
    constructor(
        address _operator,
        IMasterChef _masterChef,
        IUniswapV2Router02 _router,
        Strategy _addStrat,
        Strategy _liqStrat,
        uint256 _reinvestBountyBps
    ) public {
        operator = _operator;
        weth = _router.WETH();
        masterChef = _masterChef;
        router = _router;
        factory = IUniswapV2Factory(_router.factory());
        (IERC20 _lpToken, , , ) = masterChef.poolInfo(pid);
        lpToken = IUniswapV2Pair(address(_lpToken));
        rewardToken = address(masterChef.cake());
        addStrat = _addStrat;
        liqStrat = _liqStrat;
        okStrats[address(addStrat)] = true;
        okStrats[address(liqStrat)] = true;
        reinvestBountyBps = _reinvestBountyBps;
        lpToken.approve(address(_masterChef), uint256(-1));
        lpToken.approve(address(router), uint256(-1));
        rewardToken.safeApprove(address(router), uint256(-1));
    }
    modifier onlyEOA() {
        require(msg.sender == tx.origin, "not eoa");
        _;
    }
    modifier onlyOperator() {
        require(msg.sender == operator, "not operator");
        _;
    }
    function shareToBalance(uint256 share) public view returns (uint256) {
        if (totalShare == 0) return share;
        (uint256 totalBalance, ) = masterChef.userInfo(pid, address(this));
        return share.mul(totalBalance).div(totalShare);
    }
    function balanceToShare(uint256 balance) public view returns (uint256) {
        if (totalShare == 0) return balance;
        (uint256 totalBalance, ) = masterChef.userInfo(pid, address(this));
        return balance.mul(totalShare).div(totalBalance);
    }
    function reinvest() public onlyEOA nonReentrant {
        masterChef.withdraw(pid, 0);
        uint256 reward = rewardToken.balanceOf(address(this));
        if (reward == 0) return;
        uint256 bounty = reward.mul(reinvestBountyBps) / 10000;
        rewardToken.safeTransfer(msg.sender, bounty);
        rewardToken.safeTransfer(address(addStrat), reward.sub(bounty));
        addStrat.execute(address(this), 0, abi.encode(rewardToken, 0, 0));
        masterChef.deposit(pid, lpToken.balanceOf(address(this)));
        emit Reinvest(msg.sender, reward, bounty);
    }
    function work(uint256 id, address user, uint256 debt, bytes calldata data)
        external payable
        onlyOperator nonReentrant
    {
        _removeShare(id);
        (address strat, bytes memory ext) = abi.decode(data, (address, bytes));
        require(okStrats[strat], "unapproved work strategy");
        lpToken.transfer(strat, lpToken.balanceOf(address(this)));
        Strategy(strat).execute.value(msg.value)(user, debt, ext);
        _addShare(id);
        SafeToken.safeTransferETH(msg.sender, address(this).balance);
    }
    function getMktSellAmount(uint256 aIn, uint256 rIn, uint256 rOut) public pure returns (uint256) {
        if (aIn == 0) return 0;
        require(rIn > 0 && rOut > 0, "bad reserve values");
        uint256 aInWithFee = aIn.mul(997);
        uint256 numerator = aInWithFee.mul(rOut);
        uint256 denominator = rIn.mul(1000).add(aInWithFee);
        return numerator / denominator;
    }
    function health(uint256 id) external view returns (uint256) {
        uint256 lpBalance = shareToBalance(shares[id]);
        uint256 lpSupply = lpToken.totalSupply();
        (uint256 r0, uint256 r1,) = lpToken.getReserves();
        (uint256 totalWETH, uint256 totalSushi) = lpToken.token0() == weth ? (r0, r1) : (r1, r0);
        uint256 userWETH = lpBalance.mul(totalWETH).div(lpSupply);
        uint256 userSushi = lpBalance.mul(totalSushi).div(lpSupply);
        return getMktSellAmount(
            userSushi, totalSushi.sub(userSushi), totalWETH.sub(userWETH)
        ).add(userWETH);
    }
    function liquidate(uint256 id) external onlyOperator nonReentrant {
        _removeShare(id);
        lpToken.transfer(address(liqStrat), lpToken.balanceOf(address(this)));
        liqStrat.execute(address(0), 0, abi.encode(rewardToken, 0));
        uint256 wad = address(this).balance;
        SafeToken.safeTransferETH(msg.sender, wad);
        emit Liquidate(id, wad);
    }
    function _addShare(uint256 id) internal {
        uint256 balance = lpToken.balanceOf(address(this));
        if (balance > 0) {
            uint256 share = balanceToShare(balance);
            masterChef.deposit(pid, balance);
            shares[id] = shares[id].add(share);
            totalShare = totalShare.add(share);
            emit AddShare(id, share);
        }
    }
    function _removeShare(uint256 id) internal {
        uint256 share = shares[id];
        if (share > 0) {
            uint256 balance = shareToBalance(share);
            masterChef.withdraw(pid, balance);
            totalShare = totalShare.sub(share);
            shares[id] = 0;
            emit RemoveShare(id, share);
        }
    }
    function recover(address token, address to, uint256 value) external onlyOwner nonReentrant {
        token.safeTransfer(to, value);
    }
    function setReinvestBountyBps(uint256 _reinvestBountyBps) external onlyOwner {
        reinvestBountyBps = _reinvestBountyBps;
    }
    function setStrategyOk(address[] calldata strats, bool isOk) external onlyOwner {
        uint256 len = strats.length;
        for (uint256 idx = 0; idx < len; idx++) {
            okStrats[strats[idx]] = isOk;
        }
    }
    function setCriticalStrategies(Strategy _addStrat, Strategy _liqStrat) external onlyOwner {
        addStrat = _addStrat;
        liqStrat = _liqStrat;
    }
    function() external payable {}
}