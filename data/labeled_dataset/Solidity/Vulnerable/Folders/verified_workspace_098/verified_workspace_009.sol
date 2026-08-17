pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IProvider.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/IFujiMappings.sol";
import "../interfaces/compound/IGenCToken.sol";
import "../interfaces/compound/ICErc20.sol";
import "../interfaces/compound/IComptroller.sol";
import "../libraries/LibUniversalERC20.sol";
contract HelperFunct {
  function _isETH(address token) internal pure returns (bool) {
    return (token == address(0) || token == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE));
  }
  function _getMappingAddr() internal pure returns (address) {
    return 0x17525aFdb24D24ABfF18108E7319b93012f3AD24;
  }
  function _getComptrollerAddress() internal pure returns (address) {
    return 0xAB1c342C7bf5Ec5F02ADEA1c2270670bCa144CbB;
  }
  function _enterCollatMarket(address _cyTokenAddress) internal {
    IComptroller comptroller = IComptroller(_getComptrollerAddress());
    address[] memory cyTokenMarkets = new address[](1);
    cyTokenMarkets[0] = _cyTokenAddress;
    comptroller.enterMarkets(cyTokenMarkets);
  }
  function _exitCollatMarket(address _cyTokenAddress) internal {
    IComptroller comptroller = IComptroller(_getComptrollerAddress());
    comptroller.exitMarket(_cyTokenAddress);
  }
}
contract ProviderIronBank is IProvider, HelperFunct {
  using LibUniversalERC20 for IERC20;
  function deposit(address _asset, uint256 _amount) external payable override {
    address cyTokenAddr = IFujiMappings(_getMappingAddr()).addressMapping(_asset);
    _enterCollatMarket(cyTokenAddr);
    if (_isETH(_asset)) {
      IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2).deposit{ value: _amount }();
      _asset = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    }
    IERC20 erc20token = IERC20(_asset);
    ICErc20 cyToken = ICErc20(cyTokenAddr);
    require(erc20token.balanceOf(address(this)) >= _amount, "Not enough Balance");
    erc20token.univApprove(address(cyTokenAddr), _amount);
    require(cyToken.mint(_amount) == 0, "Deposit-failed");
  }
  function withdraw(address _asset, uint256 _amount) external payable override {
    address cyTokenAddr = IFujiMappings(_getMappingAddr()).addressMapping(_asset);
    IGenCToken cyToken = IGenCToken(cyTokenAddr);
    require(cyToken.redeemUnderlying(_amount) == 0, "Withdraw-failed");
    if (_isETH(_asset)) {
      IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2).withdraw(_amount);
    }
  }
  function borrow(address _asset, uint256 _amount) external payable override {
    address cyTokenAddr = IFujiMappings(_getMappingAddr()).addressMapping(_asset);
    IGenCToken cyToken = IGenCToken(cyTokenAddr);
    require(cyToken.borrow(_amount) == 0, "borrow-failed");
    if (_isETH(_asset)) {
      IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2).withdraw(_amount);
    }
  }
  function payback(address _asset, uint256 _amount) external payable override {
    address cyTokenAddr = IFujiMappings(_getMappingAddr()).addressMapping(_asset);
    if (_isETH(_asset)) {
      IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2).deposit{ value: _amount }();
      _asset = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    }
    IERC20 erc20token = IERC20(_asset);
    ICErc20 cyToken = ICErc20(cyTokenAddr);
    require(erc20token.balanceOf(address(this)) >= _amount, "Not-enough-token");
    erc20token.univApprove(address(cyTokenAddr), _amount);
    cyToken.repayBorrow(_amount);
  }
  function getBorrowRateFor(address _asset) external view override returns (uint256) {
    address cyTokenAddr = IFujiMappings(_getMappingAddr()).addressMapping(_asset);
    uint256 bRateperBlock = IGenCToken(cyTokenAddr).borrowRatePerBlock() * 10**9;
    uint256 blocksperYear = 2102400;
    return bRateperBlock * blocksperYear;
  }
  function getBorrowBalance(address _asset) external view override returns (uint256) {
    address cyTokenAddr = IFujiMappings(_getMappingAddr()).addressMapping(_asset);
    return IGenCToken(cyTokenAddr).borrowBalanceStored(msg.sender);
  }
  function getBorrowBalanceOf(address _asset, address _who) external override returns (uint256) {
    address cyTokenAddr = IFujiMappings(_getMappingAddr()).addressMapping(_asset);
    return IGenCToken(cyTokenAddr).borrowBalanceCurrent(_who);
  }
  function getDepositBalance(address _asset) external view override returns (uint256) {
    address cyTokenAddr = IFujiMappings(_getMappingAddr()).addressMapping(_asset);
    uint256 cyTokenBal = IGenCToken(cyTokenAddr).balanceOf(msg.sender);
    uint256 exRate = IGenCToken(cyTokenAddr).exchangeRateStored();
    return (exRate * cyTokenBal) / 1e18;
  }
}