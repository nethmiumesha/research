pragma solidity 0.5.14;
import "../SavingAccount.sol";
import { IController } from "../compound/ICompound.sol";
import "../Accounts.sol";
contract SavingAccountWithController is SavingAccount {
    Accounts.Account public accountVariable;
    address comptroller;
    constructor() public {
    }
    function initialize(
        address[] memory _tokenAddresses,
        address[] memory _cTokenAddresses,
        GlobalConfig _globalConfig,
        address _comptroller
    ) public initializer {
        comptroller = _comptroller;
        super.initialize(_tokenAddresses, _cTokenAddresses, _globalConfig);
    }
    function fastForward(uint blocks) public returns (uint) {
        return IController(comptroller).fastForward(blocks);
    }
    function getBlockNumber() internal view returns (uint) {
        return IController(comptroller).getBlockNumber();
    }
    function newRateIndexCheckpoint(address _token) public {
        globalConfig.bank().newRateIndexCheckpoint(_token);
    }
    function getDepositPrincipal(address _token) public view returns (uint256) {
        return globalConfig.accounts().getDepositPrincipal(msg.sender, _token);
    }
    function getDepositInterest(address _token) public view returns (uint256) {
        return globalConfig.accounts().getDepositInterest(msg.sender, _token);
    }
    function getDepositBalance(address _token, address _accountAddr) public view returns (uint256) {
        return globalConfig.accounts().getDepositBalanceCurrent(_token, _accountAddr);
    }
    function getBorrowPrincipal(address _token) public view returns (uint256) {
        return globalConfig.accounts().getBorrowPrincipal(msg.sender, _token);
    }
    function getBorrowInterest(address _token) public view returns (uint256) {
        return globalConfig.accounts().getBorrowInterest(msg.sender, _token);
    }
    function getBorrowBalance(address _token, address _accountAddr) public view returns (uint256) {
        return globalConfig.accounts().getBorrowBalanceCurrent(_token, _accountAddr);
    }
    function getBorrowETH(address _account) public view returns (uint256) {
        return globalConfig.accounts().getBorrowETH(_account);
    }
    function getDepositETH(address _account) public view returns (uint256) {
        return globalConfig.accounts().getDepositETH(_account);
    }
    function getTokenPrice(address _token) public view returns (uint256) {
        return globalConfig.tokenInfoRegistry().priceFromAddress(_token);
    }
    function getTokenState(address _token) public view returns (uint256 deposits, uint256 loans, uint256 reserveBalance, uint256 remainingAssets){
        return globalConfig.bank().getTokenState(_token);
    }
}