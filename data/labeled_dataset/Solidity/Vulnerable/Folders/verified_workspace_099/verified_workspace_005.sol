pragma solidity 0.6.11;
import "../LUSDToken.sol";
contract LUSDTokenTester is LUSDToken {
    constructor(
        address _troveManagerAddress,
        address _stabilityPoolAddress,
        address _borrowerOperationsAddress
    ) public LUSDToken(_troveManagerAddress,
                      _stabilityPoolAddress,
                      _borrowerOperationsAddress) {}
    function unprotectedMint(address _account, uint256 _amount) external {
        _mint(_account, _amount);
    }
    function unprotectedBurn(address _account, uint _amount) external {
        _burn(_account, _amount);
    }
    function unprotectedSendToPool(address _sender,  address _poolAddress, uint256 _amount) external {
        _transfer(_sender, _poolAddress, _amount);
    }
    function unprotectedReturnFromPool(address _poolAddress, address _receiver, uint256 _amount ) external {
        _transfer(_poolAddress, _receiver, _amount);
    }
    function callInternalApprove(address owner, address spender, uint256 amount) external returns (bool) {
        _approve(owner, spender, amount);
    }
}