pragma solidity 0.7.5;
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../../../upgradeability/EternalStorage.sol";
import "../../Ownable.sol";
contract TokensBridgeLimits is EternalStorage, Ownable {
    using SafeMath for uint256;
    event DailyLimitChanged(address indexed token, uint256 newLimit);
    event ExecutionDailyLimitChanged(address indexed token, uint256 newLimit);
    function isTokenRegistered(address _token) public view returns (bool) {
        return minPerTx(_token) > 0;
    }
    function totalSpentPerDay(address _token, uint256 _day) public view returns (uint256) {
        return uintStorage[keccak256(abi.encodePacked("totalSpentPerDay", _token, _day))];
    }
    function totalExecutedPerDay(address _token, uint256 _day) public view returns (uint256) {
        return uintStorage[keccak256(abi.encodePacked("totalExecutedPerDay", _token, _day))];
    }
    function dailyLimit(address _token) public view returns (uint256) {
        return uintStorage[keccak256(abi.encodePacked("dailyLimit", _token))];
    }
    function executionDailyLimit(address _token) public view returns (uint256) {
        return uintStorage[keccak256(abi.encodePacked("executionDailyLimit", _token))];
    }
    function maxPerTx(address _token) public view returns (uint256) {
        return uintStorage[keccak256(abi.encodePacked("maxPerTx", _token))];
    }
    function executionMaxPerTx(address _token) public view returns (uint256) {
        return uintStorage[keccak256(abi.encodePacked("executionMaxPerTx", _token))];
    }
    function minPerTx(address _token) public view returns (uint256) {
        return uintStorage[keccak256(abi.encodePacked("minPerTx", _token))];
    }
    function withinLimit(address _token, uint256 _amount) public view returns (bool) {
        uint256 nextLimit = totalSpentPerDay(_token, getCurrentDay()).add(_amount);
        return
            dailyLimit(address(0)) > 0 &&
            dailyLimit(_token) >= nextLimit &&
            _amount <= maxPerTx(_token) &&
            _amount >= minPerTx(_token);
    }
    function withinExecutionLimit(address _token, uint256 _amount) public view returns (bool) {
        uint256 nextLimit = totalExecutedPerDay(_token, getCurrentDay()).add(_amount);
        return
            executionDailyLimit(address(0)) > 0 &&
            executionDailyLimit(_token) >= nextLimit &&
            _amount <= executionMaxPerTx(_token);
    }
    function getCurrentDay() public view returns (uint256) {
        return block.timestamp / 1 days;
    }
    function setDailyLimit(address _token, uint256 _dailyLimit) external onlyOwner {
        require(isTokenRegistered(_token));
        require(_dailyLimit > maxPerTx(_token) || _dailyLimit == 0);
        uintStorage[keccak256(abi.encodePacked("dailyLimit", _token))] = _dailyLimit;
        emit DailyLimitChanged(_token, _dailyLimit);
    }
    function setExecutionDailyLimit(address _token, uint256 _dailyLimit) external onlyOwner {
        require(isTokenRegistered(_token));
        require(_dailyLimit > executionMaxPerTx(_token) || _dailyLimit == 0);
        uintStorage[keccak256(abi.encodePacked("executionDailyLimit", _token))] = _dailyLimit;
        emit ExecutionDailyLimitChanged(_token, _dailyLimit);
    }
    function setExecutionMaxPerTx(address _token, uint256 _maxPerTx) external onlyOwner {
        require(isTokenRegistered(_token));
        require(_maxPerTx == 0 || (_maxPerTx > 0 && _maxPerTx < executionDailyLimit(_token)));
        uintStorage[keccak256(abi.encodePacked("executionMaxPerTx", _token))] = _maxPerTx;
    }
    function setMaxPerTx(address _token, uint256 _maxPerTx) external onlyOwner {
        require(isTokenRegistered(_token));
        require(_maxPerTx == 0 || (_maxPerTx > minPerTx(_token) && _maxPerTx < dailyLimit(_token)));
        uintStorage[keccak256(abi.encodePacked("maxPerTx", _token))] = _maxPerTx;
    }
    function setMinPerTx(address _token, uint256 _minPerTx) external onlyOwner {
        require(isTokenRegistered(_token));
        require(_minPerTx > 0 && _minPerTx < dailyLimit(_token) && _minPerTx < maxPerTx(_token));
        uintStorage[keccak256(abi.encodePacked("minPerTx", _token))] = _minPerTx;
    }
    function maxAvailablePerTx(address _token) public view returns (uint256) {
        uint256 _maxPerTx = maxPerTx(_token);
        uint256 _dailyLimit = dailyLimit(_token);
        uint256 _spent = totalSpentPerDay(_token, getCurrentDay());
        uint256 _remainingOutOfDaily = _dailyLimit > _spent ? _dailyLimit - _spent : 0;
        return _maxPerTx < _remainingOutOfDaily ? _maxPerTx : _remainingOutOfDaily;
    }
    function addTotalSpentPerDay(
        address _token,
        uint256 _day,
        uint256 _value
    ) internal {
        uintStorage[keccak256(abi.encodePacked("totalSpentPerDay", _token, _day))] = totalSpentPerDay(_token, _day).add(
            _value
        );
    }
    function addTotalExecutedPerDay(
        address _token,
        uint256 _day,
        uint256 _value
    ) internal {
        uintStorage[keccak256(abi.encodePacked("totalExecutedPerDay", _token, _day))] = totalExecutedPerDay(
            _token,
            _day
        )
            .add(_value);
    }
    function _setLimits(address _token, uint256[3] memory _limits) internal {
        require(
            _limits[2] > 0 &&
                _limits[1] > _limits[2] &&
                _limits[0] > _limits[1]
        );
        uintStorage[keccak256(abi.encodePacked("dailyLimit", _token))] = _limits[0];
        uintStorage[keccak256(abi.encodePacked("maxPerTx", _token))] = _limits[1];
        uintStorage[keccak256(abi.encodePacked("minPerTx", _token))] = _limits[2];
        emit DailyLimitChanged(_token, _limits[0]);
    }
    function _setExecutionLimits(address _token, uint256[2] memory _limits) internal {
        require(_limits[1] < _limits[0]);
        uintStorage[keccak256(abi.encodePacked("executionDailyLimit", _token))] = _limits[0];
        uintStorage[keccak256(abi.encodePacked("executionMaxPerTx", _token))] = _limits[1];
        emit ExecutionDailyLimitChanged(_token, _limits[0]);
    }
    function _initializeTokenBridgeLimits(address _token, uint256 _decimals) internal {
        uint256 factor;
        if (_decimals < 18) {
            factor = 10**(18 - _decimals);
            uint256 _minPerTx = minPerTx(address(0)).div(factor);
            uint256 _maxPerTx = maxPerTx(address(0)).div(factor);
            uint256 _dailyLimit = dailyLimit(address(0)).div(factor);
            uint256 _executionMaxPerTx = executionMaxPerTx(address(0)).div(factor);
            uint256 _executionDailyLimit = executionDailyLimit(address(0)).div(factor);
            if (_minPerTx == 0) {
                _minPerTx = 1;
                if (_maxPerTx <= _minPerTx) {
                    _maxPerTx = 100;
                    _executionMaxPerTx = 100;
                    if (_dailyLimit <= _maxPerTx || _executionDailyLimit <= _executionMaxPerTx) {
                        _dailyLimit = 10000;
                        _executionDailyLimit = 10000;
                    }
                }
            }
            _setLimits(_token, [_dailyLimit, _maxPerTx, _minPerTx]);
            _setExecutionLimits(_token, [_executionDailyLimit, _executionMaxPerTx]);
        } else {
            factor = 10**(_decimals - 18);
            _setLimits(
                _token,
                [dailyLimit(address(0)).mul(factor), maxPerTx(address(0)).mul(factor), minPerTx(address(0)).mul(factor)]
            );
            _setExecutionLimits(
                _token,
                [executionDailyLimit(address(0)).mul(factor), executionMaxPerTx(address(0)).mul(factor)]
            );
        }
    }
}