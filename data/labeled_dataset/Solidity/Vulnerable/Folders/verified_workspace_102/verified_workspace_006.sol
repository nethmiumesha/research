pragma solidity ^0.4.25;
contract Ownable {
    event TransferredOwnership(address _from, address _to);
    event LockedOwnership(address _locked);
    address private _owner;
    bool private _isTransferable;
    constructor(address _account_, bool _transferable_) internal {
        _owner = _account_;
        _isTransferable = _transferable_;
        if (!_isTransferable) {
            emit LockedOwnership(_account_);
        }
        emit TransferredOwnership(address(0), _account_);
    }
    modifier onlyOwner() {
        require(_isOwner(msg.sender), "sender is not an owner");
        _;
    }
    function transferOwnership(address _account, bool _transferable) external onlyOwner {
        require(_isTransferable, "ownership is not transferable");
        require(_account != address(0), "owner cannot be set to zero address");
        _isTransferable = _transferable;
        if (!_transferable) {
            emit LockedOwnership(_account);
        }
        emit TransferredOwnership(_owner, _account);
        _owner = _account;
    }
    function isTransferable() external view returns (bool) {
        return _isTransferable;
    }
    function renounceOwnership() external onlyOwner {
        require(_isTransferable, "ownership is not transferable");
        _owner = address(0);
        emit TransferredOwnership(_owner, address(0));
    }
    function owner() public view returns (address) {
        return _owner;
    }
    function _isOwner(address _address) internal view returns (bool) {
        return _address == _owner;
    }
}