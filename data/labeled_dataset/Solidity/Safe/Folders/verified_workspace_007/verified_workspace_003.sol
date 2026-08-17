import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
pragma solidity 0.8.10;
interface Token {
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}
contract WorthTokenTimeLock is Ownable{
    using SafeMath for uint256;
    struct Items {
        address tokenAddress;
        address withdrawalAddress;
        uint256 tokenAmount;
        uint256 unlockTime;
        bool withdrawn;
    }
    uint256 public depositId;
    uint256[] public allDepositIds;
    mapping (address => uint256[]) public depositsByWithdrawalAddress;
    mapping (uint256 => Items) public lockedToken;
    mapping (address => mapping(address => uint256)) public walletTokenBalance;
    event LogWithdrawal(address sentToAddress, uint256 amountTransferred);
    function lockTokens(address _tokenAddress, address _withdrawalAddress, uint256 _amount, uint256 _unlockTime) external returns (uint256 _id) {
        require(_amount > 0, "Amount should be greater than 0");
        require(_unlockTime <= 3217825449, "Enter a valid unlock time");
        walletTokenBalance[_tokenAddress][_withdrawalAddress] = walletTokenBalance[_tokenAddress][_withdrawalAddress].add(_amount);
        _id = ++depositId;
        lockedToken[_id].tokenAddress = _tokenAddress;
        lockedToken[_id].withdrawalAddress = _withdrawalAddress;
        lockedToken[_id].tokenAmount = _amount;
        lockedToken[_id].unlockTime = _unlockTime;
        lockedToken[_id].withdrawn = false;
        allDepositIds.push(_id);
        depositsByWithdrawalAddress[_withdrawalAddress].push(_id);
        require(Token(_tokenAddress).transferFrom(msg.sender, address(this), _amount), "Transfer Failed");
    }
    function createMultipleLocks(address _tokenAddress, address _withdrawalAddress, uint256[] memory _amounts, uint256[] memory _unlockTimes) external returns (uint256 _id) {
        require(_amounts.length > 0, "Enter at least 1 value");
        require(_amounts.length == _unlockTimes.length, "Number of amounts and number of unlock times should be equal");
        uint256 i;
        for(i=0; i<_amounts.length; i++){
            require(_amounts[i] > 0, "Amount should be greater than 0");
            require(_unlockTimes[i] <= 3217825449, "Enter valid unlock time");
            walletTokenBalance[_tokenAddress][_withdrawalAddress] = walletTokenBalance[_tokenAddress][_withdrawalAddress].add(_amounts[i]);
            _id = ++depositId;
            lockedToken[_id].tokenAddress = _tokenAddress;
            lockedToken[_id].withdrawalAddress = _withdrawalAddress;
            lockedToken[_id].tokenAmount = _amounts[i];
            lockedToken[_id].unlockTime = _unlockTimes[i];
            lockedToken[_id].withdrawn = false;
            allDepositIds.push(_id);
            depositsByWithdrawalAddress[_withdrawalAddress].push(_id);
            require(Token(_tokenAddress).transferFrom(msg.sender, address(this), _amounts[i]), "Transfer Failed");
        }
    }
    function extendLockDuration(uint256 _id, uint256 _unlockTime) external {
        require(_unlockTime <= 3217825449, "Enter a valid unlock time");
        require(!lockedToken[_id].withdrawn, "Tokens already withdrawn");
        require(msg.sender == lockedToken[_id].withdrawalAddress,"Not the same withdrawal address");
        require(_unlockTime >= lockedToken[_id].unlockTime,"Cannot have time duration less than the previous one");
        lockedToken[_id].unlockTime = _unlockTime;
    }
    function withdrawTokens(uint256 _id) external {
        require(block.timestamp >= lockedToken[_id].unlockTime, "Unlock time not reached");
        require(msg.sender == lockedToken[_id].withdrawalAddress, "Not the same withdrawal address");
        require(!lockedToken[_id].withdrawn, "Tokens already withdrawn");
        lockedToken[_id].withdrawn = true;
        walletTokenBalance[lockedToken[_id].tokenAddress][msg.sender] = walletTokenBalance[lockedToken[_id].tokenAddress][msg.sender].sub(lockedToken[_id].tokenAmount);
        uint256 j;
        uint256 arrLength = depositsByWithdrawalAddress[lockedToken[_id].withdrawalAddress].length;
        for (j=0; j<arrLength; j++) {
            if (depositsByWithdrawalAddress[lockedToken[_id].withdrawalAddress][j] == _id) {
                depositsByWithdrawalAddress[lockedToken[_id].withdrawalAddress][j] = depositsByWithdrawalAddress[lockedToken[_id].withdrawalAddress][arrLength - 1];
                depositsByWithdrawalAddress[lockedToken[_id].withdrawalAddress].pop();
                break;
            }
        }
        require(Token(lockedToken[_id].tokenAddress).transfer(msg.sender, lockedToken[_id].tokenAmount), "Transfer Failed");
        emit LogWithdrawal(msg.sender, lockedToken[_id].tokenAmount);
    }
    function getTotalTokenBalance(address _tokenAddress) view public returns (uint256)
    {
       return Token(_tokenAddress).balanceOf(address(this));
    }
    function getTokenBalanceByAddress(address _tokenAddress, address _walletAddress) view public returns (uint256)
    {
       return walletTokenBalance[_tokenAddress][_walletAddress];
    }
    function getAllDepositIds() view public returns (uint256[] memory)
    {
        return allDepositIds;
    }
    function getDepositDetails(uint256 _id) view public returns (address _tokenAddress, address _withdrawalAddress, uint256 _tokenAmount, uint256 _unlockTime, bool _withdrawn)
    {
        return(lockedToken[_id].tokenAddress,lockedToken[_id].withdrawalAddress,lockedToken[_id].tokenAmount,
        lockedToken[_id].unlockTime,lockedToken[_id].withdrawn);
    }
    function getDepositsByWithdrawalAddress(address _withdrawalAddress) view public returns (uint256[] memory)
    {
        return depositsByWithdrawalAddress[_withdrawalAddress];
    }
}