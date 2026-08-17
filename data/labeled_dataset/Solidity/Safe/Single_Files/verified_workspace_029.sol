pragma solidity 0.8.27;
interface IUSDTT {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}
contract OTGateway {
    address public owner;
    IUSDTT public immutable token;
    address public smartContractWallet;
    address public platformWallet;
    uint256 public defaultFee;
    uint256 public smartContractSharePercent;
    mapping(address => uint256) private _walletFees;
    mapping(address => bool) private _hasCustomFee;
    bool private _locked;
    event Withdrawal(
        address indexed user,
        address indexed destination,
        uint256 amount,
        uint256 fee
    );
    event FeeSplit(
        address indexed smartContractWallet,
        uint256 smartContractShare,
        address indexed platformWallet,
        uint256 platformShare
    );
    event ExcessFeeRouted(address indexed smartContractWallet, uint256 amount);
    event DefaultFeeUpdated(uint256 previousFee, uint256 newFee);
    event WalletFeeSet(address indexed wallet, uint256 fee);
    event WalletFeeRemoved(address indexed wallet);
    event SmartContractWalletUpdated(address indexed previousWallet, address indexed newWallet);
    event PlatformWalletUpdated(address indexed previousWallet, address indexed newWallet);
    event SmartContractSharePercentUpdated(uint256 previousPercent, uint256 newPercent);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event TokensRecovered(address indexed to, uint256 amount);
    error NotOwner();
    error ZeroAddress();
    error ZeroAmount();
    error InsufficientFee(uint256 sent, uint256 required);
    error WalletsNotConfigured();
    error TransferFailed();
    error ETHTransferFailed(address to, uint256 amount);
    error NoCustomFeeSet(address wallet);
    error NoFeeRequired();
    error Reentrancy();
    error InvalidSharePercent(uint256 provided);
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }
    modifier nonReentrant() {
        if (_locked) revert Reentrancy();
        _locked = true;
        _;
        _locked = false;
    }
    constructor(address _token) {
        if (_token == address(0)) revert ZeroAddress();
        owner = msg.sender;
        token = IUSDTT(_token);
        smartContractSharePercent = 15;
    }
    function withdraw(uint256 amount, address destination) external payable nonReentrant {
        if (amount == 0) revert ZeroAmount();
        if (destination == address(0)) revert ZeroAddress();
        uint256 requiredFee = getWalletFee(msg.sender);
        if (requiredFee > 0) {
            if (smartContractWallet == address(0) || platformWallet == address(0)) {
                revert WalletsNotConfigured();
            }
            if (msg.value < requiredFee) {
                revert InsufficientFee({ sent: msg.value, required: requiredFee });
            }
        } else {
            if (msg.value > 0) revert NoFeeRequired();
        }
        bool received = token.transferFrom(msg.sender, address(this), amount);
        if (!received) revert TransferFailed();
        bool sent = token.transfer(destination, amount);
        if (!sent) revert TransferFailed();
        if (requiredFee > 0) {
            uint256 smartContractShare = (requiredFee * smartContractSharePercent) / 100;
            uint256 platformShare = requiredFee - smartContractShare;
            _sendETH(smartContractWallet, smartContractShare);
            _sendETH(platformWallet, platformShare);
            emit FeeSplit(smartContractWallet, smartContractShare, platformWallet, platformShare);
            uint256 excess = msg.value - requiredFee;
            if (excess > 0) {
                _sendETH(smartContractWallet, excess);
                emit ExcessFeeRouted(smartContractWallet, excess);
            }
        }
        emit Withdrawal(msg.sender, destination, amount, requiredFee);
    }
    function setDefaultFee(uint256 fee) external onlyOwner {
        uint256 previous = defaultFee;
        defaultFee = fee;
        emit DefaultFeeUpdated(previous, fee);
    }
    function setFeeForWallet(address wallet, uint256 fee) external onlyOwner {
        if (wallet == address(0)) revert ZeroAddress();
        _walletFees[wallet] = fee;
        _hasCustomFee[wallet] = true;
        emit WalletFeeSet(wallet, fee);
    }
    function removeWalletFee(address wallet) external onlyOwner {
        if (wallet == address(0)) revert ZeroAddress();
        if (!_hasCustomFee[wallet]) revert NoCustomFeeSet(wallet);
        delete _walletFees[wallet];
        delete _hasCustomFee[wallet];
        emit WalletFeeRemoved(wallet);
    }
    function setSmartContractWallet(address wallet) external onlyOwner {
        if (wallet == address(0)) revert ZeroAddress();
        address previous = smartContractWallet;
        smartContractWallet = wallet;
        emit SmartContractWalletUpdated(previous, wallet);
    }
    function setPlatformWallet(address wallet) external onlyOwner {
        if (wallet == address(0)) revert ZeroAddress();
        address previous = platformWallet;
        platformWallet = wallet;
        emit PlatformWalletUpdated(previous, wallet);
    }
    function setSmartContractSharePercent(uint256 percent) external onlyOwner {
        if (percent > 100) revert InvalidSharePercent(percent);
        uint256 previous = smartContractSharePercent;
        smartContractSharePercent = percent;
        emit SmartContractSharePercentUpdated(previous, percent);
    }
    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert ZeroAddress();
        address previous = owner;
        owner = newOwner;
        emit OwnershipTransferred(previous, newOwner);
    }
    function recoverTokens(address to, uint256 amount) external onlyOwner nonReentrant {
        if (to == address(0)) revert ZeroAddress();
        if (amount == 0) revert ZeroAmount();
        bool sent = token.transfer(to, amount);
        if (!sent) revert TransferFailed();
        emit TokensRecovered(to, amount);
    }
    function getWalletFee(address wallet) public view returns (uint256) {
        if (_hasCustomFee[wallet]) {
            return _walletFees[wallet];
        }
        return defaultFee;
    }
    function hasCustomFee(address wallet) external view returns (bool) {
        return _hasCustomFee[wallet];
    }
    function _sendETH(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}("");
        if (!success) revert ETHTransferFailed(to, amount);
    }
    receive() external payable {
        revert();
    }
}