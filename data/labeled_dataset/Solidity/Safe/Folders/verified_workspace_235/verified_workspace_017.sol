contract MockTellor {
    bool didRetrieve = true;
    uint private price;
    uint private updateTime;
    function setPrice(uint _price) external returns (bool) {
        price = _price;
    }
      function setDidRetrieve(bool _didRetrieve) external returns (bool) {
        didRetrieve = _didRetrieve;
    }
    function setUpdateTime(uint _updateTime) external returns (bool) {
        updateTime = _updateTime;
    }
    function getTimestampbyRequestIDandIndex(uint _requestId, uint _count) external view returns (uint) {
        return updateTime;
    }
    function getNewValueCountbyRequestId(uint reqId) external view returns (uint) {
        return 1;
    }
    function retrieveData(uint256 _requestId, uint256 _timestamp) external view returns (uint256) {
        return price;
    }
}