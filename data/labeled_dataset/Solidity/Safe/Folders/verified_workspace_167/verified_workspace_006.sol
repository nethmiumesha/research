pragma solidity 0.5.4;
pragma experimental ABIEncoderV2;
import { SafeMath } from "openzeppelin-solidity/contracts/math/SafeMath.sol";
import { IInterestSetter } from "../protocol/interfaces/IInterestSetter.sol";
import { Interest } from "../protocol/lib/Interest.sol";
contract TestInterestSetter is
    IInterestSetter
{
    mapping (address => Interest.Rate) public g_interestRates;
    function setInterestRate(
        address token,
        Interest.Rate memory rate
    )
        public
    {
        g_interestRates[token] = rate;
    }
    function getInterestRate(
        address token,
        uint256 ,
        uint256
    )
        public
        view
        returns (Interest.Rate memory)
    {
        return g_interestRates[token];
    }
}