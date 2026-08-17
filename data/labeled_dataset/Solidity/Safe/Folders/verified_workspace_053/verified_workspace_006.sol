pragma solidity 0.6.12;
interface IWhitelist {
    function isWhitelisted(address _address) external view returns (bool);
}