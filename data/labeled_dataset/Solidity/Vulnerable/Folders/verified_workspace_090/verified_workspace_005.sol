pragma solidity >=0.8.0 <=0.8.10;
pragma abicoder v2;
import "./utils/TestUtil.sol";
import "./interfaces/IHintHelpers.sol";
import "../../bridges/liquity/TroveBridge.sol";
contract TroveBridgeTest is TestUtil {
    TroveBridge private bridge;
    IHintHelpers private constant hintHelpers = IHintHelpers(0xE84251b93D9524E0d2e621Ba7dc7cb3579F997C0);
    ISortedTroves private constant sortedTroves = ISortedTroves(0x8FdD3fbFEb32b28fb73555518f8b361bCeA741A6);
    address private constant OWNER = address(24);
    uint256 private constant OWNER_WEI_BALANCE = 5e18;
    uint256 private constant ROLLUP_PROCESSOR_WEI_BALANCE = 1e18;
    uint256 private constant NICR_PRECISION = 1e20;
    enum Status {
        nonExistent,
        active,
        closedByOwner,
        closedByLiquidation,
        closedByRedemption
    }
    function setUp() public {
        _aztecPreSetup();
        setUpTokens();
        uint256 initialCollateralRatio = 160;
        uint256 maxFee = 5e16;
        vm.prank(OWNER);
        bridge = new TroveBridge(address(rollupProcessor), initialCollateralRatio, maxFee);
        vm.deal(OWNER, OWNER_WEI_BALANCE);
        vm.deal(address(rollupProcessor), ROLLUP_PROCESSOR_WEI_BALANCE);
    }
    function testInitialERC20Params() public {
        assertEq(bridge.name(), "TroveBridge");
        assertEq(bridge.symbol(), "TB-160");
        assertEq(uint256(bridge.decimals()), 18);
    }
    function testIncorrectTroveState() public {
        vm.prank(address(rollupProcessor));
        try
            bridge.convert(
                AztecTypes.AztecAsset(3, address(0), AztecTypes.AztecAssetType.ETH),
                AztecTypes.AztecAsset(0, address(0), AztecTypes.AztecAssetType.NOT_USED),
                AztecTypes.AztecAsset(2, address(bridge), AztecTypes.AztecAssetType.ERC20),
                AztecTypes.AztecAsset(1, tokens["LUSD"].addr, AztecTypes.AztecAssetType.ERC20),
                ROLLUP_PROCESSOR_WEI_BALANCE,
                0,
                0,
                address(0)
            )
        {
            assertTrue(false, "convert(...) has to revert when trove is in an incorrect state.");
        } catch Error(string memory reason) {
            assertEq(reason, "TroveBridge: INACTIVE_TROVE");
        }
    }
    function testIncorrectInput() public {
        vm.prank(address(rollupProcessor));
        try
            bridge.convert(
                AztecTypes.AztecAsset(0, address(0), AztecTypes.AztecAssetType.NOT_USED),
                AztecTypes.AztecAsset(0, address(0), AztecTypes.AztecAssetType.NOT_USED),
                AztecTypes.AztecAsset(0, address(0), AztecTypes.AztecAssetType.NOT_USED),
                AztecTypes.AztecAsset(0, address(0), AztecTypes.AztecAssetType.NOT_USED),
                0,
                0,
                0,
                address(0)
            )
        {
            assertTrue(false, "convert(...) has to revert on incorrect input.");
        } catch Error(string memory reason) {
            assertEq(reason, "TroveBridge: INCORRECT_INPUT");
        }
    }
    function testFullFlow() public {
        _openTrove();
        _borrow();
        _repay();
        _closeTrove();
    }
    function testLiquidationFlow() public {
        _openTrove();
        _borrow();
        dropLiquityPriceByHalf();
        bridge.troveManager().liquidate(address(bridge));
        Status troveStatus = Status(bridge.troveManager().getTroveStatus(address(bridge)));
        assertTrue(troveStatus == Status.closedByLiquidation);
        vm.startPrank(OWNER);
        try bridge.closeTrove() {
            assertTrue(false, "closeTrove() has to revert in case owner's balance != TB total supply.");
        } catch Error(string memory reason) {
            assertEq(reason, "TroveBridge: OWNER_MUST_BE_LAST");
        }
        try bridge.openTrove(address(0), address(0)) {
            assertTrue(false, "openTrove() has to revert in case TB total supply != 0.");
        } catch Error(string memory reason) {
            assertEq(reason, "TroveBridge: INCORRECT_TOTAL_SUPPLY");
        }
        vm.stopPrank();
    }
    function testRedeemFlow() public {
        _openTrove();
        _borrow();
        uint256 amountToRedeem = 2e25;
        do {
            mint("LUSD", address(this), amountToRedeem);
            bridge.troveManager().redeemCollateral(amountToRedeem, address(0), address(0), address(0), 0, 0, 1e18);
        } while (Status(bridge.troveManager().getTroveStatus(address(bridge))) != Status.closedByRedemption);
        _redeem();
    }
    function _openTrove() private {
        vm.startPrank(OWNER);
        uint256 amtToBorrow = bridge.computeAmtToBorrow(OWNER_WEI_BALANCE);
        uint256 nicr = (OWNER_WEI_BALANCE * NICR_PRECISION) / amtToBorrow;
        uint256 numTrials = 15;
        uint256 randomSeed = 42;
        (address approxHint, , ) = hintHelpers.getApproxHint(nicr, numTrials, randomSeed);
        (address upperHint, address lowerHint) = sortedTroves.findInsertPosition(nicr, approxHint, approxHint);
        bridge.openTrove{value: OWNER_WEI_BALANCE}(upperHint, lowerHint);
        uint256 price = bridge.troveManager().priceFeed().fetchPrice();
        uint256 icr = bridge.troveManager().getCurrentICR(address(bridge), price);
        assertEq(icr, 160e16);
        (uint256 debtAfterBorrowing, uint256 collAfterBorrowing, , ) = bridge.troveManager().getEntireDebtAndColl(
            address(bridge)
        );
        assertEq(bridge.totalSupply(), debtAfterBorrowing);
        assertEq(collAfterBorrowing, OWNER_WEI_BALANCE);
        uint256 lusdBalance = tokens["LUSD"].erc.balanceOf(OWNER);
        assertEq(lusdBalance, amtToBorrow);
        assertEq(address(bridge).balance, 0);
        assertEq(tokens["LUSD"].erc.balanceOf(address(bridge)), 0);
        vm.stopPrank();
    }
    function _borrow() private {
        uint256 price = bridge.troveManager().priceFeed().fetchPrice();
        uint256 icrBeforeBorrowing = bridge.troveManager().getCurrentICR(address(bridge), price);
        (, uint256 collBeforeBorrowing, , ) = bridge.troveManager().getEntireDebtAndColl(address(bridge));
        rollupProcessor.convert(
            address(bridge),
            AztecTypes.AztecAsset(3, address(0), AztecTypes.AztecAssetType.ETH),
            AztecTypes.AztecAsset(0, address(0), AztecTypes.AztecAssetType.NOT_USED),
            AztecTypes.AztecAsset(2, address(bridge), AztecTypes.AztecAssetType.ERC20),
            AztecTypes.AztecAsset(1, tokens["LUSD"].addr, AztecTypes.AztecAssetType.ERC20),
            ROLLUP_PROCESSOR_WEI_BALANCE,
            0,
            0
        );
        (uint256 debtAfterBorrowing, uint256 collAfterBorrowing, , ) = bridge.troveManager().getEntireDebtAndColl(
            address(bridge)
        );
        assertEq(collAfterBorrowing - collBeforeBorrowing, ROLLUP_PROCESSOR_WEI_BALANCE);
        uint256 icrAfterBorrowing = bridge.troveManager().getCurrentICR(address(bridge), price);
        assertEq(icrBeforeBorrowing, icrAfterBorrowing);
        assertEq(bridge.totalSupply(), debtAfterBorrowing);
        assertEq(address(bridge).balance, 0);
        assertEq(tokens["LUSD"].erc.balanceOf(address(bridge)), 0);
        assertGt(bridge.balanceOf(address(rollupProcessor)), 0);
        assertGt(tokens["LUSD"].erc.balanceOf(address(rollupProcessor)), 0);
    }
    function _repay() private {
        uint256 processorTBBalance = bridge.balanceOf(address(rollupProcessor));
        uint256 processorLUSDBalance = tokens["LUSD"].erc.balanceOf(address(rollupProcessor));
        uint256 borrowerFee = processorTBBalance - processorLUSDBalance;
        mint("LUSD", address(rollupProcessor), borrowerFee);
        rollupProcessor.convert(
            address(bridge),
            AztecTypes.AztecAsset(2, address(bridge), AztecTypes.AztecAssetType.ERC20),
            AztecTypes.AztecAsset(1, tokens["LUSD"].addr, AztecTypes.AztecAssetType.ERC20),
            AztecTypes.AztecAsset(3, address(0), AztecTypes.AztecAssetType.ETH),
            AztecTypes.AztecAsset(0, address(0), AztecTypes.AztecAssetType.NOT_USED),
            processorTBBalance,
            1,
            0
        );
        assertEq(address(bridge).balance, 0);
        assertEq(tokens["LUSD"].erc.balanceOf(address(bridge)), 0);
        uint256 diffInETH = address(rollupProcessor).balance < ROLLUP_PROCESSOR_WEI_BALANCE
            ? ROLLUP_PROCESSOR_WEI_BALANCE - address(rollupProcessor).balance
            : address(rollupProcessor).balance - ROLLUP_PROCESSOR_WEI_BALANCE;
        assertLe(diffInETH, 1);
    }
    function _closeTrove() private {
        vm.startPrank(OWNER);
        uint256 ownerTBBalance = bridge.balanceOf(OWNER);
        uint256 ownerLUSDBalance = tokens["LUSD"].erc.balanceOf(OWNER);
        uint256 borrowerFee = ownerTBBalance - ownerLUSDBalance - 200e18;
        uint256 amountToRepay = ownerLUSDBalance + borrowerFee;
        mint("LUSD", OWNER, borrowerFee);
        tokens["LUSD"].erc.approve(address(bridge), amountToRepay);
        bridge.closeTrove();
        Status troveStatus = Status(bridge.troveManager().getTroveStatus(address(bridge)));
        assertTrue(troveStatus == Status.closedByOwner);
        assertEq(address(bridge).balance, 0);
        assertEq(tokens["LUSD"].erc.balanceOf(address(bridge)), 0);
        uint256 diffInETH = OWNER.balance < OWNER_WEI_BALANCE
            ? OWNER_WEI_BALANCE - OWNER.balance
            : OWNER.balance - OWNER_WEI_BALANCE;
        assertLe(diffInETH, 1);
        assertEq(bridge.totalSupply(), 0);
        vm.stopPrank();
    }
    function _redeem() private {
        uint256 processorTBBalance = bridge.balanceOf(address(rollupProcessor));
        rollupProcessor.convert(
            address(bridge),
            AztecTypes.AztecAsset(2, address(bridge), AztecTypes.AztecAssetType.ERC20),
            AztecTypes.AztecAsset(0, address(0), AztecTypes.AztecAssetType.NOT_USED),
            AztecTypes.AztecAsset(3, address(0), AztecTypes.AztecAssetType.ETH),
            AztecTypes.AztecAsset(0, address(0), AztecTypes.AztecAssetType.NOT_USED),
            processorTBBalance,
            0,
            0
        );
        assertGt(address(rollupProcessor).balance, 0);
    }
    function _closeRedeem() private {
        vm.startPrank(OWNER);
        bridge.closeTrove();
        assertEq(address(bridge).balance, 0);
        assertGt(OWNER.balance, 0);
        assertEq(bridge.totalSupply(), 0);
        vm.stopPrank();
    }
    receive() external payable {}
    fallback() external payable {}
}