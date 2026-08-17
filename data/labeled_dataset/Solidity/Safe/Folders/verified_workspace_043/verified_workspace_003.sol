pragma solidity >=0.6.0 <0.7.0;
import "./YearnV2YieldSourceHarness.sol";
import "../external/openzeppelin/ProxyFactory.sol";
import "../yield-source/YearnV2YieldSourceProxyFactory.sol";
contract YearnV2YieldSourceProxyFactoryHarness is ProxyFactory {
  YearnV2YieldSourceHarness public instance;
  constructor () public {
    instance = new YearnV2YieldSourceHarness();
  }
  function create(
    IYVaultV2 _vault,
    IERC20Upgradeable _token
  ) public returns (YearnV2YieldSourceHarness) {
    YearnV2YieldSourceHarness yearnV2YieldSourceHarness = YearnV2YieldSourceHarness(deployMinimal(address(instance), ""));
    yearnV2YieldSourceHarness.initialize(_vault, _token);
    return yearnV2YieldSourceHarness;
  }
}