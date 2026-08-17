pragma solidity ^0.8.22;
import {HTMLRequest, HTMLTagType, HTMLTag} from "./../core/ScriptyCore.sol";
interface IScriptyHTMLURLSafe {
    function getHTMLURLSafe(
        HTMLRequest memory htmlRequest
    ) external view returns (bytes memory);
    function getHTMLURLSafeString(
        HTMLRequest memory htmlRequest
    ) external view returns (string memory);
}