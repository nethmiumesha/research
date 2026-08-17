pragma solidity >=0.6.0 <0.8.0;
abstract contract ManagedPausable {
    event Paused(address account);
    event Unpaused(address account);
    event PauserRoleTransferred(address indexed previousPauser, address indexed newPauser);
    uint256 private constant FALSE = 0;
    uint256 private constant TRUE = 1;
    uint256 private _initialized;
    uint256 private _paused;
    address private _pauser;
    function _initializeManagedPausable(address pauser_) internal {
        require(_initialized == FALSE);
        _initialized = TRUE;
        _paused = FALSE;
        _pauser = pauser_;
    }
    function paused() public view returns (bool) {
        return _paused != FALSE;
    }
    function pauser() public view returns (address) {
        return _pauser;
    }
    function renouncePauserRole() external onlyPauser {
        emit PauserRoleTransferred(_pauser, address(0));
        _pauser = address(0);
    }
    function transferPauserRole(address newPauser) external onlyPauser {
        require(newPauser != address(0));
        emit PauserRoleTransferred(_pauser, newPauser);
        _pauser = newPauser;
    }
    modifier onlyPauser() {
        require(_pauser == msg.sender, "Pausable: only pauser");
        _;
    }
    modifier whenNotPaused() {
        require(_paused == FALSE, "Pausable: paused");
        _;
    }
    modifier whenPaused() {
        require(_paused != FALSE, "Pausable: not paused");
        _;
    }
    function pause() external onlyPauser whenNotPaused {
        _paused = TRUE;
        emit Paused(msg.sender);
    }
    function unpause() external onlyPauser whenPaused {
        _paused = FALSE;
        emit Unpaused(msg.sender);
    }
}