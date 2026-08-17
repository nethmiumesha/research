contract ShapeShiftFallback {
    bool active;
    address checker;
    address target;
    function ShapeShiftFallback(address _checker, address _target) {
        active = true;
        checker = _checker;
        target = _target;
    }
    function() {
        if (active == false || msg.value == 0 || !target.send(msg.value)) throw;
    }
}