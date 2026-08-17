pragma solidity ^0.6.10;
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../helpers/DecimalMath.sol";
import "../interfaces/IVat.sol";
import "../interfaces/IGemJoin.sol";
import "../interfaces/IDaiJoin.sol";
import "../interfaces/IPot.sol";
import "../interfaces/IChai.sol";
import "../interfaces/IYDai.sol";
import "../interfaces/IController.sol";
import "../interfaces/IPool.sol";
import "../interfaces/IFlashMinter.sol";
contract Splitter is IFlashMinter, DecimalMath {
    bytes32 public constant WETH = "ETH-A";
    bool constant public MTY = true;
    bool constant public YTM = false;
    IVat public vat;
    IERC20 public weth;
    IERC20 public dai;
    IGemJoin public wethJoin;
    IDaiJoin public daiJoin;
    IYDai public yDai;
    IController public controller;
    IPool public pool;
    constructor(
        address vat_,
        address weth_,
        address dai_,
        address wethJoin_,
        address daiJoin_,
        address treasury_,
        address yDai_,
        address controller_,
        address pool_
    ) public {
        vat = IVat(vat_);
        weth = IERC20(weth_);
        dai = IERC20(dai_);
        wethJoin = IGemJoin(wethJoin_);
        daiJoin = IDaiJoin(daiJoin_);
        yDai = IYDai(yDai_);
        controller = IController(controller_);
        pool = IPool(pool_);
        vat.hope(daiJoin_);
        vat.hope(wethJoin_);
        dai.approve(pool_, uint256(-1));
        yDai.approve(pool_, uint256(-1));
        dai.approve(daiJoin_, uint(-1));
        weth.approve(wethJoin_, uint(-1));
        weth.approve(treasury_, uint(-1));
    }
    function toInt256(uint256 x) internal pure returns(int256) {
        require(
            x <= 57896044618658097711785492504343953926634992332820282019728792003956564819967,
            "Treasury: Cast overflow"
        );
        return int256(x);
    }
    function toUint128(uint256 x) internal pure returns(uint128) {
        require(
            x <= 340282366920938463463374607431768211455,
            "Pool: Cast overflow"
        );
        return uint128(x);
    }
    function makerToYield(address user, uint256 wethAmount, uint256 daiAmount) public {
        (uint256 ink, uint256 art) = vat.urns(WETH, user);
        (, uint256 rate,,,) = vat.ilks("ETH-A");
        require(
            daiAmount <= muld(art, rate),
            "Splitter: Not enough debt in Maker"
        );
        require(
            wethAmount <= ink,
            "Splitter: Not enough collateral in Maker"
        );
        yDai.flashMint(
            address(this),
            yDaiForDai(daiAmount),
            abi.encode(MTY, user, wethAmount, daiAmount)
        );
    }
    function yieldToMaker(address user, uint256 yDaiAmount, uint256 wethAmount) public {
        require(
            yDaiAmount <= controller.debtYDai(WETH, yDai.maturity(), user),
            "Splitter: Not enough debt in Yield"
        );
        require(
            wethAmount <= controller.posted(WETH, user),
            "Splitter: Not enough collateral in Yield"
        );
        yDai.flashMint(
            address(this),
            yDaiAmount,
            abi.encode(YTM, user, wethAmount, 0)
        );
    }
    function executeOnFlashMint(address, uint256 yDaiAmount, bytes calldata data) external override {
        (bool direction, address user, uint256 wethAmount, uint256 daiAmount) = abi.decode(data, (bool, address, uint256, uint256));
        if(direction == MTY) _makerToYield(user, wethAmount, daiAmount);
        if(direction == YTM) _yieldToMaker(user, yDaiAmount, wethAmount);
    }
    function wethForDai(uint256 daiAmount) public view returns (uint256) {
        (,, uint256 spot,,) = vat.ilks("ETH-A");
        return divd(daiAmount, spot);
    }
    function wethForYDai(uint256 yDaiAmount) public view returns (uint256) {
        (,, uint256 spot,,) = vat.ilks("ETH-A");
        return divd(yDaiAmount, spot);
    }
    function yDaiForDai(uint256 daiAmount) public view returns (uint256) {
        return pool.buyDaiPreview(toUint128(daiAmount));
    }
    function daiForYDai(uint256 yDaiAmount) public view returns (uint256) {
        return pool.buyYDaiPreview(toUint128(yDaiAmount));
    }
    function _makerToYield(address user, uint256 wethAmount, uint256 daiAmount) internal {
        uint256 yDaiSold = pool.buyDai(address(this), address(this), toUint128(daiAmount));
        daiJoin.join(user, daiAmount);
        (, uint256 rate,,,) = vat.ilks("ETH-A");
        vat.frob(
            "ETH-A",
            user,
            user,
            user,
            -toInt256(wethAmount),
            -toInt256(divdrup(daiAmount, rate))
        );
        vat.flux("ETH-A", user, address(this), wethAmount);
        wethJoin.exit(address(this), wethAmount);
        controller.post(WETH, address(this), user, wethAmount);
        controller.borrow(WETH, yDai.maturity(), user, address(this), yDaiSold);
    }
    function _yieldToMaker(address user, uint256 yDaiAmount, uint256 wethAmount) internal {
        controller.repayYDai(WETH, yDai.maturity(), address(this), user, yDaiAmount);
        controller.withdraw(WETH, user, address(this), wethAmount);
        wethJoin.join(user, wethAmount);
        uint256 daiAmount = pool.buyYDaiPreview(toUint128(yDaiAmount));
        (, uint256 rate,,,) = vat.ilks("ETH-A");
        vat.frob(
            "ETH-A",
            user,
            user,
            user,
            toInt256(wethAmount),
            toInt256(divdrup(daiAmount, rate))
        );
        vat.move(user, address(this), daiAmount.mul(UNIT));
        daiJoin.exit(address(this), daiAmount);
        pool.buyYDai(address(this), address(this), toUint128(yDaiAmount));
    }
}