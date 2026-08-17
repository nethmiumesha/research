pragma solidity 0.6.10;
contract CallTester {
    event CallFunction(address sender, address vaultOwner, uint256 vaultId, bytes data);
    function callFunction(
        address _sender,
        address _vaultOwner,
        uint256 _vaultId,
        bytes memory _data
    ) external {
        emit CallFunction(_sender, _vaultOwner, _vaultId, _data);
    }
}