pragma solidity ^0.8.34;
import "@openzeppelin/contracts/access/Ownable.sol";
interface IRewardManager {
        function totalHoldings() external view returns (uint256);
    }
contract DSFRewardForwarder is Ownable {
    enum WithdrawalType {
        Base,
        OneCoin
    }
    address public immutable dsf;
    address public rewardManager;
    modifier onlyDSF() {
        require(msg.sender == dsf, "STUB: only DSF");
        _;
    }
    constructor(address _dsf, address _rewardManager)  Ownable(msg.sender) {
        require(_dsf != address(0), "STUB: dsf=0");
        require(_rewardManager != address(0), "STUB: rm=0");
        dsf = _dsf;
        rewardManager = _rewardManager;
    }
    function setRewardManager(address _rewardManager) external onlyOwner {
        require(_rewardManager != address(0), "STUB: rm=0");
        rewardManager = _rewardManager;
    }
    function autoCompound() public onlyDSF {
    }
    function claimManagementFees() public onlyDSF returns (uint256) {
        return 0;
    }
    function totalHoldings() public view returns (uint256) {
        try IRewardManager(rewardManager).totalHoldings() returns (uint256 v) {
            return v;
        } catch {
            return 0;
        }
    }
    function deposit(uint256[3] memory ) external pure returns (uint256) {
        revert("STUB: deposit disabled");
    }
    function withdraw(
        address ,
        uint256 ,
        uint256[3] memory ,
        WithdrawalType ,
        uint128
    ) external pure returns (bool) {
        revert("STUB: withdraw disabled");
    }
    function withdrawAll() external pure {
        revert("STUB: withdrawAll disabled");
    }
    function calcWithdrawOneCoin(uint256 , uint128 )
        external
        pure
        returns (uint256)
    {
        return 0;
    }
    function calcSharesAmount(uint256[3] memory , bool )
        external
        pure
        returns (uint256)
    {
        return 0;
    }
    receive() external payable {
        revert("STUB: no ETH");
    }
}