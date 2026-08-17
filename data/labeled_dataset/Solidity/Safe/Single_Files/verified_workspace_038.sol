contract Forked {
    function forked() returns (bool);
}
contract ShapeShiftSplit {
    address forkedContract;
    function ShapeShiftSplit(address _forkedContract) {
        forkedContract = _forkedContract;
    }
    function split(address _to, uint _value) returns (bool) {
        if (Forked(forkedContract).forked()) return false;
        if (!Forked(forkedContract).forked() && _to.send(_value)) return true;
        throw;
    }
}