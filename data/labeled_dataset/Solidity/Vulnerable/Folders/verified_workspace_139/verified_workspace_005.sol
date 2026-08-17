pragma solidity ^0.8.24;
import { IEEPCondition } from "../interfaces/IEEPCondition.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
contract NFTGatedCondition is IEEPCondition {
    function conditionName() external pure override returns (string memory) {
        return "NFTGated";
    }
    function isSatisfied(
        uint256,
        address caller,
        bytes calldata data
    ) external view override returns (bool) {
        (
            address nftContract,
            uint256 tokenId,
            bool isERC1155,
            address requiredHolder
        ) = abi.decode(data, (address, uint256, bool, address));
        address checkAddress = requiredHolder != address(0) ? requiredHolder : caller;
        if (isERC1155) {
            return IERC1155(nftContract).balanceOf(checkAddress, tokenId) > 0;
        } else {
            try IERC721(nftContract).ownerOf(tokenId) returns (address owner) {
                return owner == checkAddress;
            } catch {
                return false;
            }
        }
    }
    function encode(
        address nftContract,
        uint256 tokenId,
        bool isERC1155,
        address requiredHolder
    ) external pure returns (bytes memory) {
        require(nftContract != address(0), "NFTGated: zero contract address");
        return abi.encode(nftContract, tokenId, isERC1155, requiredHolder);
    }
}