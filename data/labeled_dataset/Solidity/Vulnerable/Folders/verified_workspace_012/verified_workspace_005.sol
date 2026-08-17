pragma solidity ^0.8.0;
contract MockERC721Receiver {
    uint256 public mode = 0;
    function setMode(uint256 _mode) public {
        mode = _mode;
    }
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public view returns (bytes4) {
        require(mode != 1, "0x1111111");
        if (mode == 2) return this.setMode.selector;
        return this.onERC721Received.selector;
    }
}