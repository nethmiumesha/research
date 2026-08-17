pragma solidity 0.8.33;
interface IOperatorFilterRegistry {
    function isOperatorAllowed(address registrant, address operator) external view returns (bool);
    function registerAndSubscribe(address registrant, address subscription) external;
}
contract Primenumbers {
    error NotOwner();
    error NoScripts();
    error SoldOut();
    error FreeMintSoldOut();
    error AlreadyFreeMinted();
    error InsufficientPayment();
    error ZeroQuantity();
    error NonexistentToken();
    error NotApproved();
    error InvalidTransfer();
    error OperatorNotAllowed(address operator);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    uint256 public constant MAX_SUPPLY = 690;
    uint256 public constant COST = 0.0003 ether;
    string public constant NAME = "Primenumbers";
    string public constant SYMBOL = "Primenumbers";
    IOperatorFilterRegistry public constant OPERATOR_FILTER_REGISTRY =
        IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);
    address public constant OPENSEA_SUBSCRIPTION =
        0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6;
    address private _owner;
    uint96 private _currentIndex;
    bool public operatorFilteringEnabled = true;
    string private _baseURI = "bafybeihouhtghicg5su4er2ejft4bebxkuc4ymyofibvckvvrhuwfjn6se";
    uint128 public MAX_FREE = 690;
    uint128 public MAX_FREE_PER_WALLET = 1;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(address => uint256) public minted;
    modifier onlyOwner() {
        if (msg.sender != _owner) revert NotOwner();
        _;
    }
    modifier noContracts() {
        if (tx.origin != msg.sender) revert NoScripts();
        _;
    }
    modifier onlyAllowedOperator(address from) {
        if (operatorFilteringEnabled) {
            if (msg.sender != from) {
                _checkFilterOperator(msg.sender);
            }
        }
        _;
    }
    modifier onlyAllowedOperatorApproval(address operator) {
        if (operatorFilteringEnabled) {
            _checkFilterOperator(operator);
        }
        _;
    }
    constructor() {
        _owner = msg.sender;
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            try OPERATOR_FILTER_REGISTRY.registerAndSubscribe(
                address(this),
                OPENSEA_SUBSCRIPTION
            ) {} catch {}
        }
    }
    function _checkFilterOperator(address operator) internal view {
        if (!OPERATOR_FILTER_REGISTRY.isOperatorAllowed(address(this), operator)) {
            revert OperatorNotAllowed(operator);
        }
    }
    function setOperatorFilteringEnabled(bool enabled) external onlyOwner {
        operatorFilteringEnabled = enabled;
    }
    function freemint() external noContracts {
        uint256 amount = MAX_FREE_PER_WALLET;
        uint256 current = _currentIndex;
        if (current + amount > MAX_FREE) revert FreeMintSoldOut();
        if (current + amount > MAX_SUPPLY) revert SoldOut();
        if (minted[msg.sender] != 0) revert AlreadyFreeMinted();
        minted[msg.sender] = amount;
        _mint(msg.sender, amount);
    }
    function mint(uint256 amount) external payable {
        if (_currentIndex + amount > MAX_SUPPLY) revert SoldOut();
        if (msg.value < amount * COST) revert InsufficientPayment();
        _mint(msg.sender, amount);
    }
    function teamMint(uint256 amount) external onlyOwner {
        if (_currentIndex + amount > MAX_SUPPLY) revert SoldOut();
        _mint(msg.sender, amount);
    }
    function _mint(address to, uint256 quantity) internal {
        if (quantity == 0) revert ZeroQuantity();
        uint256 startId = _currentIndex;
        _owners[startId] = to;
        _balances[to] += quantity;
        for (uint256 i; i < quantity;) {
            emit Transfer(address(0), to, startId + i);
            unchecked { ++i; }
        }
        _currentIndex = uint96(startId + quantity);
    }
    function totalSupply() public view returns (uint256) {
        return _currentIndex;
    }
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    function ownerOf(uint256 tokenId) public view returns (address) {
        if (tokenId >= _currentIndex) revert NonexistentToken();
        for (uint256 i = tokenId; ; ) {
            address tokenOwner = _owners[i];
            if (tokenOwner != address(0)) {
                return tokenOwner;
            }
            unchecked { --i; }
        }
    }
    function owner() public view returns (address) {
        return _owner;
    }
    function name() public pure returns (string memory) {
        return NAME;
    }
    function symbol() public pure returns (string memory) {
        return SYMBOL;
    }
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        if (tokenId >= _currentIndex) revert NonexistentToken();
        return string(abi.encodePacked("ipfs:
    }
    function approve(address to, uint256 tokenId)
        public
        onlyAllowedOperatorApproval(to)
    {
        address tokenOwner = ownerOf(tokenId);
        if (msg.sender != tokenOwner && !_operatorApprovals[tokenOwner][msg.sender])
            revert NotApproved();
        _tokenApprovals[tokenId] = to;
        emit Approval(tokenOwner, to, tokenId);
    }
    function setApprovalForAll(address operator, bool approved)
        public
        onlyAllowedOperatorApproval(operator)
    {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }
    function getApproved(uint256 tokenId) public view returns (address) {
        if (tokenId >= _currentIndex) revert NonexistentToken();
        return _tokenApprovals[tokenId];
    }
    function isApprovedForAll(address account, address operator) public view returns (bool) {
        return _operatorApprovals[account][operator];
    }
    function transferFrom(address from, address to, uint256 tokenId)
        public
        onlyAllowedOperator(from)
    {
        _transfer(from, to, tokenId);
    }
    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        onlyAllowedOperator(from)
    {
        _transfer(from, to, tokenId);
    }
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata)
        public
        onlyAllowedOperator(from)
    {
        _transfer(from, to, tokenId);
    }
    function _transfer(address from, address to, uint256 tokenId) internal {
        if (ownerOf(tokenId) != from) revert InvalidTransfer();
        if (msg.sender != from && !_operatorApprovals[from][msg.sender] && _tokenApprovals[tokenId] != msg.sender)
            revert NotApproved();
        delete _tokenApprovals[tokenId];
        unchecked {
            --_balances[from];
            ++_balances[to];
        }
        _owners[tokenId] = to;
        uint256 nextId = tokenId + 1;
        if (nextId < _currentIndex && _owners[nextId] == address(0)) {
            _owners[nextId] = from;
        }
        emit Transfer(from, to, tokenId);
    }
    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return interfaceId == 0x01ffc9a7 ||
               interfaceId == 0x80ac58cd ||
               interfaceId == 0x5b5e139f ||
               interfaceId == 0x2a55205a;
    }
    function royaltyInfo(uint256, uint256 salePrice) external view returns (address, uint256) {
        return (_owner, (salePrice * 500) / 10000);
    }
    function setData(string calldata base, uint128 maxFree, uint128 maxFreePerWallet) external onlyOwner {
        _baseURI = base;
        MAX_FREE = maxFree;
        MAX_FREE_PER_WALLET = maxFreePerWallet;
    }
    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success);
    }
    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) { digits++; temp /= 10; }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            buffer[--digits] = bytes1(uint8(48 + value % 10));
            value /= 10;
        }
        return string(buffer);
    }
}