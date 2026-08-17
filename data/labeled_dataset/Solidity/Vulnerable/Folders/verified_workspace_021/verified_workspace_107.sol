pragma solidity ^0.5.16;
import "./Owned.sol";
import "./interfaces/IAddressResolver.sol";
import "./interfaces/IWrapper.sol";
import "./interfaces/ISynth.sol";
import "./interfaces/IERC20.sol";
import "./Pausable.sol";
import "./interfaces/IExchangeRates.sol";
import "./interfaces/IDebtCache.sol";
import "./interfaces/ISystemStatus.sol";
import "./interfaces/IWrapperFactory.sol";
import "./MixinResolver.sol";
import "./MixinSystemSettings.sol";
import "./SafeDecimalMath.sol";
contract Wrapper is Owned, Pausable, MixinResolver, MixinSystemSettings, IWrapper {
    using SafeMath for uint;
    using SafeDecimalMath for uint;
    bytes32 internal constant sUSD = "sUSD";
    bytes32 private constant CONTRACT_SYNTH_SUSD = "SynthsUSD";
    bytes32 private constant CONTRACT_EXRATES = "ExchangeRates";
    bytes32 private constant CONTRACT_DEBTCACHE = "DebtCache";
    bytes32 private constant CONTRACT_SYSTEMSTATUS = "SystemStatus";
    bytes32 private constant CONTRACT_WRAPPERFACTORY = "WrapperFactory";
    IERC20 public token;
    bytes32 public currencyKey;
    bytes32 public synthContractName;
    uint public targetSynthIssued;
    constructor(
        address _owner,
        address _resolver,
        IERC20 _token,
        bytes32 _currencyKey,
        bytes32 _synthContractName
    ) public Owned(_owner) MixinSystemSettings(_resolver) {
        token = _token;
        currencyKey = _currencyKey;
        synthContractName = _synthContractName;
        targetSynthIssued = 0;
        token.approve(address(this), uint256(-1));
    }
    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        bytes32[] memory existingAddresses = MixinSystemSettings.resolverAddressesRequired();
        bytes32[] memory newAddresses = new bytes32[](6);
        newAddresses[0] = CONTRACT_SYNTH_SUSD;
        newAddresses[1] = synthContractName;
        newAddresses[2] = CONTRACT_EXRATES;
        newAddresses[3] = CONTRACT_DEBTCACHE;
        newAddresses[4] = CONTRACT_SYSTEMSTATUS;
        newAddresses[5] = CONTRACT_WRAPPERFACTORY;
        addresses = combineArrays(existingAddresses, newAddresses);
        return addresses;
    }
    function synthsUSD() internal view returns (ISynth) {
        return ISynth(requireAndGetAddress(CONTRACT_SYNTH_SUSD));
    }
    function synth() internal view returns (ISynth) {
        return ISynth(requireAndGetAddress(synthContractName));
    }
    function exchangeRates() internal view returns (IExchangeRates) {
        return IExchangeRates(requireAndGetAddress(CONTRACT_EXRATES));
    }
    function debtCache() internal view returns (IDebtCache) {
        return IDebtCache(requireAndGetAddress(CONTRACT_DEBTCACHE));
    }
    function systemStatus() internal view returns (ISystemStatus) {
        return ISystemStatus(requireAndGetAddress(CONTRACT_SYSTEMSTATUS));
    }
    function wrapperFactory() internal view returns (IWrapperFactory) {
        return IWrapperFactory(requireAndGetAddress(CONTRACT_WRAPPERFACTORY));
    }
    function capacity() public view returns (uint _capacity) {
        uint balance = getReserves();
        uint maxToken = maxTokenAmount();
        if (balance >= maxToken) {
            return 0;
        }
        return maxToken.sub(balance);
    }
    function totalIssuedSynths() public view returns (uint) {
        return exchangeRates().effectiveValue(currencyKey, targetSynthIssued, sUSD);
    }
    function getReserves() public view returns (uint) {
        return token.balanceOf(address(this));
    }
    function calculateMintFee(uint amount) public view returns (uint, bool) {
        int r = mintFeeRate();
        if (r < 0) {
            return (amount.multiplyDecimalRound(uint(-r)), true);
        } else {
            return (amount.multiplyDecimalRound(uint(r)), false);
        }
    }
    function calculateBurnFee(uint amount) public view returns (uint, bool) {
        int r = burnFeeRate();
        if (r < 0) {
            return (amount.multiplyDecimalRound(uint(-r)), true);
        } else {
            return (amount.multiplyDecimalRound(uint(r)), false);
        }
    }
    function maxTokenAmount() public view returns (uint256) {
        return getWrapperMaxTokenAmount(address(this));
    }
    function mintFeeRate() public view returns (int256) {
        return getWrapperMintFeeRate(address(this));
    }
    function burnFeeRate() public view returns (int256) {
        return getWrapperBurnFeeRate(address(this));
    }
    function mint(uint amountIn) external notPaused issuanceActive {
        require(amountIn <= token.allowance(msg.sender, address(this)), "Allowance not high enough");
        require(amountIn <= token.balanceOf(msg.sender), "Balance is too low");
        require(!exchangeRates().rateIsInvalid(currencyKey), "Currency rate is invalid");
        uint currentCapacity = capacity();
        require(currentCapacity > 0, "Contract has no spare capacity to mint");
        uint actualAmountIn = currentCapacity < amountIn ? currentCapacity : amountIn;
        (uint feeAmountTarget, bool negative) = calculateMintFee(actualAmountIn);
        uint mintAmount = negative ? actualAmountIn.add(feeAmountTarget) : actualAmountIn.sub(feeAmountTarget);
        bool success = _safeTransferFrom(address(token), msg.sender, address(this), actualAmountIn);
        require(success, "Transfer did not succeed");
        _mint(mintAmount);
        emit Minted(msg.sender, mintAmount, negative ? 0 : feeAmountTarget, actualAmountIn);
    }
    function burn(uint amountIn) external notPaused issuanceActive {
        require(amountIn <= IERC20(address(synth())).balanceOf(msg.sender), "Balance is too low");
        require(!exchangeRates().rateIsInvalid(currencyKey), "Currency rate is invalid");
        require(totalIssuedSynths() > 0, "Contract cannot burn for token, token balance is zero");
        (uint burnFee, bool negative) = calculateBurnFee(targetSynthIssued);
        uint burnAmount;
        uint amountOut;
        if (negative) {
            burnAmount = targetSynthIssued < amountIn ? targetSynthIssued.sub(burnFee) : amountIn;
            amountOut = burnAmount.multiplyDecimal(
                uint(int(SafeDecimalMath.unit()) - burnFeeRate())
            );
        } else {
            burnAmount = targetSynthIssued.add(burnFee) < amountIn ? targetSynthIssued.add(burnFee) : amountIn;
            amountOut = burnAmount.divideDecimal(
                uint(int(SafeDecimalMath.unit()) + burnFeeRate())
            );
        }
        uint feeAmountTarget = negative ? 0 : burnAmount.sub(amountOut);
        bool success = _safeTransferFrom(address(token), address(this), msg.sender, amountOut);
        require(success, "Transfer did not succeed");
        _burn(burnAmount);
        emit Burned(msg.sender, amountOut, feeAmountTarget, burnAmount);
    }
    function() external payable {
        revert("Fallback disabled, use mint()");
    }
    function _mint(uint amount) internal {
        uint reserves = getReserves();
        uint excessAmount = reserves > targetSynthIssued.add(amount) ? reserves.sub(targetSynthIssued.add(amount)) : 0;
        uint excessAmountUsd = exchangeRates().effectiveValue(currencyKey, excessAmount, sUSD);
        synth().issue(msg.sender, amount);
        if (excessAmountUsd > 0) {
            synthsUSD().issue(address(wrapperFactory()), excessAmountUsd);
        }
        _setTargetSynthIssued(reserves);
    }
    function _burn(uint amount) internal {
        uint reserves = getReserves();
        uint excessAmount = reserves.add(amount) > targetSynthIssued ? reserves.add(amount).sub(targetSynthIssued) : 0;
        uint excessAmountUsd = exchangeRates().effectiveValue(currencyKey, excessAmount, sUSD);
        synth().burn(msg.sender, amount);
        if (excessAmountUsd > 0) {
            synthsUSD().issue(address(wrapperFactory()), excessAmountUsd);
        }
        _setTargetSynthIssued(reserves);
    }
    function _setTargetSynthIssued(uint _targetSynthIssued) internal {
        debtCache().recordExcludedDebtChange(currencyKey, int256(_targetSynthIssued) - int256(targetSynthIssued));
        targetSynthIssued = _targetSynthIssued;
    }
    function _safeTransferFrom(
        address _tokenAddress,
        address _from,
        address _to,
        uint256 _value
    ) internal returns (bool success) {
        bytes memory msgData = abi.encodeWithSignature("transferFrom(address,address,uint256)", _from, _to, _value);
        uint msgSize = msgData.length;
        assembly {
            mstore(0x00, 0xff)
            if iszero(call(gas(), _tokenAddress, 0, add(msgData, 0x20), msgSize, 0x00, 0x20)) {
                revert(0, 0)
            }
            switch mload(0x00)
                case 0xff {
                    success := 1
                }
                case 0x01 {
                    success := 1
                }
                case 0x00 {
                    success := 0
                }
                default {
                    revert(0, 0)
                }
        }
    }
    modifier issuanceActive {
        systemStatus().requireIssuanceActive();
        _;
    }
    event Minted(address indexed account, uint principal, uint fee, uint amountIn);
    event Burned(address indexed account, uint principal, uint fee, uint amountIn);
}