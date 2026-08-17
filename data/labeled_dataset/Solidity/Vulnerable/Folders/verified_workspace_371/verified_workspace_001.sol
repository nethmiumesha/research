pragma solidity ^0.8.20;
interface ICrossChain_Bridge {
    function burnToken(uint256 amount) external payable;
    function freezeVault(uint256 amount) external;
}