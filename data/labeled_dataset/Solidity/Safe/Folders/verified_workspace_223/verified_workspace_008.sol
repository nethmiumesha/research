pragma solidity 0.8.7;
interface IPoolToken {
    function mint(uint256 amount, address account) external returns (bool);
    function burn(uint256 amount, address account) external returns (bool);
}