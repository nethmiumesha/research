pragma solidity ^0.8.20;
import {Proxy} from "../Proxy.sol";
import {ERC1967Utils} from "./ERC1967Utils.sol";
contract ERC1967Proxy is Proxy {
    constructor(address implementation, bytes memory _data) payable {
        ERC1967Utils.upgradeToAndCall(implementation, _data);
    }
    function _implementation() internal view virtual override returns (address) {
        return ERC1967Utils.getImplementation();
    }
}