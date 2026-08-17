pragma solidity ^0.8.0;
import "ds-test/test.sol";
import "../Settings.sol";
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
contract SettingsTest is DSTest {
    Hevm public hevm;
    Settings public settings;
    TestERC721 public token;
    TestERC721 public token2;
    function setUp() public {
        hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        settings = new Settings();
        token = new TestERC721();
        token2 = new TestERC721();
    }
    function test_setMaxAuction() public {
        settings.setMaxAuctionLength(4 weeks);
        assertEq(settings.maxAuctionLength(), 4 weeks);
    }
    function testFail_setMaxAuction() public {
        settings.setMaxAuctionLength(10 weeks);
    }
    function testFail_setMaxAuction2() public {
        settings.setMaxAuctionLength(2.9 days);
    }
    function test_setMinAuction() public {
        settings.setMinAuctionLength(1 weeks);
    }
    function testFail_setMinAuction() public {
        settings.setMaxAuctionLength(0.1 days);
    }
    function testFail_setMinAuction2() public {
        settings.setMinAuctionLength(5 weeks);
    }
    function test_setGovernanceFee() public {
        settings.setGovernanceFee(90);
    }
    function testFail_setGovernanceFee() public {
        settings.setGovernanceFee(110);
    }
    function test_setMinBidIncrease() public {
        settings.setMinBidIncrease(75);
    }
    function testFail_setMinBidIncrease2() public {
        settings.setMinBidIncrease(110);
    }
    function testFail_setMinBidIncrease() public {
        settings.setMinBidIncrease(5);
    }
    function test_setMaxReserveFactor() public {
        settings.setMaxReserveFactor(10000);
    }
    function testFail_setMaxReserveFactor() public {
        settings.setMaxReserveFactor(200);
    }
    function test_setMinReserveFactor() public {
        settings.setMinReserveFactor(400);
    }
    function testFail_setMinReserveFactor() public {
        settings.setMinReserveFactor(6000);
    }
    function test_setFeeReceiver() public {
        settings.setFeeReceiver(payable(address(this)));
    }
    function test_addAllowedNFT() public {
        settings.addAllowedNFT(address(token));
        assertTrue(!settings.allowedNFTs(address(token2)));
        settings.addAllowedNFT(address(token2));
        assertTrue(settings.allowedNFTs(address(token)));
        assertTrue(settings.allowedNFTs(address(token2)));
    }
    function test_removeAllowedNFT() public {
        settings.addAllowedNFT(address(token));
        settings.removeAllowedNFT(address(token));
        assertTrue(!settings.allowedNFTs(address(token)));
    }
}