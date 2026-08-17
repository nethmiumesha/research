pragma solidity ^0.8.17;
import {HTMLRequest, HTMLTagType, HTMLTag} from "./ScriptyStructs.sol";
import {DynamicBuffer} from "./../utils/DynamicBuffer.sol";
import {IScriptyContractStorage} from "./../interfaces/IScriptyContractStorage.sol";
contract ScriptyCore {
    using DynamicBuffer for bytes;
    bytes public constant DATA_HTML_BASE64_URI_RAW = "data:text/html;base64,";
    bytes public constant DATA_HTML_URL_SAFE = "data%3Atext%2Fhtml%2C";
    bytes public constant HTML_OPEN_RAW = "<html>";
    bytes public constant HTML_OPEN_URL_SAFE = "%3Chtml%3E";
    bytes public constant HEAD_OPEN_RAW = "<head>";
    bytes public constant HEAD_OPEN_URL_SAFE = "%3Chead%3E";
    bytes public constant HEAD_CLOSE_RAW = "</head>";
    bytes public constant HEAD_CLOSE_URL_SAFE = "%3C%2Fhead%3E";
    bytes public constant BODY_OPEN_RAW = "<body>";
    bytes public constant BODY_OPEN_URL_SAFE = "%3Cbody%3E";
    bytes public constant HTML_BODY_CLOSED_RAW = "</body></html>";
    bytes public constant HTML_BODY_CLOSED_URL_SAFE =
        "%3C%2Fbody%3E%3C%2Fhtml%3E";
    uint256 public constant URLS_RAW_BYTES = 39;
    uint256 public constant URLS_SAFE_BYTES = 90;
    uint256 public constant HTML_RAW_BYTES = 13;
    uint256 public constant HEAD_RAW_BYTES = 13;
    uint256 public constant BODY_RAW_BYTES = 13;
    uint256 public constant RAW_BYTES = 39;
    uint256 public constant HTML_URL_SAFE_BYTES = 23;
    uint256 public constant HEAD_URL_SAFE_BYTES = 23;
    uint256 public constant BODY_SAFE_BYTES = 23;
    uint256 public constant URL_SAFE_BYTES = 69;
    uint256 public constant HTML_BASE64_DATA_URI_BYTES = 22;
    function tagOpenCloseForHTMLTag(
        HTMLTag memory htmlTag
    ) public pure returns (bytes memory, bytes memory) {
        if (htmlTag.tagType == HTMLTagType.script) {
            return ("<script>", "</script>");
        } else if (htmlTag.tagType == HTMLTagType.scriptBase64DataURI) {
            return ('<script src="data:text/javascript;base64,', '"></script>');
        } else if (htmlTag.tagType == HTMLTagType.scriptGZIPBase64DataURI) {
            return (
                '<script type="text/javascript+gzip" src="data:text/javascript;base64,',
                '"></script>'
            );
        } else if (htmlTag.tagType == HTMLTagType.scriptPNGBase64DataURI) {
            return (
                '<script type="text/javascript+png" src="data:text/javascript;base64,',
                '"></script>'
            );
        }
        return (htmlTag.tagOpen, htmlTag.tagClose);
    }
    function tagOpenCloseForHTMLTagURLSafe(
        HTMLTag memory htmlTag
    ) public pure returns (bytes memory, bytes memory) {
        if (
            htmlTag.tagType == HTMLTagType.script ||
            htmlTag.tagType == HTMLTagType.scriptBase64DataURI
        ) {
            return (
                "%253Cscript%2520src%253D%2522data%253Atext%252Fjavascript%253Bbase64%252C",
                "%2522%253E%253C%252Fscript%253E"
            );
        } else if (htmlTag.tagType == HTMLTagType.scriptGZIPBase64DataURI) {
            return (
                "%253Cscript%2520type%253D%2522text%252Fjavascript%252Bgzip%2522%2520src%253D%2522data%253Atext%252Fjavascript%253Bbase64%252C",
                "%2522%253E%253C%252Fscript%253E"
            );
        } else if (htmlTag.tagType == HTMLTagType.scriptPNGBase64DataURI) {
            return (
                "%253Cscript%2520type%253D%2522text%252Fjavascript%252Bpng%2522%2520src%253D%2522data%253Atext%252Fjavascript%253Bbase64%252C",
                "%2522%253E%253C%252Fscript%253E"
            );
        }
        return (htmlTag.tagOpen, htmlTag.tagClose);
    }
    function fetchTagContent(
        HTMLTag memory htmlTag
    ) public view returns (bytes memory) {
        if (htmlTag.contractAddress != address(0)) {
            return
                IScriptyContractStorage(htmlTag.contractAddress).getContent(
                    htmlTag.name,
                    htmlTag.contractData
                );
        }
        return htmlTag.tagContent;
    }
    function sizeForBase64Encoding(
        uint256 value
    ) public pure returns (uint256) {
        unchecked {
            return 4 * ((value + 2) / 3);
        }
    }
    function _enrichHTMLTags(
        HTMLTag[] memory htmlTags,
        bool isURLSafe
    ) internal view returns (uint256) {
        if (htmlTags.length == 0) {
            return 0;
        }
        bytes memory tagOpen;
        bytes memory tagClose;
        bytes memory tagContent;
        uint256 totalSize;
        uint256 length = htmlTags.length;
        uint256 i;
        unchecked {
            do {
                tagContent = fetchTagContent(htmlTags[i]);
                htmlTags[i].tagContent = tagContent;
                if (isURLSafe && htmlTags[i].tagType == HTMLTagType.script) {
                    totalSize += sizeForBase64Encoding(tagContent.length);
                } else {
                    totalSize += tagContent.length;
                }
                if (isURLSafe) {
                    (tagOpen, tagClose) = tagOpenCloseForHTMLTagURLSafe(
                        htmlTags[i]
                    );
                } else {
                    (tagOpen, tagClose) = tagOpenCloseForHTMLTag(htmlTags[i]);
                }
                htmlTags[i].tagOpen = tagOpen;
                htmlTags[i].tagClose = tagClose;
                totalSize += tagOpen.length;
                totalSize += tagClose.length;
            } while (++i < length);
        }
        return totalSize;
    }
    function _appendHTMLTags(
        bytes memory htmlFile,
        HTMLTag[] memory htmlTags,
        bool base64EncodeTagContent
    ) internal pure {
        uint256 i;
        unchecked {
            do {
                _appendHTMLTag(htmlFile, htmlTags[i], base64EncodeTagContent);
            } while (++i < htmlTags.length);
        }
    }
    function _appendHTMLTag(
        bytes memory htmlFile,
        HTMLTag memory htmlTag,
        bool base64EncodeTagContent
    ) internal pure {
        htmlFile.appendSafe(htmlTag.tagOpen);
        if (base64EncodeTagContent) {
            htmlFile.appendSafeBase64(htmlTag.tagContent, false, false);
        } else {
            htmlFile.appendSafe(htmlTag.tagContent);
        }
        htmlFile.appendSafe(htmlTag.tagClose);
    }
}