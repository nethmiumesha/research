pragma solidity ^0.8.20;
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
contract PaymentSplitter is Ownable {
    using SafeERC20 for IERC20;
    event PaymentReceived(address indexed from, uint256 amount);
    event PaymentSplit(address indexed recipient, uint256 amount);
    event ERC20PaymentSplit(address indexed token, address indexed recipient, uint256 amount);
    event RecipientsUpdated(address[] recipients, uint256[] basisPoints, address indexed defaultRecipient);
    event NameUpdated(string newName);
    event WETHAddressUpdated(address indexed wethAddress);
    error Splitter__InvalidRecipients();
    error Splitter__InvalidBasisPoints();
    error Splitter__TransferFailed();
    error Splitter__MismatchedArrays();
    error Splitter__NoDefaultRecipient();
    error Splitter__InvalidToken();
    error Splitter__NoBalance();
    struct Recipient {
        address payable wallet;
        uint256 basisPoints;
    }
    string public name;
    Recipient[] public recipients;
    address payable public defaultRecipient;
    address public wethAddress;
    uint256 private constant BASIS_POINTS_TOTAL = 10000;
    constructor(
        string memory name_,
        address owner_,
        address defaultRecipient_,
        address[] memory recipients_,
        uint256[] memory basisPoints_,
        address wethAddress_
    ) {
        if (defaultRecipient_ == address(0)) revert Splitter__NoDefaultRecipient();
        name = name_;
        defaultRecipient = payable(defaultRecipient_);
        wethAddress = wethAddress_;
        _transferOwnership(owner_);
        _setRecipients(recipients_, basisPoints_);
    }
    receive() external payable {
        if (msg.value == 0) return;
        emit PaymentReceived(msg.sender, msg.value);
        if (wethAddress != address(0)) {
            _splitERC20Internal(wethAddress);
        }
        uint256 remaining = msg.value;
        uint256 recipientCount = recipients.length;
        for (uint256 i = 0; i < recipientCount; i++) {
            uint256 amount = (msg.value * recipients[i].basisPoints) / BASIS_POINTS_TOTAL;
            remaining -= amount;
            (bool success, ) = recipients[i].wallet.call{value: amount}("");
            if (!success) revert Splitter__TransferFailed();
            emit PaymentSplit(recipients[i].wallet, amount);
        }
        if (remaining > 0) {
            (bool finalSuccess, ) = defaultRecipient.call{value: remaining}("");
            if (!finalSuccess) revert Splitter__TransferFailed();
            emit PaymentSplit(defaultRecipient, remaining);
        }
    }
    function setName(string memory newName) external onlyOwner {
        name = newName;
        emit NameUpdated(newName);
    }
    function setDefaultRecipient(address newDefaultRecipient) external onlyOwner {
        if (newDefaultRecipient == address(0)) revert Splitter__NoDefaultRecipient();
        defaultRecipient = payable(newDefaultRecipient);
        emit RecipientsUpdated(_getRecipientAddresses(), _getRecipientBasisPoints(), newDefaultRecipient);
    }
    function setRecipients(
        address[] memory recipients_,
        uint256[] memory basisPoints_
    ) external onlyOwner {
        _setRecipients(recipients_, basisPoints_);
    }
    function setWETHAddress(address wethAddress_) external onlyOwner {
        wethAddress = wethAddress_;
        emit WETHAddressUpdated(wethAddress_);
    }
    function withdrawERC20(address token) external {
        if (token == address(0)) revert Splitter__InvalidToken();
        IERC20 erc20 = IERC20(token);
        uint256 balance = erc20.balanceOf(address(this));
        if (balance == 0) revert Splitter__NoBalance();
        _splitERC20Internal(token);
    }
    function transferOwnership(address newOwner) public override onlyOwner {
        super.transferOwnership(newOwner);
    }
    function _splitERC20Internal(address token) internal {
        IERC20 erc20 = IERC20(token);
        uint256 balance = erc20.balanceOf(address(this));
        if (balance == 0) return;
        uint256 remaining = balance;
        uint256 recipientCount = recipients.length;
        for (uint256 i = 0; i < recipientCount; i++) {
            uint256 amount = (balance * recipients[i].basisPoints) / BASIS_POINTS_TOTAL;
            remaining -= amount;
            erc20.safeTransfer(recipients[i].wallet, amount);
            emit ERC20PaymentSplit(token, recipients[i].wallet, amount);
        }
        if (remaining > 0) {
            erc20.safeTransfer(defaultRecipient, remaining);
            emit ERC20PaymentSplit(token, defaultRecipient, remaining);
        }
    }
    function _setRecipients(
        address[] memory recipients_,
        uint256[] memory basisPoints_
    ) internal {
        if (recipients_.length != basisPoints_.length) revert Splitter__MismatchedArrays();
        uint256 totalBps = 0;
        for (uint256 i = 0; i < basisPoints_.length; i++) {
            if (recipients_[i] == address(0)) revert Splitter__InvalidRecipients();
            totalBps += basisPoints_[i];
        }
        if (totalBps > BASIS_POINTS_TOTAL) revert Splitter__InvalidBasisPoints();
        delete recipients;
        for (uint256 i = 0; i < recipients_.length; i++) {
            recipients.push(Recipient({
                wallet: payable(recipients_[i]),
                basisPoints: basisPoints_[i]
            }));
        }
        emit RecipientsUpdated(recipients_, basisPoints_, defaultRecipient);
    }
    function _getRecipientAddresses() internal view returns (address[] memory) {
        address[] memory addresses = new address[](recipients.length);
        for (uint256 i = 0; i < recipients.length; i++) {
            addresses[i] = recipients[i].wallet;
        }
        return addresses;
    }
    function _getRecipientBasisPoints() internal view returns (uint256[] memory) {
        uint256[] memory bps = new uint256[](recipients.length);
        for (uint256 i = 0; i < recipients.length; i++) {
            bps[i] = recipients[i].basisPoints;
        }
        return bps;
    }
    function getRecipients() external view returns (address[] memory wallets, uint256[] memory basisPoints) {
        uint256 length = recipients.length;
        wallets = new address[](length);
        basisPoints = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            wallets[i] = recipients[i].wallet;
            basisPoints[i] = recipients[i].basisPoints;
        }
    }
}