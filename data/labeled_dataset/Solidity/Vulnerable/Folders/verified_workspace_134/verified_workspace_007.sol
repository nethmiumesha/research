pragma solidity ^0.8.22;
import {HTMLRequest, HTMLTagType, HTMLTag} from "./../core/ScriptyCore.sol";
interface IScriptyHTML {
    function getHTML(
        HTMLRequest memory htmlRequest
    ) external view returns (bytes memory);
    function getEncodedHTML(
        HTMLRequest memory htmlRequest
    ) external view returns (bytes memory);
    function getHTMLString(
        HTMLRequest memory htmlRequest
    ) external view returns (string memory);
    function getEncodedHTMLString(
        HTMLRequest memory htmlRequest
    ) external view returns (string memory);
}