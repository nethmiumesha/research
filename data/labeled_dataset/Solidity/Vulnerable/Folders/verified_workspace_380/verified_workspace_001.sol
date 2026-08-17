pragma solidity ^0.8.20;
interface ICrossChain_Bridge {
    function mintMultisig(uint256 amount) external payable;
    function freezeTimelock(uint256 amount) external;
}