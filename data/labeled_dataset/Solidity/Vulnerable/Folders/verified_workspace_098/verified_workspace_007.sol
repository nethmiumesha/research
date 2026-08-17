pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IProvider.sol";
import "../interfaces/compound/IGenCToken.sol";
import "../interfaces/compound/ICErc20.sol";
import "../interfaces/compound/ICEth.sol";
import "../interfaces/compound/IFuseComptroller.sol";
import "../libraries/LibUniversalERC20.sol";
contract HelperFunct {
  function _isETH(address token) internal pure returns (bool) {
    return (token == address(0) || token == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE));
  }
  function _getComptrollerAddress() internal pure returns (address) {
    return 0xFB558eCD2D24886e8d2956775C619deb22f154EF;
  }
  function _getCTokenAddr(address _asset) internal view returns (address cTokenAddr) {
    if (_isETH(_asset)) {
      cTokenAddr = IFuseComptroller(_getComptrollerAddress()).cTokensByUnderlying(
        0x0000000000000000000000000000000000000000
      );
    } else {
      cTokenAddr = IFuseComptroller(_getComptrollerAddress()).cTokensByUnderlying(_asset);
    }
  }
  function _enterCollatMarket(address _cTokenAddress) internal {
    IFuseComptroller comptroller = IFuseComptroller(_getComptrollerAddress());
    address[] memory cTokenMarkets = new address[](1);
    cTokenMarkets[0] = _cTokenAddress;
    comptroller.enterMarkets(cTokenMarkets);
  }
  function _exitCollatMarket(address _cTokenAddress) internal {
    IFuseComptroller comptroller = IFuseComptroller(_getComptrollerAddress());
    comptroller.exitMarket(_cTokenAddress);
  }
}
contract ProviderFuse7 is IProvider, HelperFunct {
  using LibUniversalERC20 for IERC20;
  function deposit(address _asset, uint256 _amount) external payable override {
    address cTokenAddr = _getCTokenAddr(_asset);
    _enterCollatMarket(cTokenAddr);
    if (_isETH(_asset)) {
      ICEth cToken = ICEth(cTokenAddr);
      cToken.mint{ value: _amount }();
    } else {
      IERC20 erc20token = IERC20(_asset);
      ICErc20 cToken = ICErc20(cTokenAddr);
      require(erc20token.balanceOf(address(this)) >= _amount, "Not enough Balance");
      erc20token.univApprove(address(cTokenAddr), _amount);
      require(cToken.mint(_amount) == 0, "Deposit-failed");
    }
  }
  function withdraw(address _asset, uint256 _amount) external payable override {
    address cTokenAddr = _getCTokenAddr(_asset);
    IGenCToken cToken = IGenCToken(cTokenAddr);
    require(cToken.redeemUnderlying(_amount) == 0, "Withdraw-failed");
  }
  function borrow(address _asset, uint256 _amount) external payable override {
    address cTokenAddr = _getCTokenAddr(_asset);
    IGenCToken cToken = IGenCToken(cTokenAddr);
    require(cToken.borrow(_amount) == 0, "borrow-failed");
  }
  function payback(address _asset, uint256 _amount) external payable override {
    address cTokenAddr = _getCTokenAddr(_asset);
    if (_isETH(_asset)) {
      ICEth cToken = ICEth(cTokenAddr);
      cToken.repayBorrow{ value: msg.value }();
    } else {
      IERC20 erc20token = IERC20(_asset);
      ICErc20 cToken = ICErc20(cTokenAddr);
      require(erc20token.balanceOf(address(this)) >= _amount, "Not-enough-token");
      erc20token.univApprove(address(cTokenAddr), _amount);
      cToken.repayBorrow(_amount);
    }
  }
  function getBorrowRateFor(address _asset) external view override returns (uint256) {
    address cTokenAddr = _getCTokenAddr(_asset);
    uint256 bRateperBlock = IGenCToken(cTokenAddr).borrowRatePerBlock() * 10**9;
    uint256 blocksperYear = 2102400;
    return bRateperBlock * blocksperYear;
  }
  function getBorrowBalance(address _asset) external view override returns (uint256) {
    address cTokenAddr = _getCTokenAddr(_asset);
    return IGenCToken(cTokenAddr).borrowBalanceStored(msg.sender);
  }
  function getBorrowBalanceOf(address _asset, address _who) external override returns (uint256) {
    address cTokenAddr = _getCTokenAddr(_asset);
    return IGenCToken(cTokenAddr).borrowBalanceCurrent(_who);
  }
  function getDepositBalance(address _asset) external view override returns (uint256) {
    address cTokenAddr = _getCTokenAddr(_asset);
    uint256 cTokenBal = IGenCToken(cTokenAddr).balanceOf(msg.sender);
    uint256 exRate = IGenCToken(cTokenAddr).exchangeRateStored();
    return (exRate * cTokenBal) / 1e18;
  }
}