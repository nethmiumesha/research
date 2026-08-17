pragma solidity >=0.8.13;
interface IDelegateRegistry {
    enum DelegationType {
        NONE,
        ALL,
        CONTRACT,
        ERC721,
        ERC20,
        ERC1155
    }
    struct Delegation {
        DelegationType type_;
        address to;
        address from;
        bytes32 rights;
        address contract_;
        uint256 tokenId;
        uint256 amount;
    }
    event DelegateAll(address indexed from, address indexed to, bytes32 rights, bool enable);
    event DelegateContract(
        address indexed from, address indexed to, address indexed contract_, bytes32 rights, bool enable
    );
    event DelegateERC721(
        address indexed from,
        address indexed to,
        address indexed contract_,
        uint256 tokenId,
        bytes32 rights,
        bool enable
    );
    event DelegateERC20(
        address indexed from, address indexed to, address indexed contract_, bytes32 rights, uint256 amount
    );
    event DelegateERC1155(
        address indexed from,
        address indexed to,
        address indexed contract_,
        uint256 tokenId,
        bytes32 rights,
        uint256 amount
    );
    error MulticallFailed();
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);
    function delegateAll(address to, bytes32 rights, bool enable) external payable returns (bytes32 delegationHash);
    function delegateContract(address to, address contract_, bytes32 rights, bool enable)
        external
        payable
        returns (bytes32 delegationHash);
    function delegateERC721(address to, address contract_, uint256 tokenId, bytes32 rights, bool enable)
        external
        payable
        returns (bytes32 delegationHash);
    function delegateERC20(address to, address contract_, bytes32 rights, uint256 amount)
        external
        payable
        returns (bytes32 delegationHash);
    function delegateERC1155(address to, address contract_, uint256 tokenId, bytes32 rights, uint256 amount)
        external
        payable
        returns (bytes32 delegationHash);
    function checkDelegateForAll(address to, address from, bytes32 rights) external view returns (bool);
    function checkDelegateForContract(address to, address from, address contract_, bytes32 rights)
        external
        view
        returns (bool);
    function checkDelegateForERC721(address to, address from, address contract_, uint256 tokenId, bytes32 rights)
        external
        view
        returns (bool);
    function checkDelegateForERC20(address to, address from, address contract_, bytes32 rights)
        external
        view
        returns (uint256);
    function checkDelegateForERC1155(address to, address from, address contract_, uint256 tokenId, bytes32 rights)
        external
        view
        returns (uint256);
    function getIncomingDelegations(address to) external view returns (Delegation[] memory delegations);
    function getOutgoingDelegations(address from) external view returns (Delegation[] memory delegations);
    function getIncomingDelegationHashes(address to) external view returns (bytes32[] memory delegationHashes);
    function getOutgoingDelegationHashes(address from) external view returns (bytes32[] memory delegationHashes);
    function getDelegationsFromHashes(bytes32[] calldata delegationHashes)
        external
        view
        returns (Delegation[] memory delegations);
    function readSlot(bytes32 location) external view returns (bytes32);
    function readSlots(bytes32[] calldata locations) external view returns (bytes32[] memory);
}