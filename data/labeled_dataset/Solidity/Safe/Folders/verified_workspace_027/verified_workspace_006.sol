pragma solidity 0.5.8;
import "./OZStorage.sol";
import "./SecurityTokenStorage.sol";
import "../libraries/TokenLib.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "../modules/PermissionManager/IPermissionManager.sol";
contract STGetter is OZStorage, SecurityTokenStorage {
    using SafeMath for uint256;
    function isIssuable() external view returns (bool) {
        return issuance;
    }
    function getCheckpointTimes() external view returns(uint256[] memory) {
        return checkpointTimes;
    }
    function getInvestorCount() external view returns(uint256) {
        return dataStore.getAddressArrayLength(INVESTORSKEY);
    }
    function getInvestors() public view returns(address[] memory investors) {
        investors = dataStore.getAddressArray(INVESTORSKEY);
    }
    function getInvestorsAt(uint256 _checkpointId) external view returns(address[] memory) {
        uint256 count;
        uint256 i;
        address[] memory investors = dataStore.getAddressArray(INVESTORSKEY);
        for (i = 0; i < investors.length; i++) {
            if (balanceOfAt(investors[i], _checkpointId) > 0) {
                count++;
            } else {
                investors[i] = address(0);
            }
        }
        address[] memory holders = new address[](count);
        count = 0;
        for (i = 0; i < investors.length; i++) {
            if (investors[i] != address(0)) {
                holders[count] = investors[i];
                count++;
            }
        }
        return holders;
    }
    function getInvestorsSubsetAt(uint256 _checkpointId, uint256 _start, uint256 _end) external view returns(address[] memory) {
        uint256 count;
        uint256 i;
        address[] memory investors = dataStore.getAddressArrayElements(INVESTORSKEY, _start, _end);
        for (i = 0; i < investors.length; i++) {
            if (balanceOfAt(investors[i], _checkpointId) > 0) {
                count++;
            } else {
                investors[i] = address(0);
            }
        }
        address[] memory holders = new address[](count);
        count = 0;
        for (i = 0; i < investors.length; i++) {
            if (investors[i] != address(0)) {
                holders[count] = investors[i];
                count++;
            }
        }
        return holders;
    }
    function getModule(address _module) external view returns(bytes32, address, address, bool, uint8[] memory, bytes32) {
        return (
            modulesToData[_module].name,
            modulesToData[_module].module,
            modulesToData[_module].moduleFactory,
            modulesToData[_module].isArchived,
            modulesToData[_module].moduleTypes,
            modulesToData[_module].label
        );
    }
    function getModulesByName(bytes32 _name) external view returns(address[] memory) {
        return names[_name];
    }
    function getModulesByType(uint8 _type) external view returns(address[] memory) {
        return modules[_type];
    }
    function getTreasuryWallet() external view returns(address) {
        return dataStore.getAddress(TREASURY);
    }
    function balanceOfAt(address _investor, uint256 _checkpointId) public view returns(uint256) {
        require(_checkpointId <= currentCheckpointId);
        return TokenLib.getValueAt(checkpointBalances[_investor], _checkpointId, balanceOf(_investor));
    }
    function totalSupplyAt(uint256 _checkpointId) external view returns(uint256) {
        require(_checkpointId <= currentCheckpointId);
        return checkpointTotalSupply[_checkpointId];
    }
    function iterateInvestors(uint256 _start, uint256 _end) external view returns(address[] memory) {
        return dataStore.getAddressArrayElements(INVESTORSKEY, _start, _end);
    }
    function checkPermission(address _delegate, address _module, bytes32 _perm) public view returns(bool) {
        for (uint256 i = 0; i < modules[PERMISSION_KEY].length; i++) {
            if (!modulesToData[modules[PERMISSION_KEY][i]].isArchived) {
                if (IPermissionManager(modules[PERMISSION_KEY][i]).checkPermission(_delegate, _module, _perm)) {
                    return true;
                }
            }
        }
        return false;
    }
    function isOperator(address _operator, address _tokenHolder) external view returns (bool) {
        return (_allowance(_tokenHolder, _operator) == uint(-1));
    }
    function isOperatorForPartition(bytes32 _partition, address _operator, address _tokenHolder) external view returns (bool) {
        return partitionApprovals[_tokenHolder][_partition][_operator];
    }
    function partitionsOf(address ) external pure returns (bytes32[] memory) {
        bytes32[] memory result = new bytes32[](2);
        result[0] = UNLOCKED;
        result[1] = LOCKED;
        return result;
    }
    function getVersion() external view returns(uint8[] memory) {
        uint8[] memory version = new uint8[](3);
        version[0] = securityTokenVersion.major;
        version[1] = securityTokenVersion.minor;
        version[2] = securityTokenVersion.patch;
        return version;
    }
    function getDocument(bytes32 _name) external view returns (string memory, bytes32, uint256) {
        return (
            _documents[_name].uri,
            _documents[_name].docHash,
            _documents[_name].lastModified
        );
    }
    function getAllDocuments() external view returns (bytes32[] memory) {
        return _docNames;
    }
}