pragma solidity ^0.8.0;
interface IStrataCDO {
    function strategy() external view returns (address);
    function isJrt(address tranche) external view returns (bool);
}