pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IProvider.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/aave/IAaveDataProvider.sol";
import "../interfaces/aave/IAaveLendingPool.sol";
import "../interfaces/aave/IAaveLendingPoolProvider.sol";
import "../libraries/LibUniversalERC20.sol";
contract ProviderAave is IProvider {
  using LibUniversalERC20 for IERC20;
  function _getAaveProvider() internal pure returns (IAaveLendingPoolProvider) {
    return IAaveLendingPoolProvider(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5);
  }
  function _getAaveDataProvider() internal pure returns (IAaveDataProvider) {
    return IAaveDataProvider(0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d);
  }
  function _getWethAddr() internal pure returns (address) {
    return 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  }
  function _getEthAddr() internal pure returns (address) {
    return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  }
  function getBorrowRateFor(address _asset) external view override returns (uint256) {
    IAaveDataProvider aaveData = _getAaveDataProvider();
    (, , , , uint256 variableBorrowRate, , , , , ) = IAaveDataProvider(aaveData).getReserveData(
      _asset == _getEthAddr() ? _getWethAddr() : _asset
    );
    return variableBorrowRate;
  }
  function getBorrowBalance(address _asset) external view override returns (uint256) {
    IAaveDataProvider aaveData = _getAaveDataProvider();
    bool isEth = _asset == _getEthAddr();
    address _tokenAddr = isEth ? _getWethAddr() : _asset;
    (, , uint256 variableDebt, , , , , , ) = aaveData.getUserReserveData(_tokenAddr, msg.sender);
    return variableDebt;
  }
  function getBorrowBalanceOf(address _asset, address _who)
    external
    view
    override
    returns (uint256)
  {
    IAaveDataProvider aaveData = _getAaveDataProvider();
    bool isEth = _asset == _getEthAddr();
    address _tokenAddr = isEth ? _getWethAddr() : _asset;
    (, , uint256 variableDebt, , , , , , ) = aaveData.getUserReserveData(_tokenAddr, _who);
    return variableDebt;
  }
  function getDepositBalance(address _asset) external view override returns (uint256) {
    IAaveDataProvider aaveData = _getAaveDataProvider();
    bool isEth = _asset == _getEthAddr();
    address _tokenAddr = isEth ? _getWethAddr() : _asset;
    (uint256 atokenBal, , , , , , , , ) = aaveData.getUserReserveData(_tokenAddr, msg.sender);
    return atokenBal;
  }
  function deposit(address _asset, uint256 _amount) external payable override {
    IAaveLendingPool aave = IAaveLendingPool(_getAaveProvider().getLendingPool());
    bool isEth = _asset == _getEthAddr();
    address _tokenAddr = isEth ? _getWethAddr() : _asset;
    if (isEth) IWETH(_tokenAddr).deposit{ value: _amount }();
    IERC20(_tokenAddr).univApprove(address(aave), _amount);
    aave.deposit(_tokenAddr, _amount, address(this), 0);
    aave.setUserUseReserveAsCollateral(_tokenAddr, true);
  }
  function borrow(address _asset, uint256 _amount) external payable override {
    IAaveLendingPool aave = IAaveLendingPool(_getAaveProvider().getLendingPool());
    bool isEth = _asset == _getEthAddr();
    address _tokenAddr = isEth ? _getWethAddr() : _asset;
    aave.borrow(_tokenAddr, _amount, 2, 0, address(this));
    if (isEth) IWETH(_tokenAddr).withdraw(_amount);
  }
  function withdraw(address _asset, uint256 _amount) external payable override {
    IAaveLendingPool aave = IAaveLendingPool(_getAaveProvider().getLendingPool());
    bool isEth = _asset == _getEthAddr();
    address _tokenAddr = isEth ? _getWethAddr() : _asset;
    aave.withdraw(_tokenAddr, _amount, address(this));
    if (isEth) IWETH(_tokenAddr).withdraw(_amount);
  }
  function payback(address _asset, uint256 _amount) external payable override {
    IAaveLendingPool aave = IAaveLendingPool(_getAaveProvider().getLendingPool());
    bool isEth = _asset == _getEthAddr();
    address _tokenAddr = isEth ? _getWethAddr() : _asset;
    if (isEth) IWETH(_tokenAddr).deposit{ value: _amount }();
    IERC20(_tokenAddr).univApprove(address(aave), _amount);
    aave.repay(_tokenAddr, _amount, 2, address(this));
  }
}