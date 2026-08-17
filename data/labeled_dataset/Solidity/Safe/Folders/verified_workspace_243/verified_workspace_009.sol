pragma solidity 0.4.25;
pragma experimental ABIEncoderV2;
import "../libs/LibOrder.sol";
import "../libs/LibFillResults.sol";
contract IWrapperFunctions {
    function fillOrKillOrder(
        LibOrder.Order memory order,
        uint256 takerAssetFillAmount,
        bytes memory signature
    )
        public
        returns (LibFillResults.FillResults memory fillResults);
    function fillOrderNoThrow(
        LibOrder.Order memory order,
        uint256 takerAssetFillAmount,
        bytes memory signature
    )
        public
        returns (LibFillResults.FillResults memory fillResults);
    function batchFillOrders(
        LibOrder.Order[] memory orders,
        uint256[] memory takerAssetFillAmounts,
        bytes[] memory signatures
    )
        public
        returns (LibFillResults.FillResults memory totalFillResults);
    function batchFillOrKillOrders(
        LibOrder.Order[] memory orders,
        uint256[] memory takerAssetFillAmounts,
        bytes[] memory signatures
    )
        public
        returns (LibFillResults.FillResults memory totalFillResults);
    function batchFillOrdersNoThrow(
        LibOrder.Order[] memory orders,
        uint256[] memory takerAssetFillAmounts,
        bytes[] memory signatures
    )
        public
        returns (LibFillResults.FillResults memory totalFillResults);
    function marketSellOrders(
        LibOrder.Order[] memory orders,
        uint256 takerAssetFillAmount,
        bytes[] memory signatures
    )
        public
        returns (LibFillResults.FillResults memory totalFillResults);
    function marketSellOrdersNoThrow(
        LibOrder.Order[] memory orders,
        uint256 takerAssetFillAmount,
        bytes[] memory signatures
    )
        public
        returns (LibFillResults.FillResults memory totalFillResults);
    function marketBuyOrders(
        LibOrder.Order[] memory orders,
        uint256 makerAssetFillAmount,
        bytes[] memory signatures
    )
        public
        returns (LibFillResults.FillResults memory totalFillResults);
    function marketBuyOrdersNoThrow(
        LibOrder.Order[] memory orders,
        uint256 makerAssetFillAmount,
        bytes[] memory signatures
    )
        public
        returns (LibFillResults.FillResults memory totalFillResults);
    function batchCancelOrders(LibOrder.Order[] memory orders)
        public;
}