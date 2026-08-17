pragma solidity ^0.4.17;
import "../token/ILivepeerToken.sol";
import "../token/ITokenDistribution.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";
contract TokenDistributionMock is Ownable, ITokenDistribution {
    uint256 endTime;
    bool over;
    ILivepeerToken public token;
    address public faucet;
    function TokenDistributionMock(address _token, address _faucet, uint256 _endTime) public {
        token = ILivepeerToken(_token);
        faucet = _faucet;
        endTime = _endTime;
        over = false;
    }
    function finalize() external onlyOwner {
        require(!isOver());
        over = true;
        uint256 balance = token.balanceOf(this);
        token.transfer(faucet, balance);
    }
    function isOver() public view returns (bool) {
        return over;
    }
    function getEndTime() public view returns (uint256) {
        return endTime;
    }
}