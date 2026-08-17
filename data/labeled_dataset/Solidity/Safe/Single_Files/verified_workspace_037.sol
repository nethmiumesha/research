contract Forked {
    function forked() returns (bool);
}
contract ShapeShiftReceiver {
    address forkedContract;
    address public target;
    bool public forked;
    function ShapeShiftReceiver(address _forkedContract, address _target, bool _forked) {
        forkedContract = _forkedContract;
        target = _target;
        forked = _forked;
    }
    function() {
        if (Forked(forkedContract).forked() != forked || msg.value == 0 || !target.send(msg.value)) throw;
    }
}