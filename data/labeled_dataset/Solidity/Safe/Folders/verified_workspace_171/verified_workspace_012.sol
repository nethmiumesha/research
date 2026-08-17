pragma solidity 0.8.6;
import "../Interfaces/IOptionsManager.sol";
interface IHegicStakeAndCover {
    event Provided(address indexed by, uint256 hAmount, uint256 tokenAmount);
    event Withdrawn(
        address indexed by,
        address indexed hegicDestination,
        uint256 hAmount,
        uint256 tokenAmount
    );
    function availableBalance() external view returns (uint256);
    function payOut(uint256 amount) external;
}