pragma solidity >=0.8.0 <=0.8.10;
pragma abicoder v2;
import "./utils/TestUtil.sol";
import "../../bridges/liquity/StakingBridge.sol";
contract StakingBridgeTest is TestUtil {
    StakingBridge private bridge;
    function setUp() public {
        _aztecPreSetup();
        setUpTokens();
        bridge = new StakingBridge(address(rollupProcessor));
        bridge.setApprovals();
    }
    function testInitialERC20Params() public {
        assertEq(bridge.name(), "StakingBridge");
        assertEq(bridge.symbol(), "SB");
        assertEq(uint256(bridge.decimals()), 18);
    }
    function testFullDepositWithdrawalFlow() public {
        uint256 depositAmount = 1e24;
        mint("LQTY", address(rollupProcessor), depositAmount);
        rollupProcessor.convert(
            address(bridge),
            AztecTypes.AztecAsset(1, tokens["LQTY"].addr, AztecTypes.AztecAssetType.ERC20),
            AztecTypes.AztecAsset(0, address(0), AztecTypes.AztecAssetType.NOT_USED),
            AztecTypes.AztecAsset(2, address(bridge), AztecTypes.AztecAssetType.ERC20),
            AztecTypes.AztecAsset(0, address(0), AztecTypes.AztecAssetType.NOT_USED),
            depositAmount,
            0,
            0
        );
        assertEq(bridge.totalSupply(), depositAmount);
        assertEq(bridge.balanceOf(address(rollupProcessor)), depositAmount);
        assertEq(bridge.STAKING_CONTRACT().stakes(address(bridge)), depositAmount);
        uint256 withdrawAmount = depositAmount;
        rollupProcessor.convert(
            address(bridge),
            AztecTypes.AztecAsset(2, address(bridge), AztecTypes.AztecAssetType.ERC20),
            AztecTypes.AztecAsset(0, address(0), AztecTypes.AztecAssetType.NOT_USED),
            AztecTypes.AztecAsset(1, tokens["LQTY"].addr, AztecTypes.AztecAssetType.ERC20),
            AztecTypes.AztecAsset(0, address(0), AztecTypes.AztecAssetType.NOT_USED),
            depositAmount,
            1,
            0
        );
        assertEq(bridge.totalSupply(), 0);
        assertEq(tokens["LQTY"].erc.balanceOf(address(rollupProcessor)), depositAmount);
    }
    function testMultipleDepositsWithdrawals() public {
        uint256 i = 0;
        uint256 numIters = 2;
        uint256 depositAmount = 203;
        uint256[] memory sbBalances = new uint256[](numIters);
        while (i < numIters) {
            depositAmount = rand(depositAmount);
            mint("LQTY", address(rollupProcessor), depositAmount);
            mint("LUSD", address(bridge), 1e20);
            mint("WETH", address(bridge), 1e18);
            (uint256 outputValueA, , ) = rollupProcessor.convert(
                address(bridge),
                AztecTypes.AztecAsset(1, tokens["LQTY"].addr, AztecTypes.AztecAssetType.ERC20),
                AztecTypes.AztecAsset(0, address(0), AztecTypes.AztecAssetType.NOT_USED),
                AztecTypes.AztecAsset(2, address(bridge), AztecTypes.AztecAssetType.ERC20),
                AztecTypes.AztecAsset(0, address(0), AztecTypes.AztecAssetType.NOT_USED),
                depositAmount,
                i,
                0
            );
            sbBalances[i] = outputValueA;
            i++;
        }
        i = 0;
        while (i < numIters) {
            rollupProcessor.convert(
                address(bridge),
                AztecTypes.AztecAsset(2, address(bridge), AztecTypes.AztecAssetType.ERC20),
                AztecTypes.AztecAsset(0, address(0), AztecTypes.AztecAssetType.NOT_USED),
                AztecTypes.AztecAsset(1, tokens["LQTY"].addr, AztecTypes.AztecAssetType.ERC20),
                AztecTypes.AztecAsset(0, address(0), AztecTypes.AztecAssetType.NOT_USED),
                sbBalances[i],
                numIters + i,
                0
            );
            i++;
        }
        assertEq(bridge.totalSupply(), 0);
    }
}