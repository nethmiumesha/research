pragma solidity ^0.8.13;
import {IHandler} from "../../interfaces/IHandler.sol";
import {VaultHopper} from "../../VaultHopper.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IMorpho, MarketParams} from "../../interfaces/IMorpho.sol";
abstract contract BaseHandler is IHandler {
    error Unauthorized();
    error OnlyHopper();
    error InvalidMorphoMarket();
    error UnsupportedAsset();
    using SafeERC20 for IERC20;
    VaultHopper public immutable hopper;
    uint256 internal constant BPS_DENOMINATOR = 10000;
    constructor(address _hopper) {
        hopper = VaultHopper(_hopper);
    }
    modifier onlyOwner() {
        if (msg.sender != hopper.owner()) revert Unauthorized();
        _;
    }
    modifier onlyHopper() {
        if (msg.sender != address(hopper)) revert OnlyHopper();
        _;
    }
    function _getMorphoMarketParams(bytes32 morphoMarketId) internal view returns (MarketParams memory mp) {
        mp = IMorpho(hopper.morphoBlue()).idToMarketParams(morphoMarketId);
        if (mp.loanToken == address(0)) revert InvalidMorphoMarket();
    }
    function _getOutputToken(address dest, bytes32 morphoMarketId) internal view returns (address outputToken) {
        if (morphoMarketId != bytes32(0)) {
            return _getMorphoMarketParams(morphoMarketId).loanToken;
        }
        outputToken = IERC4626(dest).asset();
        if (outputToken == address(0)) revert UnsupportedAsset();
    }
        function _depositToDest(address dest, address outputToken, uint256 amount, address receiver, bytes32 morphoMarketId)
        internal
    {
        if (morphoMarketId != bytes32(0)) {
            address morpho = hopper.morphoBlue();
            IERC20(outputToken).safeIncreaseAllowance(morpho, amount);
            MarketParams memory mp = _getMorphoMarketParams(morphoMarketId);
            IMorpho(morpho).supply(mp, amount, 0, receiver, "");
        } else {
            IERC20(outputToken).safeIncreaseAllowance(dest, amount);
            IERC4626(dest).deposit(amount, receiver);
        }
    }
}