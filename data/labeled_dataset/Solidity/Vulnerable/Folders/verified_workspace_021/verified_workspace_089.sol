pragma solidity ^0.5.16;
import "./Owned.sol";
import "./ExternStateToken.sol";
import "./MixinResolver.sol";
import "./interfaces/ISynth.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/ISystemStatus.sol";
import "./interfaces/IFeePool.sol";
import "./interfaces/IExchanger.sol";
import "./interfaces/IIssuer.sol";
import "./interfaces/IFuturesMarketManager.sol";
contract Synth is Owned, IERC20, ExternStateToken, MixinResolver, ISynth {
    bytes32 public constant CONTRACT_NAME = "Synth";
    bytes32 public currencyKey;
    uint8 public constant DECIMALS = 18;
    address public constant FEE_ADDRESS = 0xfeEFEEfeefEeFeefEEFEEfEeFeefEEFeeFEEFEeF;
    bytes32 private constant CONTRACT_SYSTEMSTATUS = "SystemStatus";
    bytes32 private constant CONTRACT_EXCHANGER = "Exchanger";
    bytes32 private constant CONTRACT_ISSUER = "Issuer";
    bytes32 private constant CONTRACT_FEEPOOL = "FeePool";
    bytes32 private constant CONTRACT_FUTURESMARKETMANAGER = "FuturesMarketManager";
    constructor(
        address payable _proxy,
        TokenState _tokenState,
        string memory _tokenName,
        string memory _tokenSymbol,
        address _owner,
        bytes32 _currencyKey,
        uint _totalSupply,
        address _resolver
    )
        public
        ExternStateToken(_proxy, _tokenState, _tokenName, _tokenSymbol, _totalSupply, DECIMALS, _owner)
        MixinResolver(_resolver)
    {
        require(_proxy != address(0), "_proxy cannot be 0");
        require(_owner != address(0), "_owner cannot be 0");
        currencyKey = _currencyKey;
    }
    function transfer(address to, uint value) public onlyProxyOrInternal returns (bool) {
        _ensureCanTransfer(messageSender, value);
        if (to == FEE_ADDRESS) {
            return _transferToFeeAddress(to, value);
        }
        if (to == address(0)) {
            return _internalBurn(messageSender, value);
        }
        return super._internalTransfer(messageSender, to, value);
    }
    function transferAndSettle(address to, uint value) public onlyProxyOrInternal returns (bool) {
        (, , uint numEntriesSettled) = exchanger().settle(messageSender, currencyKey);
        uint balanceAfter = value;
        if (numEntriesSettled > 0) {
            balanceAfter = tokenState.balanceOf(messageSender);
        }
        value = value > balanceAfter ? balanceAfter : value;
        return super._internalTransfer(messageSender, to, value);
    }
    function transferFrom(
        address from,
        address to,
        uint value
    ) public onlyProxyOrInternal returns (bool) {
        _ensureCanTransfer(from, value);
        return _internalTransferFrom(from, to, value);
    }
    function transferFromAndSettle(
        address from,
        address to,
        uint value
    ) public onlyProxyOrInternal returns (bool) {
        (, , uint numEntriesSettled) = exchanger().settle(from, currencyKey);
        uint balanceAfter = value;
        if (numEntriesSettled > 0) {
            balanceAfter = tokenState.balanceOf(from);
        }
        value = value >= balanceAfter ? balanceAfter : value;
        return _internalTransferFrom(from, to, value);
    }
    function _transferToFeeAddress(address to, uint value) internal returns (bool) {
        uint amountInUSD;
        if (currencyKey == "sUSD") {
            amountInUSD = value;
            super._internalTransfer(messageSender, to, value);
        } else {
            (amountInUSD, ) = exchanger().exchange(
                messageSender,
                messageSender,
                currencyKey,
                value,
                "sUSD",
                FEE_ADDRESS,
                false,
                address(0),
                bytes32(0)
            );
        }
        feePool().recordFeePaid(amountInUSD);
        return true;
    }
    function issue(address account, uint amount) external onlyInternalContracts {
        _internalIssue(account, amount);
    }
    function burn(address account, uint amount) external onlyInternalContracts {
        _internalBurn(account, amount);
    }
    function _internalIssue(address account, uint amount) internal {
        tokenState.setBalanceOf(account, tokenState.balanceOf(account).add(amount));
        totalSupply = totalSupply.add(amount);
        emitTransfer(address(0), account, amount);
        emitIssued(account, amount);
    }
    function _internalBurn(address account, uint amount) internal returns (bool) {
        tokenState.setBalanceOf(account, tokenState.balanceOf(account).sub(amount));
        totalSupply = totalSupply.sub(amount);
        emitTransfer(account, address(0), amount);
        emitBurned(account, amount);
        return true;
    }
    function setTotalSupply(uint amount) external optionalProxy_onlyOwner {
        totalSupply = amount;
    }
    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        addresses = new bytes32[](5);
        addresses[0] = CONTRACT_SYSTEMSTATUS;
        addresses[1] = CONTRACT_EXCHANGER;
        addresses[2] = CONTRACT_ISSUER;
        addresses[3] = CONTRACT_FEEPOOL;
        addresses[4] = CONTRACT_FUTURESMARKETMANAGER;
    }
    function systemStatus() internal view returns (ISystemStatus) {
        return ISystemStatus(requireAndGetAddress(CONTRACT_SYSTEMSTATUS));
    }
    function feePool() internal view returns (IFeePool) {
        return IFeePool(requireAndGetAddress(CONTRACT_FEEPOOL));
    }
    function exchanger() internal view returns (IExchanger) {
        return IExchanger(requireAndGetAddress(CONTRACT_EXCHANGER));
    }
    function issuer() internal view returns (IIssuer) {
        return IIssuer(requireAndGetAddress(CONTRACT_ISSUER));
    }
    function futuresMarketManager() internal view returns (IFuturesMarketManager) {
        return IFuturesMarketManager(requireAndGetAddress(CONTRACT_FUTURESMARKETMANAGER));
    }
    function _ensureCanTransfer(address from, uint value) internal view {
        require(exchanger().maxSecsLeftInWaitingPeriod(from, currencyKey) == 0, "Cannot transfer during waiting period");
        require(transferableSynths(from) >= value, "Insufficient balance after any settlement owing");
        systemStatus().requireSynthActive(currencyKey);
    }
    function transferableSynths(address account) public view returns (uint) {
        (uint reclaimAmount, , ) = exchanger().settlementOwing(account, currencyKey);
        uint balance = tokenState.balanceOf(account);
        if (reclaimAmount > balance) {
            return 0;
        } else {
            return balance.sub(reclaimAmount);
        }
    }
    function _internalTransferFrom(
        address from,
        address to,
        uint value
    ) internal returns (bool) {
        if (tokenState.allowance(from, messageSender) != uint(-1)) {
            tokenState.setAllowance(from, messageSender, tokenState.allowance(from, messageSender).sub(value));
        }
        return super._internalTransfer(from, to, value);
    }
    function _isInternalContract(address account) internal view returns (bool) {
        return
            account == address(feePool()) ||
            account == address(exchanger()) ||
            account == address(issuer()) ||
            account == address(futuresMarketManager());
    }
    modifier onlyInternalContracts() {
        require(_isInternalContract(msg.sender), "Only internal contracts allowed");
        _;
    }
    modifier onlyProxyOrInternal {
        _onlyProxyOrInternal();
        _;
    }
    function _onlyProxyOrInternal() internal {
        if (msg.sender == address(proxy)) {
            return;
        } else if (_isInternalTransferCaller(msg.sender)) {
            messageSender = msg.sender;
        } else {
            revert("Only the proxy can call");
        }
    }
    function _isInternalTransferCaller(address caller) internal view returns (bool) {
        return
            caller == resolver.getAddress("CollateralShort") ||
            caller == resolver.getAddress("SynthRedeemer") ||
            caller == resolver.getAddress("WrapperFactory") ||
            caller == resolver.getAddress("NativeEtherWrapper") ||
            caller == resolver.getAddress("Depot");
    }
    event Issued(address indexed account, uint value);
    bytes32 private constant ISSUED_SIG = keccak256("Issued(address,uint256)");
    function emitIssued(address account, uint value) internal {
        proxy._emit(abi.encode(value), 2, ISSUED_SIG, addressToBytes32(account), 0, 0);
    }
    event Burned(address indexed account, uint value);
    bytes32 private constant BURNED_SIG = keccak256("Burned(address,uint256)");
    function emitBurned(address account, uint value) internal {
        proxy._emit(abi.encode(value), 2, BURNED_SIG, addressToBytes32(account), 0, 0);
    }
}