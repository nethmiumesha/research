pragma solidity ^0.4.24;
import "./Arbitrator.sol";
contract CentralizedArbitrator is Arbitrator {
    address public owner = msg.sender;
    uint arbitrationPrice;
    uint constant NOT_PAYABLE_VALUE = (2**256-2) / 2;
    struct Dispute {
        Arbitrable arbitrated;
        uint choices;
        uint fee;
        uint ruling;
        DisputeStatus status;
    }
    modifier onlyOwner {require(msg.sender==owner); _;}
    Dispute[] public disputes;
    constructor(uint _arbitrationPrice) public {
        arbitrationPrice = _arbitrationPrice;
    }
    function setArbitrationPrice(uint _arbitrationPrice) public onlyOwner {
        arbitrationPrice = _arbitrationPrice;
    }
    function arbitrationCost(bytes _extraData) public constant returns(uint fee) {
        _extraData;
        return arbitrationPrice;
    }
    function appealCost(uint _disputeID, bytes _extraData) public constant returns(uint fee) {
        _disputeID;
        _extraData;
        return NOT_PAYABLE_VALUE;
    }
    function createDispute(uint _choices, bytes _extraData) public payable requireArbitrationFee(_extraData) returns(uint disputeID)  {
        super.createDispute(_choices, _extraData);
        disputeID = disputes.push(Dispute({
            arbitrated: Arbitrable(msg.sender),
            choices: _choices,
            fee: msg.value,
            ruling: 0,
            status: DisputeStatus.Waiting
        })) - 1;
      	emit DisputeCreation(disputeID, Arbitrable(msg.sender));
    		return disputeID;
    }
    function giveRuling(uint _disputeID, uint _ruling) public onlyOwner {
        Dispute storage dispute = disputes[_disputeID];
        require(_ruling <= dispute.choices);
        uint fee = dispute.fee;
        Arbitrable arbitrated = dispute.arbitrated;
        dispute.arbitrated = Arbitrable(0x0);
        dispute.fee = 0;
        dispute.ruling = _ruling;
        dispute.status = DisputeStatus.Solved;
        msg.sender.transfer(fee);
        arbitrated.rule(_disputeID,_ruling);
    }
    function disputeStatus(uint _disputeID) public constant returns(DisputeStatus status) {
        return disputes[_disputeID].status;
    }
    function currentRuling(uint _disputeID) public constant returns(uint ruling) {
        return disputes[_disputeID].ruling;
    }
}