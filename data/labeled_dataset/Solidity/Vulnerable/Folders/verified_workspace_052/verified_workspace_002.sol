pragma solidity ^0.8.0;
import "ds-test/test.sol";
import "../ERC721VaultFactory.sol";
import "./TestERC721.sol";
interface Hevm {
    function warp(uint256) external;
    function roll(uint256) external;
    function store(
        address,
        bytes32,
        bytes32
    ) external;
}
contract User {
    ERC721VaultFactory public factory;
    constructor(address _factory) {
        factory = ERC721VaultFactory(_factory);
    }
    receive() external payable {}
}
contract VaultFactoryTest is DSTest {
    Hevm public hevm;
    ERC721VaultFactory public factory;
    TestERC721 public token;
    User public user1;
    User public user2;
    User public user3;
    function setUp() public {
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    }
}