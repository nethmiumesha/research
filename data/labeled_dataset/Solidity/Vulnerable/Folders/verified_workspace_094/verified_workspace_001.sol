pragma solidity 0.8.3;
import {
    ERC20Upgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {
    ReentrancyGuardUpgradeable
} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {SafeERC20} from "../libs/SafeERC20.sol";
import {
    IERC721ReceiverUpgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import {NFT} from "../tokens/NFT.sol";
import {DInterest} from "../DInterest.sol";
import {Vesting02} from "../rewards/Vesting02.sol";
import {Sponsorable} from "../libs/Sponsorable.sol";
contract ZeroCouponBond is
    ERC20Upgradeable,
    ReentrancyGuardUpgradeable,
    IERC721ReceiverUpgradeable,
    Sponsorable
{
    using SafeERC20 for ERC20;
    DInterest public pool;
    ERC20 public stablecoin;
    NFT public depositNFT;
    Vesting02 public vesting;
    uint64 public maturationTimestamp;
    uint64 public depositID;
    uint8 private _decimals;
    event WithdrawDeposit();
    event RedeemStablecoin(address indexed sender, uint256 amount);
    function initialize(
        address _creator,
        address _pool,
        address _vesting,
        uint64 _maturationTimestamp,
        uint256 _initialDepositAmount,
        string calldata _tokenName,
        string calldata _tokenSymbol
    ) external initializer {
        __ERC20_init(_tokenName, _tokenSymbol);
        __ReentrancyGuard_init();
        pool = DInterest(_pool);
        stablecoin = pool.stablecoin();
        depositNFT = pool.depositNFT();
        maturationTimestamp = _maturationTimestamp;
        vesting = Vesting02(_vesting);
        _decimals = pool.stablecoin().decimals();
        stablecoin.safeTransferFrom(
            _creator,
            address(this),
            _initialDepositAmount
        );
        stablecoin.safeApprove(address(pool), type(uint256).max);
        uint256 interestAmount;
        (depositID, interestAmount) = pool.deposit(
            _initialDepositAmount,
            maturationTimestamp
        );
        _mint(_creator, _initialDepositAmount + interestAmount);
        vesting.safeTransferFrom(
            address(this),
            _creator,
            vesting.depositIDToVestID(_pool, depositID)
        );
    }
    function decimals() public view override returns (uint8) {
        return _decimals;
    }
    function mint(uint256 depositAmount)
        external
        nonReentrant
        returns (uint256 mintedAmount)
    {
        return _mintInternal(msg.sender, depositAmount);
    }
    function withdrawDeposit() external nonReentrant {
        uint256 balance = pool.getDeposit(depositID).virtualTokenTotalSupply;
        require(balance > 0, "ZeroCouponBond: already withdrawn");
        pool.withdraw(depositID, balance, false);
        emit WithdrawDeposit();
    }
    function redeem(uint256 amount, bool withdrawDepositIfNeeded)
        external
        nonReentrant
    {
        _redeem(msg.sender, amount, withdrawDepositIfNeeded);
    }
    function sponsoredMint(
        uint256 depositAmount,
        Sponsorship calldata sponsorship
    )
        external
        nonReentrant
        sponsored(
            sponsorship,
            this.sponsoredMint.selector,
            abi.encode(depositAmount)
        )
        returns (uint256 mintedAmount)
    {
        return _mintInternal(sponsorship.sender, depositAmount);
    }
    function sponsoredRedeem(
        uint256 amount,
        bool withdrawDepositIfNeeded,
        Sponsorship calldata sponsorship
    )
        external
        nonReentrant
        sponsored(
            sponsorship,
            this.sponsoredRedeem.selector,
            abi.encode(amount, withdrawDepositIfNeeded)
        )
    {
        _redeem(sponsorship.sender, amount, withdrawDepositIfNeeded);
    }
    function withdrawDepositNeeded() external view returns (bool) {
        return pool.getDeposit(depositID).virtualTokenTotalSupply > 0;
    }
    function _mintInternal(address sender, uint256 depositAmount)
        internal
        returns (uint256 mintedAmount)
    {
        stablecoin.safeTransferFrom(sender, address(this), depositAmount);
        mintedAmount =
            depositAmount +
            pool.topupDeposit(depositID, depositAmount);
        _mint(sender, mintedAmount);
    }
    function _redeem(
        address sender,
        uint256 amount,
        bool withdrawDepositIfNeeded
    ) internal {
        require(
            block.timestamp >= maturationTimestamp,
            "ZeroCouponBond: not mature"
        );
        if (withdrawDepositIfNeeded) {
            uint256 balance =
                pool.getDeposit(depositID).virtualTokenTotalSupply;
            if (balance > 0) {
                pool.withdraw(depositID, balance, false);
                emit WithdrawDeposit();
            }
        }
        _burn(sender, amount);
        stablecoin.safeTransfer(sender, amount);
        emit RedeemStablecoin(sender, amount);
    }
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    uint256[43] private __gap;
}