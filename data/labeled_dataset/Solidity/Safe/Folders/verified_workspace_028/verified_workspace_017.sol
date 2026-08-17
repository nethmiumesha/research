pragma solidity 0.6.11;
contract MockTellor {
    bool didRetrieve = true;
    uint private price;
    uint private updateTime;
    bool private revertRequest;
    function setPrice(uint _price) external {
        price = _price;
    }
      function setDidRetrieve(bool _didRetrieve) external {
        didRetrieve = _didRetrieve;
    }
    function setUpdateTime(uint _updateTime) external {
        updateTime = _updateTime;
    }
      function setRevertRequest() external {
        revertRequest = !revertRequest;
    }
    function getTimestampbyRequestIDandIndex(uint, uint) external view returns (uint) {
        return updateTime;
    }
    function getNewValueCountbyRequestId(uint) external view returns (uint) {
        if (revertRequest) {require (1 == 0, "Tellor request reverted");}
        return 1;
    }
    function retrieveData(uint256, uint256) external view returns (uint256) {
        return price;
    }
}