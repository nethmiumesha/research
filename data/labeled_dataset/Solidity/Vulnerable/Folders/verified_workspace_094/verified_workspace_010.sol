pragma solidity 0.8.3;
import {ERC20Mock} from "./ERC20Mock.sol";
contract RegistryMock {
    ERC20Mock public comp;
    constructor(address _comp) {
        comp = ERC20Mock(_comp);
    }
}