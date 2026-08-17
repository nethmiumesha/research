pragma solidity ^0.5.16;
import "../ExternStateToken.sol";
import "../interfaces/ISystemStatus.sol";
import "../interfaces/IAddressResolver.sol";
import "../interfaces/IFeePool.sol";
contract MockSynth is ExternStateToken {
    IAddressResolver private addressResolver;
    bytes32 public currencyKey;
    address public constant FEE_ADDRESS = 0xfeEFEEfeefEeFeefEEFEEfEeFeefEEFeeFEEFEeF;
    constructor(
        address payable _proxy,
        TokenState _tokenState,
        string memory _name,
        string memory _symbol,
        uint _totalSupply,
        address _owner,
        bytes32 _currencyKey
    ) public ExternStateToken(_proxy, _tokenState, _name, _symbol, _totalSupply, 18, _owner) {
        currencyKey = _currencyKey;
    }
    function setAddressResolver(IAddressResolver _resolver) external {
        addressResolver = _resolver;
    }
    function setTotalSupply(uint256 _totalSupply) external {
        totalSupply = _totalSupply;
    }
    function _transferToFeeAddress(address to, uint value) internal returns (bool) {
        uint amountInUSD;
        if (currencyKey == "sUSD") {
            amountInUSD = value;
            _transferByProxy(messageSender, to, value);
        } else {
        }
        IFeePool(addressResolver.getAddress("FeePool")).recordFeePaid(amountInUSD);
        return true;
    }
    function transfer(address to, uint value) external optionalProxy returns (bool) {
        ISystemStatus(addressResolver.getAddress("SystemStatus")).requireSynthActive(currencyKey);
        if (to == FEE_ADDRESS) {
            return _transferToFeeAddress(to, value);
        }
        if (to == address(0)) {
            this.burn(messageSender, value);
            return true;
        }
        return _transferByProxy(messageSender, to, value);
    }
    function transferFrom(
        address from,
        address to,
        uint value
    ) external optionalProxy returns (bool) {
        ISystemStatus(addressResolver.getAddress("SystemStatus")).requireSynthActive(currencyKey);
        return _transferFromByProxy(messageSender, from, to, value);
    }
    event Issued(address indexed account, uint value);
    event Burned(address indexed account, uint value);
    function issue(address account, uint amount) external {
        tokenState.setBalanceOf(account, tokenState.balanceOf(account).add(amount));
        totalSupply = totalSupply.add(amount);
        emit Issued(account, amount);
    }
    function burn(address account, uint amount) external {
        tokenState.setBalanceOf(account, tokenState.balanceOf(account).sub(amount));
        totalSupply = totalSupply.sub(amount);
        emit Burned(account, amount);
    }
}