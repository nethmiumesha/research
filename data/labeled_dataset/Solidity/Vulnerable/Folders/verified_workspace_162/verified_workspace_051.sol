pragma solidity ^0.8.24;
import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "src/shared/common/EssentialContract.sol";
import "src/shared/libs/LibStrings.sol";
import "src/shared/libs/LibMath.sol";
import "../provers/ProverSet.sol";
contract TokenUnlock is EssentialContract {
    using SafeERC20 for IERC20;
    using LibMath for uint256;
    uint256 public constant ONE_YEAR = 365 days;
    uint256 public constant THREE_YEARS = 3 * ONE_YEAR;
    uint64 public constant FIXED_TGE_TIMESTAMP = 1_772_323_200;
    address public constant TAIKO_TOKEN = 0x10dea67478c5F8C5E2D90e5E9B26dBe60c54d800;
    uint256 public amountVested;
    address public recipient;
    uint64 private tgeTimestamp_deprecated;
    mapping(address proverSet => bool valid) public isProverSet;
    uint256[47] private __gap;
    event TokenVested(uint256 amount);
    event TokenWithdrawn(address indexed to, uint256 amount);
    event RecipientChanged(address indexed oldRecipient, address indexed newRecipient);
    event ProverSetCreated(address indexed proverSet);
    event DepositToProverSet(address indexed proverSet, uint256 amount);
    error INVALID_PARAM();
    error NOT_WITHDRAWABLE();
    error NOT_PROVER_SET();
    error PERMISSION_DENIED();
    error TAIKO_TOKEN_NOT_USED_AS_BOND_TOKEN();
    modifier onlyRecipient() {
        if (msg.sender != recipient) revert PERMISSION_DENIED();
        _;
    }
    modifier onlyRecipientOrOwner() {
        if (msg.sender != recipient && msg.sender != owner()) revert PERMISSION_DENIED();
        _;
    }
    constructor(address _resolver) EssentialContract(_resolver) { }
    function vest(uint128 _amount) external nonReentrant {
        if (_amount == 0) revert INVALID_PARAM();
        amountVested += _amount;
        emit TokenVested(_amount);
        IERC20(TAIKO_TOKEN).safeTransferFrom(
            msg.sender, address(this), _amount
        );
    }
    function createProverSet() external onlyRecipient returns (address proverSet_) {
        require(
            resolve(LibStrings.B_BOND_TOKEN, false) == TAIKO_TOKEN,
            TAIKO_TOKEN_NOT_USED_AS_BOND_TOKEN()
        );
        bytes memory data = abi.encodeCall(ProverSetBase.init, (owner(), address(this)));
        proverSet_ = address(new ERC1967Proxy(resolve(LibStrings.B_PROVER_SET, false), data));
        isProverSet[proverSet_] = true;
        emit ProverSetCreated(proverSet_);
    }
    function depositToProverSet(
        address _proverSet,
        uint256 _amount
    )
        external
        nonZeroValue(_amount)
        onlyRecipient
    {
        if (!isProverSet[_proverSet]) revert NOT_PROVER_SET();
        emit DepositToProverSet(_proverSet, _amount);
        IERC20(TAIKO_TOKEN).safeTransfer(_proverSet, _amount);
    }
    function withdraw(
        address _to,
        uint256 _amount
    )
        external
        nonZeroAddr(_to)
        nonZeroValue(_amount)
        onlyRecipient
        nonReentrant
    {
        if (_amount > amountWithdrawable()) revert NOT_WITHDRAWABLE();
        emit TokenWithdrawn(_to, _amount);
        IERC20(TAIKO_TOKEN).safeTransfer(_to, _amount);
    }
    function withdraw() external nonReentrant {
        uint256 amount = amountWithdrawable();
        emit TokenWithdrawn(recipient, amount);
        IERC20(TAIKO_TOKEN).safeTransfer(recipient, amount);
    }
    function changeRecipient(address _newRecipient) external onlyRecipientOrOwner {
        if (_newRecipient == address(0) || _newRecipient == recipient) {
            revert INVALID_PARAM();
        }
        emit RecipientChanged(recipient, _newRecipient);
        recipient = _newRecipient;
    }
    function delegate(address _delegatee) external onlyRecipient nonReentrant {
        ERC20VotesUpgradeable(TAIKO_TOKEN).delegate(_delegatee);
    }
    function amountWithdrawable() public view returns (uint256) {
        IERC20 tko = IERC20(TAIKO_TOKEN);
        uint256 balance = tko.balanceOf(address(this));
        uint256 locked = _getAmountLocked();
        return balance.max(locked) - locked;
    }
    function _getAmountLocked() private view returns (uint256) {
        uint256 _amountVested = amountVested;
        if (_amountVested == 0) return 0;
        if (block.timestamp < FIXED_TGE_TIMESTAMP) return _amountVested;
        if (block.timestamp >= FIXED_TGE_TIMESTAMP + THREE_YEARS) return 0;
        return _amountVested * (FIXED_TGE_TIMESTAMP + THREE_YEARS - block.timestamp) / THREE_YEARS;
    }
}