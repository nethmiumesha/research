pragma solidity ^0.8.0;
import "./ERC20WithFees.sol";
contract Koku is ERC20WithFees {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint32 public lastTimeAdminMintedAt;
    uint112 public adminMintableTokensPerSecond = 0.005 * 1e9;
    uint112 public adminMintableTokensHardCap = 10_000 * 1e9;
    uint32 public lastTimeGameMintedAt;
    uint112 public gameMintableTokensPerSecond = 0.1 * 1e9;
    uint112 public gameMintableTokensHardCap = 10_000 * 1e9;
    constructor() ERC20WithFees("Koku", "KOKU")  {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        lastTimeAdminMintedAt = uint32(block.timestamp);
        _mint(msg.sender, 100_000 * 1e9);
    }
    function decimals() public view virtual override returns (uint8) {
        return 9;
    }
    function setAdminMintableTokensPerSecond(uint112 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        adminMintableTokensPerSecond = amount;
        emit AdminMintableTokensPerSecondUpdated(amount);
    }
    function setAdminMintableTokensHardCap(uint112 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        adminMintableTokensHardCap = amount;
        emit AdminMintableTokensHardCapUpdated(amount);
    }
    function setGameMintableTokensPerSecond(uint112 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        gameMintableTokensPerSecond = amount;
        emit GameMintableTokensPerSecondUpdated(amount);
    }
    function setGameMintableTokensHardCap(uint112 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        gameMintableTokensHardCap = amount;
        emit GameMintableTokensHardCapUpdated(amount);
    }
    function specialMint(uint amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(amount > 0, "Invalid input amount.");
        uint mintableTokens = getMintableTokens(lastTimeAdminMintedAt, adminMintableTokensPerSecond, adminMintableTokensHardCap);
        require(mintableTokens >= amount, "amount exceeds the mintable tokens amount.");
        _mint(msg.sender, amount);
        lastTimeAdminMintedAt = getLastTimeMintedAt(mintableTokens, amount, adminMintableTokensPerSecond);
        emit AdminBalanceIncremented(amount);
    }
    function incrementBalances(address[] calldata accounts, uint[] calldata values, uint valuesSum) external onlyRole(MINTER_ROLE) {
        require(accounts.length == values.length, "Arrays must have the same length.");
        require(valuesSum > 0, "Invalid valuesSum amount.");
        uint mintableTokens = getMintableTokens(lastTimeGameMintedAt, gameMintableTokensPerSecond, gameMintableTokensHardCap);
        require(mintableTokens >= valuesSum, "valuesSum exceeds the mintable tokens amount.");
        uint sum = 0;
        for (uint i = 0; i < accounts.length; i++) {
            sum += values[i];
            require(mintableTokens >= sum, "sum exceeds the mintable tokens amount.");
            _mint(accounts[i], values[i]);
        }
        lastTimeGameMintedAt = getLastTimeMintedAt(mintableTokens, sum, gameMintableTokensPerSecond);
        emit UserBalancesIncremented(sum);
    }
    function getMintableTokens(uint32 lastTimeMintedAt, uint112 mintableTokensPerSecond, uint112 mintableTokensHardCap) internal view returns (uint) {
        return min((block.timestamp - lastTimeMintedAt) * mintableTokensPerSecond, mintableTokensHardCap);
    }
    function getLastTimeMintedAt(uint mintableTokens, uint mintedTokens, uint112 mintableTokensPerSecond) internal view returns (uint32) {
        return uint32(block.timestamp - (mintableTokens - mintedTokens) / mintableTokensPerSecond);
    }
    function min(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }
    event AdminMintableTokensPerSecondUpdated(uint amount);
    event AdminMintableTokensHardCapUpdated(uint amount);
    event GameMintableTokensPerSecondUpdated(uint amount);
    event GameMintableTokensHardCapUpdated(uint amount);
    event AdminBalanceIncremented(uint amount);
    event UserBalancesIncremented(uint amount);
}