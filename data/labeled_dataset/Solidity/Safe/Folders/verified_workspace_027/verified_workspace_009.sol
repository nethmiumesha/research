pragma solidity 0.5.8;
import "../modules/Experimental/Burn/TrackedRedemption.sol";
contract MockRedemptionManager is TrackedRedemption {
    mapping(address => uint256) tokenToRedeem;
    mapping(address => mapping(bytes32 => uint256)) redeemedTokensByPartition;
    event RedeemedTokenByOwner(address _investor, address _byWhoom, uint256 _value);
    event RedeemedTokensByPartition(address indexed _investor, address indexed _operator, bytes32 _partition, uint256 _value, bytes _data, bytes _operatorData);
    constructor(address _securityToken, address _polyToken) public TrackedRedemption(_securityToken, _polyToken) {
    }
    function transferToRedeem(uint256 _value) public {
        require(securityToken.transferFrom(msg.sender, address(this), _value), "Insufficient funds");
        tokenToRedeem[msg.sender] = _value;
    }
    function redeemTokenByOwner(uint256 _value) public {
        require(tokenToRedeem[msg.sender] >= _value, "Insufficient tokens redeemable");
        tokenToRedeem[msg.sender] = tokenToRedeem[msg.sender].sub(_value);
        redeemedTokens[msg.sender] = redeemedTokens[msg.sender].add(_value);
        securityToken.redeem(_value, "");
        emit RedeemedTokenByOwner(msg.sender, address(this), _value);
    }
    function redeemTokensByPartition(uint256 _value, bytes32 _partition, bytes calldata _data) external {
        require(tokenToRedeem[msg.sender] >= _value, "Insufficient tokens redeemable");
        tokenToRedeem[msg.sender] = tokenToRedeem[msg.sender].sub(_value);
        redeemedTokensByPartition[msg.sender][_partition] = redeemedTokensByPartition[msg.sender][_partition].add(_value);
        securityToken.redeemByPartition(_partition, _value, _data);
        emit RedeemedTokensByPartition(msg.sender, address(0), _partition, _value, _data, "");
    }
    function operatorRedeemTokensByPartition(uint256 _value, bytes32 _partition, bytes calldata _data, bytes calldata _operatorData) external {
        require(tokenToRedeem[msg.sender] >= _value, "Insufficient tokens redeemable");
        tokenToRedeem[msg.sender] = tokenToRedeem[msg.sender].sub(_value);
        redeemedTokensByPartition[msg.sender][_partition] = redeemedTokensByPartition[msg.sender][_partition].add(_value);
        securityToken.operatorRedeemByPartition(_partition, msg.sender, _value, _data, _operatorData);
        emit RedeemedTokensByPartition(msg.sender, address(this), _partition, _value, _data, _operatorData);
    }
    function operatorTransferToRedeem(uint256 _value, bytes32 _partition, bytes calldata _data, bytes calldata _operatorData) external {
        securityToken.operatorTransferByPartition(_partition, msg.sender, address(this), _value, _data, _operatorData);
        tokenToRedeem[msg.sender] = _value;
    }
}