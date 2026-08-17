pragma solidity ^0.8.24;
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./PaymentEscrow.sol";
contract PaymentFactory is AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    event EscrowCreated(address indexed escrow, uint256 orderId);
    constructor(address initialAdmin) {
        _grantRole(DEFAULT_ADMIN_ROLE, initialAdmin);
        _grantRole(ADMIN_ROLE, initialAdmin);
    }
    function version() public pure returns (string memory) {
        return "1.0.3";
    }
    function createEscrow(
        uint256 timeoutSeconds,
        address token,
        uint256 expectedAmount,
        bytes32 salt
    ) external returns (address) {
        PaymentEscrow escrow = new PaymentEscrow{salt: salt}(
            address(this),
            timeoutSeconds,
            token,
            expectedAmount
        );
        emit EscrowCreated(address(escrow), uint256(uint160(address(escrow))));
        return address(escrow);
    }
}