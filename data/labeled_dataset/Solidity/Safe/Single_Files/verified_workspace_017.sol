contract Token {
    function transfer(address to, uint256 value) returns (bool ok);
    function balanceOf(address who) constant returns (uint256 value);
}
contract Forwarder {
    address owner;
    address defaultSweep;
    function Forwarder() {
        owner = 0xab8c0420ad39a5727fd43c917679e8822bff1c51;
        defaultSweep = 0xaec2e87e0a235266d9c5adc9deb4b2e29b54d009;
    }
    function() {
        sweep(defaultSweep);
    }
    function sweep(address _token) {
        address token = _token;
        if (!(msg.sender == owner && Token(token).transfer(owner, Token(token).balanceOf(this)))) throw;
    }
}