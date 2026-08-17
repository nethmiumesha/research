pragma solidity 0.8.10;
import "../../../lib/ds-test/src/test.sol";
import {Vm} from "../../../lib/forge-std/src/Vm.sol";
import { DefiBridgeProxy } from "./../../aztec/DefiBridgeProxy.sol";
import { RollupProcessor } from "./../../aztec/RollupProcessor.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IssuanceBridge } from "./../../bridges/set/IssuanceBridge.sol";
import { IController } from "./../../bridges/set/interfaces/IController.sol";
import { ISetToken } from "./../../bridges/set/interfaces/ISetToken.sol";
import { AztecTypes } from "./../../aztec/AztecTypes.sol";
contract SetTest is DSTest {
    Vm vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    DefiBridgeProxy defiBridgeProxy;
    RollupProcessor rollupProcessor;
    IssuanceBridge issuanceBridge;
    address exchangeIssuanceAddress = 0xc8C85A3b4d03FB3451e7248Ff94F780c92F884fD;
    address setControllerAddress = 0xa4c8d221d8BB851f83aadd0223a8900A6921A349;
    IERC20 constant dai = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IERC20 constant dpi = IERC20(0x1494CA1F11D487c2bBe4543E90080AeBa4BA3C2b);
    function _aztecPreSetup() internal {
        defiBridgeProxy = new DefiBridgeProxy();
        rollupProcessor = new RollupProcessor(address(defiBridgeProxy));
    }
    function setUp() public {
        _aztecPreSetup();
        issuanceBridge = new IssuanceBridge(
            address(rollupProcessor),
            exchangeIssuanceAddress,
            setControllerAddress
        );
    }
    function testSetBridge() public {
        uint256 depositAmountDai = 1000000000;
        uint256 depositAmountDpi = 2000000000;
        uint256 depositAmountEth = 1000000000000000000;
        _setTokenBalance(address(dai), address(rollupProcessor), depositAmountDai, 2);
        _setTokenBalance(address(dpi), address(rollupProcessor), depositAmountDpi, 0);
        _setEthBalance(address(rollupProcessor), depositAmountEth);
        uint256 rollupBalanceDai = dai.balanceOf(address(rollupProcessor));
        uint256 rollupBalanceDpi = dpi.balanceOf(address(rollupProcessor));
        uint256 rollupBalanceEth = address(rollupProcessor).balance;
        assertEq(
            depositAmountDai,
            rollupBalanceDai,
            "DAI balance must match"
        );
        assertEq(
            depositAmountDpi,
            rollupBalanceDpi,
            "DPI balance must match"
        );
        assertEq(
            depositAmountEth,
            rollupBalanceEth,
            "ETH balance must match"
        );
    }
    function testIssueSetForExactToken() public {
        uint256 depositAmountDai = 1000000000000000000000;
        _setTokenBalance(address(dai), address(rollupProcessor), depositAmountDai, 2);
        AztecTypes.AztecAsset memory empty;
        AztecTypes.AztecAsset memory inputAsset = AztecTypes.AztecAsset({
            id: 1,
            erc20Address: address(dai),
            assetType: AztecTypes.AztecAssetType.ERC20
        });
        AztecTypes.AztecAsset memory outputAsset = AztecTypes.AztecAsset({
            id: 1,
            erc20Address: address(dpi),
            assetType: AztecTypes.AztecAssetType.ERC20
        });
        uint256 rollupBalanceBeforeDai = dai.balanceOf(address(rollupProcessor));
        uint256 rollupBalanceBeforeDpi = dpi.balanceOf(address(rollupProcessor));
        (
            uint256 outputValueA,
            uint256 outputValueB,
            bool isAsync
        ) = rollupProcessor.convert(
                address(issuanceBridge),
                inputAsset,
                empty,
                outputAsset,
                empty,
                depositAmountDai,
                0,
                0
            );
        uint256 rollupBalanceAfterDai = dai.balanceOf(address(rollupProcessor));
        uint256 rollupBalanceAfterDpi = dpi.balanceOf(address(rollupProcessor));
        assertEq(
            depositAmountDai,
            rollupBalanceBeforeDai,
            "DAI balance before convert must match"
        );
        assertEq(
            0,
            rollupBalanceBeforeDpi,
            "DPI balance before convert must match"
        );
        assertEq(
            0,
            rollupBalanceAfterDai,
            "DAI balance after convert must match"
        );
        assertEq(
            outputValueA,
            rollupBalanceAfterDpi,
            "DPI balance after convert must match"
        );
        assertGt(
            rollupBalanceAfterDpi,
            0,
            "DPI balance after must be > 0"
        );
    }
    function testIssueSetForExactEth() public {
        uint256 depositAmountEth = 100000000000000000;
        _setEthBalance(address(rollupProcessor), depositAmountEth);
        AztecTypes.AztecAsset memory empty;
        AztecTypes.AztecAsset memory inputAsset = AztecTypes.AztecAsset({
            id: 1,
            erc20Address: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE,
            assetType: AztecTypes.AztecAssetType.ETH
        });
        AztecTypes.AztecAsset memory outputAsset = AztecTypes.AztecAsset({
            id: 1,
            erc20Address: address(dpi),
            assetType: AztecTypes.AztecAssetType.ERC20
        });
        uint256 rollupBalanceBeforeEth = address(rollupProcessor).balance;
        uint256 rollupBalanceBeforeDpi = dpi.balanceOf(address(rollupProcessor));
        (
            uint256 outputValueA,
            uint256 outputValueB,
            bool isAsync
        ) = rollupProcessor.convert(
                address(issuanceBridge),
                inputAsset,
                empty,
                outputAsset,
                empty,
                depositAmountEth,
                0,
                0
            );
        uint256 rollupBalanceAfterEth = address(rollupProcessor).balance;
        uint256 rollupBalanceAfterDpi = dpi.balanceOf(address(rollupProcessor));
        assertEq(
            depositAmountEth,
            rollupBalanceBeforeEth,
            "ETH balance before convert must match"
        );
        assertEq(
            0,
            rollupBalanceBeforeDpi,
            "DPI balance before convert must match"
        );
        assertEq(
            0,
            rollupBalanceAfterEth,
            "ETH balance after convert must match"
        );
        assertEq(
            outputValueA,
            rollupBalanceAfterDpi,
            "DPI balance after convert must match"
        );
        assertGt(
            rollupBalanceAfterDpi,
            0,
            "DPI balance after must be > 0"
        );
    }
    function testRedeemExactSetForToken() public {
        uint256 depositAmountDpi = 100000000000000000000;
        _setTokenBalance(address(dpi), address(rollupProcessor), depositAmountDpi, 0);
        AztecTypes.AztecAsset memory empty;
        AztecTypes.AztecAsset memory inputAsset = AztecTypes.AztecAsset({
            id: 1,
            erc20Address: address(dpi),
            assetType: AztecTypes.AztecAssetType.ERC20
        });
        AztecTypes.AztecAsset memory outputAsset = AztecTypes.AztecAsset({
            id: 1,
            erc20Address: address(dai),
            assetType: AztecTypes.AztecAssetType.ERC20
        });
        uint256 rollupBalanceBeforeDai = dai.balanceOf(address(rollupProcessor));
        uint256 rollupBalanceBeforeDpi = dpi.balanceOf(address(rollupProcessor));
        (
            uint256 outputValueA,
            uint256 outputValueB,
            bool isAsync
        ) = rollupProcessor.convert(
                address(issuanceBridge),
                inputAsset,
                empty,
                outputAsset,
                empty,
                depositAmountDpi,
                0,
                0
            );
        uint256 rollupBalanceAfterDai = dai.balanceOf(address(rollupProcessor));
        uint256 rollupBalanceAfterDpi = dpi.balanceOf(address(rollupProcessor));
        assertEq(
            0,
            rollupBalanceBeforeDai,
            "DAI balance before convert must match"
        );
        assertEq(
            depositAmountDpi,
            rollupBalanceBeforeDpi,
            "DPI balance before convert must match"
        );
        assertEq(
            outputValueA,
            rollupBalanceAfterDai,
            "DAI balance after convert must match"
        );
        assertEq(
            0,
            rollupBalanceAfterDpi,
            "DPI balance after convert must match"
        );
        assertGt(
            rollupBalanceAfterDai,
            0,
            "DAI balance after must be > 0"
        );
    }
    function testRedeemExactSetForEth() public {
        uint256 depositAmountDpi = 100000000000000000000;
        _setTokenBalance(address(dpi), address(rollupProcessor), depositAmountDpi, 0);
        AztecTypes.AztecAsset memory empty;
        AztecTypes.AztecAsset memory inputAsset = AztecTypes.AztecAsset({
            id: 1,
            erc20Address: address(dpi),
            assetType: AztecTypes.AztecAssetType.ERC20
        });
        AztecTypes.AztecAsset memory outputAsset = AztecTypes.AztecAsset({
            id: 1,
            erc20Address: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE,
            assetType: AztecTypes.AztecAssetType.ETH
        });
        uint256 rollupBalanceBeforeDpi = dpi.balanceOf(address(rollupProcessor));
        uint256 rollupBalanceBeforeEth = address(rollupProcessor).balance;
        (
            uint256 outputValueA,
            uint256 outputValueB,
            bool isAsync
        ) = rollupProcessor.convert(
                address(issuanceBridge),
                inputAsset,
                empty,
                outputAsset,
                empty,
                depositAmountDpi,
                0,
                0
            );
        uint256 rollupBalanceAfterDpi = dpi.balanceOf(address(rollupProcessor));
        uint256 rollupBalanceAfterEth = address(rollupProcessor).balance;
        assertEq(
            0,
            rollupBalanceBeforeEth,
            "ETH balance before convert must match"
        );
        assertEq(
            depositAmountDpi,
            rollupBalanceBeforeDpi,
            "DPI balance before convert must match"
        );
        assertEq(
            outputValueA,
            rollupBalanceAfterEth,
            "ETH balance after convert must match"
        );
        assertEq(
            0,
            rollupBalanceAfterDpi,
            "DPI balance after convert must match"
        );
        assertGt(
            rollupBalanceAfterEth,
            0,
            "ETH balance after must be > 0"
        );
    }
    function _setTokenBalance(
        address token,
        address user,
        uint256 balance,
        uint256 slot
    ) internal {
        vm.store(
            token,
            keccak256(abi.encode(user, slot)),
            bytes32(uint256(balance))
        );
        assertEq(IERC20(token).balanceOf(user), balance, "wrong token balance");
    }
    function _setEthBalance(
        address user,
        uint256 balance
    ) internal {
        vm.deal(user, balance);
        assertEq(user.balance, balance, "wrong ETH balance");
    }
}