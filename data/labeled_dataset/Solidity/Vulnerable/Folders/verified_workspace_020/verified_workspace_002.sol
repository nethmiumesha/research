pragma solidity ^0.8.3;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
abstract contract Pausable is Context {
    event Paused(address account);
    event Unpaused(address account);
    bool private _paused;
    constructor () {
        _paused = false;
    }
    function paused() public view virtual returns (bool) {
        return _paused;
    }
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}
abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    constructor () {
        _status = _NOT_ENTERED;
    }
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
interface IERC1155 is IERC165 {
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}
contract Staking is Ownable, Pausable, ReentrancyGuard {
	using SafeMath for uint256;
	struct UserInfo {
		uint256 amount;
		uint256 createdAt;
		uint256 lastUpdateAt;
		uint256 pointsDebt;
	}
	uint256 public minimumAmount = 1 * (10**18);
	uint256 public maxAmount = 1000 * (10**18);
	uint256 public lockTime = 5 minutes;
	uint256 public emissionRate;
	IERC20 spiToken;
	mapping(address => UserInfo) public userInfo;
	event StakeClaimed(address user, uint256 amount);
	event RewardAdded(uint256 amount);
	event EmissionRateChanged(uint256 newEmissionRate);
	constructor(IERC20 _lpToken, uint256 _emissionRate) {
		spiToken = _lpToken;
		emissionRate = _emissionRate;
	}
	function addReward(uint256 _amount) external {
		spiToken.transferFrom(msg.sender, address(this), _amount);
		emit RewardAdded(_amount);
	}
	function stake(uint256 _amount) external whenNotPaused nonReentrant {
		require(_amount >= minimumAmount, "amount below minimumAmount");
		require(_amount <= maxAmount, "amount greater than maxAmount");
		require(spiToken.transferFrom(msg.sender, address(this), _amount), "failed to transfer");
		UserInfo storage user = userInfo[msg.sender];
		if (user.amount != 0) {
			user.pointsDebt = pointsBalance(msg.sender);
		}
		user.amount = user.amount.add(_amount);
		user.lastUpdateAt = block.timestamp;
		user.createdAt = block.timestamp;
	}
	function claim() public nonReentrant {
		UserInfo storage user = userInfo[msg.sender];
		uint256 amountToTransfer = pointsBalance(msg.sender);
		user.pointsDebt = 0;
		user.lastUpdateAt = block.timestamp;
		spiToken.transfer(msg.sender, amountToTransfer);
	}
	function unstake() external {
		UserInfo storage user = userInfo[msg.sender];
		require(user.amount >= 0, "insufficient staked");
		require(user.createdAt + lockTime <= block.timestamp, "tokens are locked");
		claim();
		uint256 userAmount = user.amount;
		user.amount = 0;
		spiToken.transfer(msg.sender, userAmount);
	}
	function _unDebitedPoints(UserInfo memory user) internal view returns (uint256) {
		return block.timestamp.sub(user.lastUpdateAt).mul(emissionRate).mul(user.amount).div(1e18);
	}
	function pointsBalance(address userAddress) public view returns (uint256) {
		UserInfo memory user = userInfo[userAddress];
		return user.pointsDebt.add(_unDebitedPoints(user));
	}
	function changeEmissionRate(uint256 newEmissionRate) public onlyOwner {
		emissionRate = newEmissionRate;
		emit EmissionRateChanged(newEmissionRate);
	}
	function reclaimToken(IERC20 token, uint256 _amount) public onlyOwner {
		require(address(token) != address(0), "no 0 address");
		require(address(token) != address(spiToken), "can't withdraw the reward");
		uint256 balance = token.balanceOf(address(this));
		require(_amount <= balance, "you can't withdraw more than you have");
		token.transfer(msg.sender, _amount);
	}
	function pause() public onlyOwner {
		_pause();
	}
	function unpause() public onlyOwner {
		_unpause();
	}
	function withdraw() public onlyOwner {
		uint256 balance = address(this).balance;
		payable(msg.sender).transfer(balance);
	}
}