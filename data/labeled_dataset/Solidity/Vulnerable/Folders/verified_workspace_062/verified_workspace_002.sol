pragma solidity ^0.6.0;
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {Math} from "@openzeppelin/contracts/math/Math.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/Initializable.sol";
import "./Interfaces.sol";
import { ReentrancyGuardPausable } from "../ReentrancyGuardPausable.sol";
import "../UpgradeableOwnable.sol";
import "../interfaces/IyVaultV2.sol";
contract SimpleVault is ERC20, UpgradeableOwnable, ReentrancyGuardPausable, IyVaultV2Simple, Initializable {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    struct StratCandidate {
        address implementation;
        uint256 proposedTime;
    }
    StratCandidate public stratCandidate;
    ISimpleStrategy public strategy;
    IERC20 private assetToken;
    uint256 public approvalDelay;
    event NewStratCandidate(address implementation);
    event UpgradeStrat(address implementation);
    bool public needWhitelist = false;
    mapping(address => bool) public isWhitelisted;
    string private vaultName;
    string private vaultSymbol;
    constructor () public ERC20("", "") {}
    function initialize(
        address _token,
        address _strategy,
        string memory _name,
        string memory _symbol,
        uint256 _approvalDelay
    )
        external
        initializer
        onlyOwner
    {
        assetToken = IERC20(_token);
        strategy = ISimpleStrategy(_strategy);
        approvalDelay = _approvalDelay;
        assetToken.safeApprove(_strategy, uint256(-1));
        vaultName = _name;
        vaultSymbol = _symbol;
    }
    function name() public view override returns (string memory) {
        return vaultName;
    }
    function symbol() public view override returns (string memory) {
        return vaultSymbol;
    }
    function decimals() public view override(IyVaultV2Simple, ERC20) returns (uint8) {
        return 18;
    }
    function token() public view override returns (address) {
        return address(assetToken);
    }
    function totalBalance() public view returns (uint) {
        return strategy.totalBalance();
    }
    function getPricePerFullShare() public view returns (uint256) {
        return totalBalance().mul(1e18).div(totalSupply());
    }
    function pricePerShare() public view override returns (uint256) {
        return getPricePerFullShare();
    }
    function depositAll() external {
        deposit(assetToken.balanceOf(msg.sender));
    }
    function deposit(uint256 _amount) public override nonReentrantAndUnpaused returns (uint256) {
        require(!needWhitelist || isWhitelisted[msg.sender], "not whitelisted");
        assetToken.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 balanceOld = totalBalance();
        strategy.deposit(_amount);
        uint256 balanceNew = totalBalance();
        uint256 actualAmount = balanceNew.sub(balanceOld);
        uint256 shares = 0;
        if (totalSupply() == 0) {
            shares = actualAmount;
        } else {
            shares = (actualAmount.mul(totalSupply())).div(balanceOld);
        }
        _mint(msg.sender, shares);
        return shares;
    }
    function withdrawAll() external {
        withdraw(balanceOf(msg.sender));
    }
    function _withdraw(uint256 _shares, address _recipient) internal returns (uint256) {
        require(!needWhitelist || isWhitelisted[msg.sender], "not whitelisted");
        uint256 amount = (totalBalance().mul(_shares)).div(totalSupply());
        _burn(msg.sender, _shares);
        strategy.withdraw(amount);
        uint256 actualAmount = assetToken.balanceOf(address(this));
        assetToken.safeTransfer(_recipient, actualAmount);
        return actualAmount;
    }
    function withdraw(uint256 _shares) public override nonReentrantAndUnpaused returns (uint256) {
        return _withdraw(_shares, msg.sender);
    }
    function withdraw(uint256 _shares, address _recipient) external override nonReentrantAndUnpaused returns (uint256) {
        return _withdraw(_shares, _recipient);
    }
    function proposeStrat(address _implementation) external onlyOwner {
        stratCandidate = StratCandidate({
            implementation: _implementation,
            proposedTime: block.timestamp
         });
        emit NewStratCandidate(_implementation);
    }
    function whitelist(address _account, bool _whitelisted) external onlyOwner {
        isWhitelisted[_account] = _whitelisted;
    }
    function setNeedWhitelist(bool _needWhitelist) external onlyOwner {
        needWhitelist = _needWhitelist;
    }
    function upgradeStrat() external onlyOwner {
        require(stratCandidate.implementation != address(0), "There is no candidate");
        require(stratCandidate.proposedTime.add(approvalDelay) < block.timestamp, "Delay has not passed");
        emit UpgradeStrat(stratCandidate.implementation);
        strategy.withdraw(totalBalance());
        assetToken.safeApprove(address(strategy), 0);
        strategy = ISimpleStrategy(stratCandidate.implementation);
        stratCandidate.implementation = address(0);
        stratCandidate.proposedTime = 5000000000;
        assetToken.safeApprove(address(strategy), uint256(-1));
        strategy.deposit(assetToken.balanceOf(address(this)));
    }
}