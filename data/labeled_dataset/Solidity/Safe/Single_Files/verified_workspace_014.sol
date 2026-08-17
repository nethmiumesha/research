pragma solidity 0.8.33;
contract EasterEggs {
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
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event TokenBurned(uint256 indexed tokenId, address indexed from);
    uint256 public constant MAX_SUPPLY = 923;
    uint256 public constant COST = 0.0009 ether;
    string public constant NAME = "EasterEggs";
    string public constant SYMBOL = "EasterEggs";
    uint256 public constant BURN_CHANCE = 20;
    uint256 public constant BURN_THRESHOLD = 300;
    address private _owner;
    uint96 private _currentIndex;
    uint96 private _burnedCount;
    string private _baseURI = "bafybeickwsqpuj3h2f6vlyqve27c2lv5jtp2iad6gljmkgqxrdomjvxz6q";
    uint128 public MAX_FREE = 923;
    uint128 public MAX_FREE_PER_WALLET = 2;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(address => uint256) public minted;
    mapping(uint256 => bool) private _burned;
    modifier onlyOwner() {
        if (msg.sender != _owner) revert NotOwner();
        _;
    }
    modifier noContracts() {
        if (tx.origin != msg.sender) revert NoScripts();
        _;
    }
    constructor() {
        _owner = msg.sender;
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
        return _currentIndex - _burnedCount;
    }
    function totalBurned() public view returns (uint256) {
        return _burnedCount;
    }
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    function ownerOf(uint256 tokenId) public view returns (address) {
        if (tokenId >= _currentIndex) revert NonexistentToken();
        if (_burned[tokenId]) revert NonexistentToken();
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
        if (_burned[tokenId]) revert NonexistentToken();
        return string(abi.encodePacked("ipfs:
    }
    function approve(address to, uint256 tokenId) public {
        address tokenOwner = ownerOf(tokenId);
        if (msg.sender != tokenOwner && !_operatorApprovals[tokenOwner][msg.sender])
            revert NotApproved();
        _tokenApprovals[tokenId] = to;
        emit Approval(tokenOwner, to, tokenId);
    }
    function setApprovalForAll(address operator, bool approved) public {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }
    function getApproved(uint256 tokenId) public view returns (address) {
        if (tokenId >= _currentIndex) revert NonexistentToken();
        if (_burned[tokenId]) revert NonexistentToken();
        return _tokenApprovals[tokenId];
    }
    function isApprovedForAll(address account, address operator) public view returns (bool) {
        return _operatorApprovals[account][operator];
    }
    function transferFrom(address from, address to, uint256 tokenId) public {
        _transfer(from, to, tokenId);
    }
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        _transfer(from, to, tokenId);
    }
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata) public {
        _transfer(from, to, tokenId);
    }
    function _transfer(address from, address to, uint256 tokenId) internal {
        if (ownerOf(tokenId) != from) revert InvalidTransfer();
        if (msg.sender != from && !_operatorApprovals[from][msg.sender] && _tokenApprovals[tokenId] != msg.sender)
            revert NotApproved();
        delete _tokenApprovals[tokenId];
        uint256 currentSupply = totalSupply();
        bool burningActive = currentSupply > BURN_THRESHOLD;
        if (burningActive) {
            uint256 randomNumber = uint256(keccak256(abi.encodePacked(
                block.timestamp,
                block.prevrandao,
                tokenId,
                from,
                to,
                tx.gasprice
            ))) % 100;
            if (randomNumber < BURN_CHANCE) {
                _burn(from, tokenId);
                return;
            }
        }
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
    function _burn(address from, uint256 tokenId) internal {
        unchecked {
            --_balances[from];
            ++_burnedCount;
        }
        _burned[tokenId] = true;
        delete _owners[tokenId];
        uint256 nextId = tokenId + 1;
        if (nextId < _currentIndex && _owners[nextId] == address(0)) {
            _owners[nextId] = from;
        }
        emit Transfer(from, address(0), tokenId);
        emit TokenBurned(tokenId, from);
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