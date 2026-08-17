pragma solidity ^0.4.17;
import "../Manager.sol";
import "./IVerifier.sol";
import "./IVerifiable.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "../../installed_contracts/oraclize/contracts/usingOraclize.sol";
contract OraclizeVerifier is Manager, usingOraclize, IVerifier {
    using SafeMath for uint256;
    string public verificationCodeHash;
    uint256 public gasPrice;
    uint256 public gasLimit;
    struct OraclizeQuery {
        uint256 jobId;
        uint256 claimId;
        uint256 segmentNumber;
        bytes32 commitHash;
    }
    mapping (bytes32 => OraclizeQuery) oraclizeQueries;
    modifier onlyJobsManager() {
        require(msg.sender == controller.getContract(keccak256("JobsManager")));
        _;
    }
    modifier onlyOraclize() {
        require(msg.sender == oraclize_cbAddress());
        _;
    }
    modifier sufficientPayment() {
        require(getPrice() <= msg.value);
        _;
    }
    event OraclizeCallback(uint256 indexed jobId, uint256 indexed claimId, uint256 indexed segmentNumber, bytes proof, bool result);
    function OraclizeVerifier(address _controller, string _verificationCodeHash, uint256 _gasPrice, uint256 _gasLimit) public Manager(_controller) {
        verificationCodeHash = _verificationCodeHash;
        gasPrice = _gasPrice;
        oraclize_setCustomGasPrice(_gasPrice);
        gasLimit = _gasLimit;
        oraclize_setProof(proofType_TLSNotary | proofStorage_IPFS);
    }
    function setVerificationCodeHash(string _verificationCodeHash) external onlyControllerOwner {
        verificationCodeHash = _verificationCodeHash;
    }
    function verify(
        uint256 _jobId,
        uint256 _claimId,
        uint256 _segmentNumber,
        string _transcodingOptions,
        string _dataStorageHash,
        bytes32[2] _dataHashes
    )
        external
        payable
        onlyJobsManager
        whenSystemNotPaused
        sufficientPayment
    {
        string memory codeHashQuery = strConcat("binary(", verificationCodeHash, ").unhexlify()");
        bytes32 queryId = oraclize_query("computation", [codeHashQuery, _dataStorageHash, _transcodingOptions], gasLimit);
        oraclizeQueries[queryId].jobId = _jobId;
        oraclizeQueries[queryId].claimId = _claimId;
        oraclizeQueries[queryId].segmentNumber = _segmentNumber;
        oraclizeQueries[queryId].commitHash = keccak256(_dataHashes[0], _dataHashes[1]);
    }
    function __callback(bytes32 _queryId, string _result, bytes _proof) public onlyOraclize whenSystemNotPaused {
        OraclizeQuery memory oc = oraclizeQueries[_queryId];
        if (oc.commitHash == strToBytes32(_result)) {
            IVerifiable(controller.getContract(keccak256("JobsManager"))).receiveVerification(oc.jobId, oc.claimId, oc.segmentNumber, true);
            OraclizeCallback(oc.jobId, oc.claimId, oc.segmentNumber, _proof, true);
        } else {
            IVerifiable(controller.getContract(keccak256("JobsManager"))).receiveVerification(oc.jobId, oc.claimId, oc.segmentNumber, false);
            OraclizeCallback(oc.jobId, oc.claimId, oc.segmentNumber, _proof, false);
        }
        delete oraclizeQueries[_queryId];
    }
    function getPrice() public view returns (uint256) {
        return oraclize_getPrice("computation").add(gasPrice.mul(gasLimit));
    }
    function strToBytes32(string _str) internal pure returns (bytes32) {
        bytes memory byteStr = bytes(_str);
        bytes32 result;
        assembly {
            result := mload(add(byteStr, 32))
        }
        return result;
    }
}