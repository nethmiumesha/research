pragma solidity 0.6.12;
import "./YearnV2YieldSource.sol";
import "../external/openzeppelin/ProxyFactory.sol";
contract YearnV2YieldSourceProxyFactory is ProxyFactory {
  YearnV2YieldSource public instance;
  constructor () public {
    instance = new YearnV2YieldSource();
  }
  function create(
    IYVaultV2 _vault,
    IERC20Upgradeable _token
  ) public returns (YearnV2YieldSource) {
    YearnV2YieldSource yearnV2YieldSource = YearnV2YieldSource(deployMinimal(address(instance), ""));
    yearnV2YieldSource.initialize(_vault, _token);
    return yearnV2YieldSource;
  }
}