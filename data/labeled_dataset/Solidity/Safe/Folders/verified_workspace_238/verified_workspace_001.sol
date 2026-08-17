pragma solidity ^0.4.24;
import './Arbitrator.sol';
contract Arbitrable {
    Arbitrator public arbitrator;
    bytes public arbitratorExtraData;
    modifier onlyArbitrator {
        require(msg.sender == address(arbitrator));
         _;
    }
    event Dispute(Arbitrator indexed _arbitrator, uint indexed _disputeID, string _rulingOptions);
    event Ruling(Arbitrator indexed _arbitrator, uint indexed _disputeID, uint _ruling);
    event Evidence(Arbitrator indexed _arbitrator, uint indexed _disputeID, address _party, string _evidence);
    event ContractHash(bytes32 _contractHash);
    constructor(Arbitrator _arbitrator, bytes _arbitratorExtraData, bytes32 _contractHash) public {
        arbitrator = _arbitrator;
      	arbitratorExtraData = _arbitratorExtraData;
        emit ContractHash(_contractHash);
    }
    function rule(uint _disputeID, uint _ruling) onlyArbitrator public {
        emit Ruling(Arbitrator(msg.sender), _disputeID, _ruling);
        executeRuling(_disputeID, _ruling);
    }
    function executeRuling(uint _disputeID, uint _ruling) internal;
}