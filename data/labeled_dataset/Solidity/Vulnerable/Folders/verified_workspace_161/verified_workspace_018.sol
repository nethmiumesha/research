pragma solidity ^0.8.13;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {BaseHandler} from "./base/BaseHandler.sol";
import {ISwapHandler} from "../interfaces/ISwapHandler.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IMorpho, MarketParams} from "../interfaces/IMorpho.sol";
contract SwapHandler is BaseHandler, ISwapHandler {
    error SwapFailed();
    error InvalidAddress();
    error SwapTargetNotWhitelisted(address swapTarget);
    error NativeTransferFailed();
    error UnsupportedProtocol(SwapProtocol protocol);
    error OutputAmountZero();
    using SafeERC20 for IERC20;
    address public constant ZERO_EX_ALLOWANCE_HOLDER = 0x0000000000001fF3684f28c67538d4D072C22734;
    address public constant OPEN_OCEAN_ROUTER = 0x6352a56caadC4F1E25CD6c75970Fa768A3304e64;
    address public constant KYBER_AGGREGATOR = 0x6131B5fae19EA4f9D964eAc0408E4408b66337b5;
    address internal constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    mapping(address => bool) public whitelistedSwapTargets;
    enum SwapProtocol {
        OTHER,
        ZERO_EX
    }
    event SwapTargetSet(address indexed target, bool status);
    event SwapExecuted(
        SwapProtocol indexed protocol,
        address indexed inputToken,
        address indexed outputToken,
        uint256 inputAmount,
        uint256 outputAmount
    );
    event ExecuteOnSourceChain(
        address indexed toVault, address indexed receiver, address indexed asset, uint256 amount
    );
    constructor(address _hopper) BaseHandler(_hopper) {
        whitelistedSwapTargets[ZERO_EX_ALLOWANCE_HOLDER] = true;
        whitelistedSwapTargets[OPEN_OCEAN_ROUTER] = true;
        whitelistedSwapTargets[KYBER_AGGREGATOR] = true;
    }
    function setWhitelistedSwapTargets(address target, bool status) external onlyOwner {
        if (target == address(0)) revert InvalidAddress();
        whitelistedSwapTargets[target] = status;
        emit SwapTargetSet(target, status);
    }
    function swap(address inputToken, uint256 amount, address outputToken, address receiver, bytes calldata swapData)
        external
        payable
        returns (uint256 outputAmount)
    {
        outputAmount = _swap(inputToken, amount, outputToken, receiver, swapData);
    }
    function executeOnSourceChain(
        address asset,
        address,
        uint256 amount,
        bytes calldata data
    )
        external
        payable
        onlyHopper
    {
        (address dest, address receiver, bytes memory swapData, bytes32 morphoMarketId) =
            abi.decode(data, (address, address, bytes, bytes32));
        if (receiver == address(0) || dest == address(0)) revert InvalidAddress();
        address outputToken = _getOutputToken(dest, morphoMarketId);
        uint256 outputAmount = _swap(asset, amount, outputToken, address(this), swapData);
        _depositToDest(dest, outputToken, outputAmount, receiver, morphoMarketId);
        emit ExecuteOnSourceChain(dest, receiver, outputToken, outputAmount);
    }
    function _swap(address inputToken, uint256 amount, address outputToken, address receiver, bytes memory swapData)
        internal
        returns (uint256 outputAmount)
    {
        IERC20(inputToken).safeTransferFrom(msg.sender, address(this), amount);
        (address swapTarget, bytes memory swapCalldata, SwapProtocol protocol) =
            abi.decode(swapData, (address, bytes, SwapProtocol));
        if (!whitelistedSwapTargets[swapTarget]) revert SwapTargetNotWhitelisted(swapTarget);
        if (protocol == SwapProtocol.ZERO_EX) {
            outputAmount = _swapVia0x(inputToken, amount, outputToken, swapTarget, swapCalldata);
        } else {
            outputAmount = _swapViaAggregator(inputToken, amount, outputToken, swapTarget, swapCalldata);
        }
        if (outputAmount == 0) revert OutputAmountZero();
        _payout(outputToken, receiver, outputAmount);
        emit SwapExecuted(protocol, inputToken, outputToken, amount, outputAmount);
        return outputAmount;
    }
    function _swapVia0x(
        address inputToken,
        uint256 amount,
        address outputToken,
        address swapTarget,
        bytes memory swapCalldata
    ) internal returns (uint256 outputAmount) {
        IERC20(inputToken).safeIncreaseAllowance(ZERO_EX_ALLOWANCE_HOLDER, amount);
        uint256 balanceBefore =
            outputToken == NATIVE_TOKEN ? address(this).balance : IERC20(outputToken).balanceOf(address(this));
        (bool success,) = swapTarget.call{value: msg.value}(swapCalldata);
        if (!success) revert SwapFailed();
        outputAmount = outputToken == NATIVE_TOKEN
            ? address(this).balance - balanceBefore
            : IERC20(outputToken).balanceOf(address(this)) - balanceBefore;
        return outputAmount;
    }
    function _swapViaAggregator(
        address inputToken,
        uint256 amount,
        address outputToken,
        address swapTarget,
        bytes memory swapCalldata
    ) internal returns (uint256 outputAmount) {
        IERC20(inputToken).safeIncreaseAllowance(swapTarget, amount);
        uint256 balanceBefore =
            outputToken == NATIVE_TOKEN ? address(this).balance : IERC20(outputToken).balanceOf(address(this));
        (bool success,) = swapTarget.call{value: msg.value}(swapCalldata);
        if (!success) revert SwapFailed();
        outputAmount = outputToken == NATIVE_TOKEN
            ? address(this).balance - balanceBefore
            : IERC20(outputToken).balanceOf(address(this)) - balanceBefore;
        return outputAmount;
    }
    function _payout(address token, address recipient, uint256 amount) internal {
        if (recipient == address(this)) return;
        if (token == NATIVE_TOKEN) {
            (bool sent,) = payable(recipient).call{value: amount}("");
            if (!sent) revert NativeTransferFailed();
        } else {
            IERC20(token).safeTransfer(recipient, amount);
        }
    }
    function validateHandlerData(bytes calldata handlerData, bool, uint256, uint256)
        external
        view
        returns (address toVault, address receiver, uint256 destinationChainId)
    {
        (toVault, receiver,) = abi.decode(handlerData, (address, address, bytes));
        destinationChainId = block.chainid;
    }
    receive() external payable {}
}