pragma solidity ^0.8.20;
interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
}
contract MergeBuyWrapper {
    address public immutable seaport;
    address payable public immutable feeRecipient;
    uint256 public immutable feeBps;
    address public owner;
    constructor(address _seaport, address payable _feeRecipient, uint256 _feeBps) {
        seaport = _seaport;
        feeRecipient = _feeRecipient;
        feeBps = _feeBps;
        owner = msg.sender;
    }
    function buyWithFee(
        bytes calldata seaportCalldata,
        address nftContract,
        uint256 tokenId,
        uint256 listingValue
    ) external payable {
        uint256 minFee = listingValue * feeBps / 10000;
        require(msg.value >= listingValue + minFee, "Insufficient payment");
        uint256 fee = msg.value - listingValue;
        (bool success,) = seaport.call{value: listingValue}(seaportCalldata);
        require(success, "Seaport failed");
        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
        (bool feeSent,) = feeRecipient.call{value: fee}("");
        require(feeSent, "Fee failed");
    }
    function onERC721Received(address, address, uint256, bytes calldata)
        external pure returns (bytes4)
    {
        return this.onERC721Received.selector;
    }
    function rescueToken(address nftContract, address to, uint256 tokenId) external {
        require(msg.sender == owner, "Not owner");
        IERC721(nftContract).transferFrom(address(this), to, tokenId);
    }
    function withdraw() external {
        require(msg.sender == owner, "Not owner");
        (bool s,) = owner.call{value: address(this).balance}("");
        require(s);
    }
    receive() external payable {}
}