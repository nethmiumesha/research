pragma solidity 0.5.17;
import "@openzeppelin/contracts/ownership/Ownable.sol";
contract OwnerPausable is Ownable {
    event Paused();
    event Unpaused();
    bool private paused = false;
    function pause() external onlyOwner onlyUnpaused {
        paused = true;
        emit Paused();
    }
    function unpause() external onlyOwner onlyPaused {
        paused = false;
        emit Unpaused();
    }
    modifier onlyUnpaused() {
        require(!paused, "Method can only be called when unpaused");
        _;
    }
    modifier onlyPaused() {
        require(paused, "Method can only be called when paused");
        _;
    }
}