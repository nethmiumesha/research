pragma solidity ^0.5.16;
import "openzeppelin-solidity-2.3.0/contracts/token/ERC20/ERC20.sol";
import "./SafeDecimalMath.sol";
import "./interfaces/ISynth.sol";
import "./interfaces/IAddressResolver.sol";
import "./interfaces/IVirtualSynth.sol";
import "./interfaces/IExchanger.sol";
contract VirtualSynth is ERC20, IVirtualSynth {
    using SafeMath for uint;
    using SafeDecimalMath for uint;
    IERC20 public synth;
    IAddressResolver public resolver;
    bool public settled = false;
    uint8 public constant decimals = 18;
    uint public initialSupply;
    uint public settledAmount;
    bytes32 public currencyKey;
    bool public initialized = false;
    function initialize(
        IERC20 _synth,
        IAddressResolver _resolver,
        address _recipient,
        uint _amount,
        bytes32 _currencyKey
    ) external {
        require(!initialized, "vSynth already initialized");
        initialized = true;
        synth = _synth;
        resolver = _resolver;
        currencyKey = _currencyKey;
        _mint(_recipient, _amount);
        initialSupply = _amount;
    }
    function exchanger() internal view returns (IExchanger) {
        return IExchanger(resolver.requireAndGetAddress("Exchanger", "Exchanger contract not found"));
    }
    function secsLeft() internal view returns (uint) {
        return exchanger().maxSecsLeftInWaitingPeriod(address(this), currencyKey);
    }
    function calcRate() internal view returns (uint) {
        if (initialSupply == 0) {
            return 0;
        }
        uint synthBalance;
        if (!settled) {
            synthBalance = IERC20(address(synth)).balanceOf(address(this));
            (uint reclaim, uint rebate, ) = exchanger().settlementOwing(address(this), currencyKey);
            if (reclaim > 0) {
                synthBalance = synthBalance.sub(reclaim);
            } else if (rebate > 0) {
                synthBalance = synthBalance.add(rebate);
            }
        } else {
            synthBalance = settledAmount;
        }
        return synthBalance.divideDecimalRound(initialSupply);
    }
    function balanceUnderlying(address account) internal view returns (uint) {
        uint vBalanceOfAccount = balanceOf(account);
        return vBalanceOfAccount.multiplyDecimalRound(calcRate());
    }
    function settleSynth() internal {
        if (settled) {
            return;
        }
        settled = true;
        exchanger().settle(address(this), currencyKey);
        settledAmount = IERC20(address(synth)).balanceOf(address(this));
        emit Settled(totalSupply(), settledAmount);
    }
    function name() external view returns (string memory) {
        return string(abi.encodePacked("Virtual Synth ", currencyKey));
    }
    function symbol() external view returns (string memory) {
        return string(abi.encodePacked("v", currencyKey));
    }
    function rate() external view returns (uint) {
        return calcRate();
    }
    function balanceOfUnderlying(address account) external view returns (uint) {
        return balanceUnderlying(account);
    }
    function secsLeftInWaitingPeriod() external view returns (uint) {
        return secsLeft();
    }
    function readyToSettle() external view returns (bool) {
        return secsLeft() == 0;
    }
    function settle(address account) external {
        settleSynth();
        IERC20(address(synth)).transfer(account, balanceUnderlying(account));
        _burn(account, balanceOf(account));
    }
    event Settled(uint totalSupply, uint amountAfterSettled);
}