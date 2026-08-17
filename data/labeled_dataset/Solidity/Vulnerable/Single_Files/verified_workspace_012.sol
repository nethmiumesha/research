pragma solidity ^0.8.24;
contract BreimRawTokenDistributor {
    IERC20 public constant RAW_TOKEN =
        IERC20(0x91C4F7b22E9F9454C985eCEdf125B09E335A87EE);
    address public constant CUSTODY_WALLET =
        0xC280Da2d8581D29270f64a85A6f9C3fa85cADB11;
    address public constant RECIPIENT_A =
        0x94A9fa01861ACf53076F7a9c3F9A97a52666A901;
    address public constant RECIPIENT_B =
        0x67fee360F6167DDbeD7DBD43a08069649a59168E;
    address public constant RECIPIENT_C =
        0xbf707C2b39B3078E9f1C9590a2e5ad848c7cD9e3;
    address public owner;
    bool    public distributed = false;
    event Distributed(
        uint256 totalRead,
        uint256 amtA,
        uint256 amtB,
        uint256 amtC,
        uint256 remainder
    );
    event OwnershipTransferred(address indexed previous, address indexed next);
    modifier onlyOwner() {
        require(msg.sender == owner, "BreimRaw: caller is not owner");
        _;
    }
    constructor() {
        owner = msg.sender;
    }
    function distribute() external onlyOwner {
        require(!distributed, "BreimRaw: already distributed");
        uint256 total = RAW_TOKEN.balanceOf(CUSTODY_WALLET);
        require(total > 0, "BreimRaw: custody wallet has no RAWToken balance");
        uint256 amtA      = (total * 35) / 100;
        uint256 amtB      = (total * 10) / 100;
        uint256 amtC      = (total *  5) / 100;
        uint256 remainder = total - amtA - amtB - amtC;
        require(
            RAW_TOKEN.transferFrom(CUSTODY_WALLET, RECIPIENT_A, amtA),
            "BreimRaw: transfer to A (35%) failed"
        );
        require(
            RAW_TOKEN.transferFrom(CUSTODY_WALLET, RECIPIENT_B, amtB),
            "BreimRaw: transfer to B (10%) failed"
        );
        require(
            RAW_TOKEN.transferFrom(CUSTODY_WALLET, RECIPIENT_C, amtC),
            "BreimRaw: transfer to C (5%) failed"
        );
        distributed = true;
        emit Distributed(total, amtA, amtB, amtC, remainder);
    }
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "BreimRaw: zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    function resetDistributed() external onlyOwner {
        distributed = false;
    }
}