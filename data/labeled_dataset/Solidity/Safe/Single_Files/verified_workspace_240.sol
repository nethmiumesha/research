pragma solidity ^0.5.2;
contract AuctioneerManaged {
    address public auctioneer;
    function updateAuctioneer(address _auctioneer) public onlyAuctioneer {
        require(_auctioneer != address(0), "The auctioneer must be a valid address");
        auctioneer = _auctioneer;
    }
    modifier onlyAuctioneer() {
        require(msg.sender == auctioneer, "Only the auctioneer can nominate a new one");
        _;
    }
}
contract TokenWhitelist is AuctioneerManaged {
    mapping(address => bool) public approvedTokens;
    event Approval(address indexed token, bool approved);
    function getApprovedAddressesOfList(address[] calldata addressesToCheck) external view returns (bool[] memory) {
        uint length = addressesToCheck.length;
        bool[] memory isApproved = new bool[](length);
        for (uint i = 0; i < length; i++) {
            isApproved[i] = approvedTokens[addressesToCheck[i]];
        }
        return isApproved;
    }
    function updateApprovalOfToken(address[] memory token, bool approved) public onlyAuctioneer {
        for (uint i = 0; i < token.length; i++) {
            approvedTokens[token[i]] = approved;
            emit Approval(token[i], approved);
        }
    }
}
contract BasicTokenWhitelist is TokenWhitelist {
    constructor() public {
        auctioneer = msg.sender;
    }
}