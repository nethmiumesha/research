pragma solidity 0.5.8;
import "./MockBurnFactory.sol";
import "../modules/ModuleFactory.sol";
import "../libraries/Util.sol";
contract MockWrongTypeFactory is MockBurnFactory {
    constructor(
        uint256 _setupCost,
        uint256 _usageCost,
        address _polymathRegistry,
        bool _isFeeInPoly
    )
        public
        MockBurnFactory(_setupCost, _usageCost, _polymathRegistry, _isFeeInPoly)
    {
    }
    function getTypes() external view returns(uint8[] memory) {
        uint8[] memory res = new uint8[](1);
        res[0] = 4;
        return res;
    }
}