pragma solidity ^0.4.24;
import './RobotLiabilityAPI.sol';
import './LightContract.sol';
contract RobotLiability is RobotLiabilityAPI, LightContract {
    constructor(address _lib) public LightContract(_lib)
    { factory = LiabilityFactory(msg.sender); }
}