pragma solidity 0.5.11;
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import {
    Initializable
} from "@openzeppelin/upgrades/contracts/Initializable.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { IStrategy } from "../interfaces/IStrategy.sol";
import { Governable } from "../governance/Governable.sol";
import { OUSD } from "../token/OUSD.sol";
import "../utils/Helpers.sol";
import { StableMath } from "../utils/StableMath.sol";
contract VaultStorage is Initializable, Governable {
    using SafeMath for uint256;
    using StableMath for uint256;
    using SafeMath for int256;
    using SafeERC20 for IERC20;
    event AssetSupported(address _asset);
    event AssetDefaultStrategyUpdated(address _asset, address _strategy);
    event StrategyApproved(address _addr);
    event StrategyRemoved(address _addr);
    event Mint(address _addr, uint256 _value);
    event Redeem(address _addr, uint256 _value);
    event CapitalPaused();
    event CapitalUnpaused();
    event RebasePaused();
    event RebaseUnpaused();
    event VaultBufferUpdated(uint256 _vaultBuffer);
    event RedeemFeeUpdated(uint256 _redeemFeeBps);
    event PriceProviderUpdated(address _priceProvider);
    event AllocateThresholdUpdated(uint256 _threshold);
    event RebaseThresholdUpdated(uint256 _threshold);
    event UniswapUpdated(address _address);
    event StrategistUpdated(address _address);
    event MaxSupplyDiffChanged(uint256 maxSupplyDiff);
    event YieldDistribution(address _to, uint256 _yield, uint256 _fee);
    event TrusteeFeeBpsChanged(uint256 _basis);
    event TrusteeAddressChanged(address _address);
    struct Asset {
        bool isSupported;
    }
    mapping(address => Asset) assets;
    address[] allAssets;
    struct Strategy {
        bool isSupported;
        uint256 _deprecated;
    }
    mapping(address => Strategy) strategies;
    address[] allStrategies;
    address public priceProvider;
    bool public rebasePaused = false;
    bool public capitalPaused = true;
    uint256 public redeemFeeBps;
    uint256 public vaultBuffer;
    uint256 public autoAllocateThreshold;
    uint256 public rebaseThreshold;
    OUSD oUSD;
    bytes32 constant adminImplPosition = 0xa2bd3d3cf188a41358c8b401076eb59066b09dec5775650c0de4c55187d17bd9;
    address private _deprecated_rebaseHooksAddr = address(0);
    address public uniswapAddr = address(0);
    address public strategistAddr = address(0);
    mapping(address => address) public assetDefaultStrategies;
    uint256 public maxSupplyDiff;
    address public trusteeAddress;
    uint256 public trusteeFeeBps;
    function setAdminImpl(address newImpl) external onlyGovernor {
        require(
            Address.isContract(newImpl),
            "new implementation is not a contract"
        );
        bytes32 position = adminImplPosition;
        assembly {
            sstore(position, newImpl)
        }
    }
}