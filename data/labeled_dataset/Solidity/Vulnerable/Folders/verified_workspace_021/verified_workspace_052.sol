pragma solidity >=0.4.24;
import "./IERC20.sol";
interface IWrapperFactory {
    function isWrapper(address possibleWrapper) external view returns (bool);
    function createWrapper(
        IERC20 token,
        bytes32 currencyKey,
        bytes32 synthContractName
    ) external returns (address);
    function distributeFees() external;
}