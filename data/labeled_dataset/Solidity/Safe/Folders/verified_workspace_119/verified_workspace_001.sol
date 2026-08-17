pragma solidity ^0.8.0;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
pragma solidity ^0.8.0;
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _setOwner(_msgSender());
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }
    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
pragma solidity 0.8.9;
interface IAllocKafra {
    function MAX_ALLOCATION() external view returns (uint16);
    function limitAllocation() external view returns (uint16);
    function canAllocate(
        uint256 _amount,
        uint256 _balanceOfWant,
        uint256 _balanceOfMasterChef,
        address _user
    ) external view returns (bool);
}
pragma solidity 0.8.9;
contract AllocKafra is Ownable, IAllocKafra {
    uint16 public constant override MAX_ALLOCATION = 10000;
    uint16 public override limitAllocation;
    event SetLimitAllocation(uint16 limitAllocation);
    constructor(uint16 _limitAllocation) {
        limitAllocation = _limitAllocation;
    }
    function canAllocate(
        uint256,
        uint256 _balanceOfWant,
        uint256 _balanceOfMasterChef,
        address
    ) external view override returns (bool) {
        if (limitAllocation == 0) {
            return true;
        }
        uint256 percentage = (_balanceOfWant * MAX_ALLOCATION) / _balanceOfMasterChef;
        return percentage <= limitAllocation;
    }
    function setLimitAllocation(uint16 _limitAllocation) external onlyOwner {
        require(_limitAllocation <= MAX_ALLOCATION, "invalid limit");
        limitAllocation = _limitAllocation;
        emit SetLimitAllocation(_limitAllocation);
    }
}