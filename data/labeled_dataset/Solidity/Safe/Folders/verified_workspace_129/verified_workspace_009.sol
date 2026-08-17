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
contract ThorusLottery is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    address public immutable treasury;
    IERC20 public immutable thorus;
    IERC20 public immutable dai;
    uint256 public immutable ticketPrice;
    uint256 public rewardOffered;
    bool public buyingAllowed = false;
    bool public claimingAllowed = false;
    bool public ticketsWithdrawn = false;
    uint256 public immutable winningCount;
    uint256 public firstWinningNumber;
    uint256 public lastWinningNumber;
    uint256 public settlementBlockNumber;
    uint256 public immutable firstWinningPermille;
    uint256 public immutable secondWinningPermille;
    uint256 public immutable thirdWinningPermille;
    uint256 public immutable lastWinningPermille;
    event BuyingStarted();
    event BuyingStopped();
    event SettleRandomResult();
    event TicketsWithdrawn();
    event RewardSet();
    event ClaimingStarted();
    event Buy(uint256 amount, address indexed user);
    event Claim(uint256 amount, address indexed user);
    struct Ticket {
        address owner;
        bool isClaimed;
    }
    Ticket[] public tickets;
    uint256[] public ticketNumbers;
    mapping(address => uint256[]) public ownedTickets;
    constructor(
        address _treasury,
        IERC20 _thorus,
        IERC20 _dai,
        uint256 _ticketPrice,
        uint256 _winningCount,
        uint256 _firstWinningPermille,
        uint256 _secondWinningPermille,
        uint256 _thirdWinningPermille,
        uint256 _lastWinningPermille
        ) {
        require(
            address(_thorus) != address(0) && _treasury != address(0) && address(_dai) != address(0),
            "zero address in constructor"
        );
        require(_winningCount >= 3, "at least 3 winners");
        require(
            _firstWinningPermille + _secondWinningPermille + _thirdWinningPermille + _lastWinningPermille * (_winningCount - 3) == 1000,
            "wrong permilles"
        );
        treasury = _treasury;
        thorus = _thorus;
        dai = _dai;
        ticketPrice = _ticketPrice;
        winningCount = _winningCount;
        firstWinningPermille = _firstWinningPermille;
        secondWinningPermille = _secondWinningPermille;
        thirdWinningPermille = _thirdWinningPermille;
        lastWinningPermille = _lastWinningPermille;
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
    function setRewardOffered(uint256 _rewardOffered) external onlyOwner {
        require(!buyingAllowed, "buying still allowed");
        require(!claimingAllowed, "claiming already allowed");
        require(dai.balanceOf(address(this)) >= _rewardOffered, "transfer needed funds first!");
        require(_rewardOffered > rewardOffered, "new reward lower");
        rewardOffered = _rewardOffered;
        emit RewardSet();
    }
    function allowClaiming() external onlyOwner {
        require(!claimingAllowed, "claiming already allowed");
        require(ticketsWithdrawn, "tickets not yet withdrawn");
        require(rewardOffered > 0, "reward not yet set");
        uint256 excessAmount = dai.balanceOf(address(this)) - rewardOffered;
        if(excessAmount > 0)
            dai.safeTransfer(treasury, excessAmount);
        claimingAllowed = true;
        emit ClaimingStarted();
    }
    function ticketsCount() external view returns (uint256) {
        return tickets.length;
    }
    function buyTickets(uint256 amount) external nonReentrant {
        require(buyingAllowed, "buying not allowed");
        require(amount <= 100, "exceed maximum limit");
        thorus.safeTransferFrom(msg.sender, treasury, amount * ticketPrice);
        for(uint256 i=0; i<amount; i++) {
            tickets.push(
                Ticket({
                    owner: msg.sender,
                    isClaimed: false
                })
            );
            ownedTickets[msg.sender].push(tickets.length - 1);
            if (ticketNumbers.length == 0) {
                ticketNumbers.push(0);
            } else {
                uint256 randomIndex = uint256(keccak256(abi.encodePacked(
                    block.difficulty,
                    block.timestamp,
                    block.number,
                    tickets.length,
                    thorus.totalSupply()
                ))) % ticketNumbers.length;
                uint256 tempNumber = ticketNumbers[randomIndex];
                ticketNumbers[randomIndex] = tickets.length - 1;
                ticketNumbers.push(tempNumber);
            }
        }
        emit Buy(amount, msg.sender);
    }
    function settleRandomResult() external onlyOwner {
        require(!buyingAllowed, "buying still allowed");
        require(!ticketsWithdrawn, "tickets already withdrawn");
        require(tickets.length > 0, "no tickets sold yet");
        require(settlementBlockNumber == 0 || block.number - settlementBlockNumber >= 256, "settlementBlockNumber block is already set");
        settlementBlockNumber = block.number + 10;
        emit SettleRandomResult();
    }
    function withdrawWinningTickets() external onlyOwner {
        require(block.number > settlementBlockNumber , "settlementBlockNumber block is not arrived yet");
        require(block.number - settlementBlockNumber < 256, "settlementBlockNumber block is expired");
        firstWinningNumber =  uint256(blockhash(settlementBlockNumber)) % tickets.length;
        lastWinningNumber = firstWinningNumber + winningCount;
        ticketsWithdrawn = true;
        emit TicketsWithdrawn();
    }
    function isWinning(uint256 ticketIndex) public view returns (bool) {
        if(firstWinningNumber <= ticketNumbers[ticketIndex] && ticketNumbers[ticketIndex] < lastWinningNumber)
            return true;
        if(lastWinningNumber > tickets.length && ticketNumbers[ticketIndex] < (lastWinningNumber % tickets.length))
            return true;
        return false;
    }
    function isFirstWinning(uint256 ticketIndex) public view returns (bool) {
        if(firstWinningNumber == ticketNumbers[ticketIndex])
            return true;
        return false;
    }
    function isSecondWinning(uint256 ticketIndex) public view returns (bool) {
        if(firstWinningNumber + 1 == ticketNumbers[ticketIndex])
            return true;
        if(firstWinningNumber + 1 == tickets.length && ticketNumbers[ticketIndex] == 0)
            return true;
        return false;
    }
    function isThirdWinning(uint256 ticketIndex) public view returns (bool) {
        if(firstWinningNumber + 2 == ticketNumbers[ticketIndex])
            return true;
        if(firstWinningNumber + 1 == tickets.length && ticketNumbers[ticketIndex] == 1)
            return true;
        if(firstWinningNumber + 2 == tickets.length && ticketNumbers[ticketIndex] == 0)
            return true;
        return false;
    }
    function ownerWinningTicketsCount(address owner) public view returns (uint256) {
        uint256 count = 0;
        for(uint256 i=0; i<ownedTickets[owner].length; i++) {
            uint256 ticketIndex = ownedTickets[owner][i];
            if(isWinning(ticketIndex)) count++;
        }
        return count;
    }
    function ownerTicketsCount(address owner) public view returns (uint256) {
        return ownedTickets[owner].length;
    }
    function ownerClaimableTicketsCount(address owner) public view returns (uint256) {
        uint256 count = 0;
        for(uint256 i=0; i<ownedTickets[owner].length; i++) {
            uint256 ticketIndex = ownedTickets[owner][i];
            if(isWinning(ticketIndex) && !tickets[ticketIndex].isClaimed) count++;
        }
        return count;
    }
    function getFirstWinning() public view returns (address) {
        if(!ticketsWithdrawn)
            return address(0);
        for(uint256 i=0; i<tickets.length; i++) {
            if(isFirstWinning(i))
                return tickets[i].owner;
        }
        return address(0);
    }
    function getSecondWinning() public view returns (address) {
        if(!ticketsWithdrawn)
            return address(0);
        for(uint256 i=0; i<tickets.length; i++) {
            if(isSecondWinning(i))
                return tickets[i].owner;
        }
        return address(0);
    }
    function getThirdWinning() public view returns (address) {
        if(!ticketsWithdrawn)
            return address(0);
        for(uint256 i=0; i<tickets.length; i++) {
            if(isThirdWinning(i))
                return tickets[i].owner;
        }
        return address(0);
    }
    function getWinning() public view returns (address[] memory) {
        address[] memory result = new address[](winningCount-3);
        if(!ticketsWithdrawn)
            return result;
        uint256 j = 0;
        for(uint256 i=0; i<tickets.length; i++) {
            if(isWinning(i) && !isFirstWinning(i) && !isSecondWinning(i) && !isThirdWinning(i)) {
                result[j] = tickets[i].owner;
                j++;
            }
        }
        return result;
    }
    function claimTickets(uint256[] calldata ticketIndexes) external nonReentrant {
        require(claimingAllowed, "claiming not allowed");
        uint256 reward = 0;
        for(uint256 i=0; i<ticketIndexes.length; i++) {
            uint256 ticketIndex = ticketIndexes[i];
            require(tickets[ticketIndex].owner == msg.sender, "user not owner of the ticket");
            if(isFirstWinning(ticketIndex) && !tickets[ticketIndex].isClaimed) {
                tickets[ticketIndex].isClaimed = true;
                reward += rewardOffered * firstWinningPermille / 1000;
            } else if(isSecondWinning(ticketIndex) && !tickets[ticketIndex].isClaimed) {
                tickets[ticketIndex].isClaimed = true;
                reward += rewardOffered * secondWinningPermille / 1000;
            } else if(isThirdWinning(ticketIndex) && !tickets[ticketIndex].isClaimed) {
                tickets[ticketIndex].isClaimed = true;
                reward += rewardOffered * thirdWinningPermille / 1000;
            } else if(isWinning(ticketIndex) && !tickets[ticketIndex].isClaimed) {
                tickets[ticketIndex].isClaimed = true;
                reward += rewardOffered * lastWinningPermille / 1000;
            }
        }
        dai.safeTransfer(msg.sender, reward);
        emit Claim(reward, msg.sender);
    }
    function claimTickets() external nonReentrant {
        require(claimingAllowed, "claiming not allowed");
        uint256 reward = 0;
        for(uint256 i=0; i<ownedTickets[msg.sender].length; i++) {
            uint256 ticketIndex = ownedTickets[msg.sender][i];
            if(isFirstWinning(ticketIndex) && !tickets[ticketIndex].isClaimed) {
                tickets[ticketIndex].isClaimed = true;
                reward += rewardOffered * firstWinningPermille / 1000;
            } else if(isSecondWinning(ticketIndex) && !tickets[ticketIndex].isClaimed) {
                tickets[ticketIndex].isClaimed = true;
                reward += rewardOffered * secondWinningPermille / 1000;
            } else if(isThirdWinning(ticketIndex) && !tickets[ticketIndex].isClaimed) {
                tickets[ticketIndex].isClaimed = true;
                reward += rewardOffered * thirdWinningPermille / 1000;
            } else if(isWinning(ticketIndex) && !tickets[ticketIndex].isClaimed) {
                tickets[ticketIndex].isClaimed = true;
                reward += rewardOffered * lastWinningPermille / 1000;
            }
        }
        dai.safeTransfer(msg.sender, reward);
        emit Claim(reward, msg.sender);
    }
}