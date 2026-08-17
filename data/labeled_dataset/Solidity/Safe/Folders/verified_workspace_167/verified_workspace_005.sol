pragma solidity 0.5.4;
pragma experimental ABIEncoderV2;
import { OnlySolo } from "../external/helpers/OnlySolo.sol";
import { ICallee } from "../protocol/interfaces/ICallee.sol";
import { IAutoTrader } from "../protocol/interfaces/IAutoTrader.sol";
import { Account } from "../protocol/lib/Account.sol";
import { Math } from "../protocol/lib/Math.sol";
import { Require } from "../protocol/lib/Require.sol";
import { Time } from "../protocol/lib/Time.sol";
import { Types } from "../protocol/lib/Types.sol";
contract TestCallee is
    ICallee,
    OnlySolo
{
    bytes32 constant FILE = "TestCallee";
    event Called(
        address indexed sender,
        address indexed accountOwner,
        uint256 accountNumber,
        uint256 accountData,
        uint256 senderData
    );
    mapping (address => mapping (uint256 => uint256)) public accountData;
    mapping (address => uint256) public senderData;
    constructor(
        address SOLO_MARGIN
    )
        public
        OnlySolo(SOLO_MARGIN)
    {}
    function callFunction(
        address sender,
        Account.Info memory account,
        bytes memory data
    )
        public
        onlySolo(msg.sender)
    {
        (
            uint256 aData,
            uint256 sData
        ) = parseData(data);
        emit Called(
            sender,
            account.owner,
            account.number,
            aData,
            sData
        );
        accountData[account.owner][account.number] = aData;
        senderData[sender] = sData;
    }
    function parseData(
        bytes memory data
    )
        private
        pure
        returns (
            uint256,
            uint256
        )
    {
        Require.that(
            data.length == 64,
            FILE,
            "Call data invalid length"
        );
        uint256 aData;
        uint256 sData;
        assembly {
            aData := mload(add(data, 32))
            sData := mload(add(data, 64))
        }
        return (
            aData,
            sData
        );
    }
}