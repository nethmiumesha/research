pragma solidity ^0.8.20;
import "./base64.sol";
import "./LibString.sol";
import "./IFileStore.sol";
import { IScriptyBuilderV2,
         HTMLRequest,
         HTMLTagType,
         HTMLTag        } from "scripty.sol/contracts/scripty/interfaces/IScriptyBuilderV2.sol";
contract Lift_Off_renderer {
    IFileStore public fileStore;
    address constant private ethfsFileStorage = 0x8FAA1AAb9DA8c75917C43Fb24fDdb513edDC3245;
    address constant private scriptyBuilder   = 0xD7587F110E08F4D120A231bA97d3B577A81Df022;
    address constant private scriptyStorage   = 0xbD11994aABB55Da86DC246EBB17C1Be0af5b7699;
    string public title                 = "Lift Off";
    string public artistName            = "Luke Weaver";
    string public scriptFileName        = "frameworks_v2monochrome.js";
    string public imageFileName         = "liftoff.gif";
    string public description           = "Sequence 002 - Launch";
    string public storageType           = "Fully On-Chain";
    string public medium                = "Frameworks";
    string public sequence              = "002";
    string public autoExecuteCommand    = "1fP(13)t2(kl,10)1(d(1RRR4RRR6RRRRR1,4),21)1zZA2R1dt(l,8)d(il,5)dt(i,8)dt(ij,5)dt(j,8)dt(kj,5)dt(k,8)zZd 5Aesk5(dtkkkkkkkkjp(-1),11)siiA2R1t(i,48)(l,10)2tjjjjjjjjjjj1fxv(K,16)(J,1)yym";
    constructor() {
        fileStore = IFileStore(0xFe1411d6864592549AdE050215482e4385dFa0FB);
    }
    function generateTraits() public view returns (string memory) {
        string memory traits = string(abi.encodePacked(
            '{"trait_type": "Artist", "value": "',
            artistName,
            '"}, ',
            '{"trait_type": "Storage", "value": "',
            storageType,
            '"}, ',
            '{"trait_type": "Sequence", "value": "',
            sequence,
            '"}, ',
            '{"trait_type": "Medium", "value": "',
            medium,
            '"}'
        ));
        return traits;
    }
    function uri(uint _tokenId) public view returns (string memory) {
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name":"', title,
                        '","image": "data:image/png;base64,', getImage(),
                        '","animation_url": "', generateHtm(),
                        '","description":"', description,
                        '","attributes": [', generateTraits(), ']}'
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }
    function getScript() public view returns (string memory) {
        return fileStore.getFile(scriptFileName).read();
    }
    function getImage() public view returns (string memory) {
        return fileStore.getFile(imageFileName).read();
    }
    function generateHtm () internal view returns (string memory) {
        HTMLTag[] memory headTags = new HTMLTag[](2);
        headTags[0].tagOpen = "<title>";
        headTags[0].tagContent = bytes(title);
        headTags[0].tagClose = "</title>";
        headTags[1].name = "fullSizeCanvas.css";
        headTags[1].tagOpen = '<link rel="stylesheet" href="data:text/css;base64,';
        headTags[1].tagClose = '">';
        headTags[1].contractAddress = ethfsFileStorage;
        HTMLTag[] memory bodyTags = new HTMLTag[](4);
        bodyTags[0].name = "p5-v1.5.0.min.js.gz";
        bodyTags[0].tagType = HTMLTagType.scriptGZIPBase64DataURI;
        bodyTags[0].contractAddress = ethfsFileStorage;
        bodyTags[1].name = "gunzipScripts-0.0.1.js";
        bodyTags[1].tagType = HTMLTagType.scriptBase64DataURI;
        bodyTags[1].contractAddress = ethfsFileStorage;
        bytes memory prefix = "let autoExecuteCommand = '";
        bytes memory suffix = "';";
        bodyTags[2].tagContent = abi.encodePacked(prefix, bytes(autoExecuteCommand), suffix);
        bodyTags[2].tagType = HTMLTagType.script;
        bodyTags[3].name = scriptFileName;
        bodyTags[3].tagType = HTMLTagType.scriptBase64DataURI;
        bodyTags[3].contractAddress = ethfsFileStorage;
        HTMLRequest memory htmlRequest;
        htmlRequest.headTags = headTags;
        htmlRequest.bodyTags = bodyTags;
        return string(IScriptyBuilderV2(scriptyBuilder).getEncodedHTML(htmlRequest));
    }
}