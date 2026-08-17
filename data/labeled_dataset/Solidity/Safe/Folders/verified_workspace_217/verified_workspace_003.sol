pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {BaseStrategyInitializable, StrategyParams, VaultAPI} from "../BaseStrategy.sol";
contract TestStrategy is BaseStrategyInitializable {
    bool public doReentrancy;
    address public constant protectedToken = address(0xbad);
    constructor(address _vault) public BaseStrategyInitializable(_vault) {}
    function name() external override view returns (string memory) {
        return string(abi.encodePacked("TestStrategy ", apiVersion()));
    }
    function _takeFunds(uint256 amount) public {
        want.safeTransfer(msg.sender, amount);
    }
    function _toggleReentrancyExploit() public {
        doReentrancy = !doReentrancy;
    }
    function _setWant(IERC20 _want) public {
        want = _want;
    }
    function estimatedTotalAssets() public override view returns (uint256) {
        return want.balanceOf(address(this));
    }
    function prepareReturn(uint256 _debtOutstanding)
        internal
        override
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _debtPayment
        )
    {
        uint256 totalAssets = want.balanceOf(address(this));
        uint256 totalDebt = vault.strategies(address(this)).totalDebt;
        if (totalAssets > _debtOutstanding) {
            _debtPayment = _debtOutstanding;
            totalAssets = totalAssets.sub(_debtOutstanding);
        } else {
            _debtPayment = totalAssets;
            totalAssets = 0;
        }
        totalDebt = totalDebt.sub(_debtPayment);
        if (totalAssets > totalDebt) {
            _profit = totalAssets.sub(totalDebt);
        } else {
            _loss = totalDebt.sub(totalAssets);
        }
    }
    function adjustPosition(uint256 _debtOutstanding) internal override {
    }
    function liquidatePosition(uint256 _amountNeeded) internal override returns (uint256 _liquidatedAmount, uint256 _loss) {
        if (doReentrancy) {
            uint256 stratBalance = VaultAPI(address(vault)).balanceOf(address(this));
            VaultAPI(address(vault)).withdraw(stratBalance, address(this));
        }
        uint256 totalDebt = vault.strategies(address(this)).totalDebt;
        uint256 totalAssets = want.balanceOf(address(this));
        if (_amountNeeded > totalAssets) {
            _liquidatedAmount = totalAssets;
            _loss = _amountNeeded.sub(totalAssets);
        } else {
            if (totalDebt > totalAssets) {
                _loss = totalDebt.sub(totalAssets);
                if (_loss > _amountNeeded) _loss = _amountNeeded;
            }
            _liquidatedAmount = _amountNeeded;
        }
    }
    function prepareMigration(address _newStrategy) internal override {
    }
    function protectedTokens() internal override view returns (address[] memory) {
        address[] memory protected = new address[](1);
        protected[0] = protectedToken;
        return protected;
    }
}