pragma solidity 0.8.11;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _transferOwnership(_msgSender());
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}
library SafeERC20 {
    using Address for address;
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    constructor() {
        _status = _NOT_ENTERED;
    }
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}
contract ThorusLaunchpad is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    address public immutable treasury;
    IERC20 public immutable thorus;
    IERC20 public immutable reward;
    uint256 public immutable thorusHardcap;
    uint256 public immutable rewardOffered;
    uint256 public immutable ticketsHardcap;
    uint256 public immutable ticketPrice;
    bool public buyingAllowed = false;
    bool public claimingAllowed = false;
    bool public ticketsWithdrawn = false;
    event BuyingStarted();
    event BuyingStopped();
    event TicketsWithdrawn();
    event ClaimingStarted();
    event Buy(uint256 amount, address indexed user);
    event Claim(uint256 amount, address indexed user);
    event ThorusWithdrawn(uint256 amount);
    event ExcessiveRewardWithdrawn(uint256 amount);
    struct Ticket {
        address owner;
        bool isWinning;
        bool isClaimed;
    }
    Ticket[] public tickets;
    mapping(address => uint) public ownerTicketsCount;
    constructor(IERC20 _thorus, IERC20 _reward, uint256 _thorusHardcap, uint256 _rewardOffered, uint256 _ticketsHardcap, uint256 _ticketPrice, address _treasury) {
        require(
            address(_thorus) != address(0) && address(_reward) != address(0),
            "zero address in constructor"
        );
        thorus = _thorus;
        reward = _reward;
        thorusHardcap = _thorusHardcap;
        rewardOffered = _rewardOffered;
        ticketsHardcap = _ticketsHardcap;
        ticketPrice = _ticketPrice;
        treasury = _treasury;
    }
    function allowBuying() external onlyOwner {
        require(!buyingAllowed, "buying already allowed");
        require(!ticketsWithdrawn, "tickets already withdrawn");
        buyingAllowed = true;
        emit BuyingStarted();
    }
    function disallowBuying() external onlyOwner {
        require(buyingAllowed, "buying already disallowed");
        buyingAllowed = false;
        emit BuyingStopped();
    }
    function allowClaiming() external onlyOwner {
        require(!claimingAllowed, "claiming already allowed");
        require(ticketsWithdrawn, "tickets not yet withdrawn");
        claimingAllowed = true;
        emit ClaimingStarted();
    }
    function ownerWinningTicketsCount(address owner) public view returns (uint256) {
        uint256 count = 0;
        for(uint256 i=0; i<tickets.length; i++) {
            if(tickets[i].isWinning && tickets[i].owner == owner)
                count++;
            if(count == ownerTicketsCount[owner])
                break;
        }
        return count;
    }
    function ownerClaimableTicketsCount(address owner) public view returns (uint256) {
        uint256 count = 0;
        for(uint256 i=0; i<tickets.length; i++) {
            if(tickets[i].isWinning && tickets[i].owner == owner && !tickets[i].isClaimed)
                count++;
            if(count == ownerTicketsCount[owner])
                break;
        }
        return count;
    }
    function ticketsCount() external view returns (uint256) {
        return tickets.length;
    }
    function buyTickets(uint256 amount) external nonReentrant {
        require(buyingAllowed, "buying not allowed");
        thorus.safeTransferFrom(msg.sender, address(this), amount * ticketPrice);
        for(uint256 i=0; i<amount; i++) {
            tickets.push(
                Ticket({
                    owner: msg.sender,
                    isWinning: false,
                    isClaimed: false
                })
            );
            ownerTicketsCount[msg.sender]++;
        }
        emit Buy(amount, msg.sender);
    }
    function claimTickets() external nonReentrant {
        require(claimingAllowed, "claiming not allowed");
        uint256 claimableTickets = ownerClaimableTicketsCount(msg.sender);
        reward.safeTransfer(msg.sender, claimableTickets * (rewardOffered / ticketsHardcap));
        uint256 claimedTickets = 0;
        for(uint256 i=0; i<tickets.length; i++) {
            if(tickets[i].isWinning && tickets[i].owner == msg.sender) {
                tickets[i].isClaimed = true;
                claimedTickets++;
            }
            if(claimedTickets == claimableTickets)
                break;
        }
        emit Claim(claimedTickets, msg.sender);
    }
    function withdrawWinningTickets() external onlyOwner {
        require(!buyingAllowed, "buying still allowed");
        require(!ticketsWithdrawn, "tickets already withdrawn");
        require(tickets.length > 0, "no tickets sold yet");
        if(tickets.length <= ticketsHardcap) {
            for(uint256 i=0; i<tickets.length; i++) {
                tickets[i].isWinning = true;
            }
            ticketsWithdrawn = true;
            emit TicketsWithdrawn();
            return;
        }
        uint256 randomizer = 0;
        uint256 randomIndex;
        for(uint256 i=0; i<ticketsHardcap; i++) {
            do {
                randomizer++;
                randomIndex = uint256(keccak256(abi.encodePacked(
                    randomizer,
                    block.difficulty,
                    block.timestamp,
                    block.number,
                    tickets.length,
                    thorus.totalSupply()
                ))) % tickets.length;
            } while(tickets[randomIndex].isWinning);
            tickets[randomIndex].isWinning = true;
        }
        ticketsWithdrawn = true;
        emit TicketsWithdrawn();
    }
    function withdrawThorus() external onlyOwner {
        require(!buyingAllowed, "buying still allowed");
        thorus.safeTransfer(treasury, thorus.balanceOf(address(this)));
        emit ThorusWithdrawn(thorus.balanceOf(address(this)));
    }
    function withdrawExcessiveReward() external onlyOwner {
        require(!buyingAllowed, "buying still allowed");
        uint256 amount;
        if(tickets.length <= ticketsHardcap)
            amount = reward.balanceOf(address(this)) - (rewardOffered / ticketsHardcap * tickets.length);
        else
            amount = reward.balanceOf(address(this)) - rewardOffered;
        reward.safeTransfer(treasury, amount);
        emit ExcessiveRewardWithdrawn(amount);
    }
}