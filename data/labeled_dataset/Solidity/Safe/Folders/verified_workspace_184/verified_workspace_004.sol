pragma solidity ^0.6.11;
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../Interfaces/IVault.sol";
import "../Interfaces/IGaugeD1.sol";
contract VaultGaugeBridge is ReentrancyGuard {
	using SafeERC20 for IERC20;
	using Address for address;
    using SafeMath for uint256;
    address payable public WETH_VAULT = 0xe1237aA7f535b0CC33Fd973D66cBf830354D16c7;
    address public governance;
    mapping(address => address) public bridges;
    constructor () public {
    	governance = msg.sender;
    }
    receive() external payable {
        if (msg.sender != WETH_VAULT){
            if (IGaugeD1(bridges[WETH_VAULT]).fundOpen()){
                depositBridgeETH(WETH_VAULT, true);
            }
            else {
                depositBridgeETH(WETH_VAULT, false);
            }
        }
    }
    function setGovernance(address _new) external {
        require(msg.sender == governance, "BRIDGE: !governance");
        governance = _new;
    }
    function newBridge(address _vault, address _gauge) external {
    	require(msg.sender == governance, "BRIDGE: !governance");
    	bridges[_vault] = _gauge;
    }
    function setWETHVault(address payable _new) external {
        require(msg.sender == governance, "BRIDGE: !governance");
        WETH_VAULT = _new;
    }
    function depositBridge(address _vault, uint256 _amount, bool _commit) nonReentrant external {
    	address _gauge = bridges[_vault];
    	require(_gauge != address(0), "BRIDGE: !bridge");
    	IERC20 _token = IVault(_vault).token();
    	uint256 _before = _token.balanceOf(address(this));
    	_token.safeTransferFrom(msg.sender, address(this), _amount);
    	uint256 _after = _token.balanceOf(address(this));
    	uint256 _transferred = _after.sub(_before);
    	_token.safeApprove(_vault, 0);
    	_token.safeApprove(_vault, _transferred);
    	uint256 _beforeYToken = IERC20(_vault).balanceOf(address(this));
    	IVault(_vault).deposit(_transferred);
    	uint256 _afterYToken = IERC20(_vault).balanceOf(address(this));
    	uint256 _receivedYToken = _afterYToken.sub(_beforeYToken);
    	_depositGauge(_gauge, _vault, _receivedYToken, _commit, msg.sender);
    }
    function depositBridgeETH(address payable _vault, bool _commit) nonReentrant public payable {
    	address _gauge = bridges[_vault];
    	require(_gauge != address(0), "BRIDGE: !bridge");
    	uint256 _beforeYToken = IERC20(_vault).balanceOf(address(this));
    	IVault(_vault).depositETH{value: msg.value}();
    	uint256 _afterYToken = IERC20(_vault).balanceOf(address(this));
    	uint256 _receivedYToken = _afterYToken.sub(_beforeYToken);
    	_depositGauge(_gauge, _vault, _receivedYToken, _commit, msg.sender);
    }
    function withdrawBridge(address _vault, uint256 _amount) nonReentrant external {
        address _gauge = bridges[_vault];
        require(_gauge != address(0), "BRIDGE: !bridge");
        uint256 _receivedYToken = _withdrawGauge(_gauge, _vault, _amount, msg.sender);
        IERC20 _token = IVault(_vault).token();
        uint256 _before = _token.balanceOf(address(this));
        IVault(_vault).withdraw(_receivedYToken);
        uint256 _after = _token.balanceOf(address(this));
        uint256 _transferred = _after.sub(_before);
        _token.safeTransfer(msg.sender, _transferred);
    }
    function withdrawBridgeETH(address _vault, uint256 _amount) nonReentrant external {
        address _gauge = bridges[_vault];
        require(_gauge != address(0), "BRIDGE: !bridge");
        uint256 _receivedYToken = _withdrawGauge(_gauge, _vault, _amount, msg.sender);
        uint256 _before = address(this).balance;
        IVault(_vault).withdrawETH(_receivedYToken);
        uint256 _after = address(this).balance;
        uint256 _transferred = _after.sub(_before);
        msg.sender.transfer(_transferred);
    }
    function _withdrawGauge(address _gauge, address _acceptToken, uint256 _amount, address _user) internal returns (uint256){
        uint256 _beforeYToken = IERC20(_acceptToken).balanceOf(address(this));
        IGaugeD1(_gauge).withdraw(_amount, _user);
        uint256 _afterYToken = IERC20(_acceptToken).balanceOf(address(this));
        return _afterYToken.sub(_beforeYToken);
    }
    function _depositGauge(address _gauge, address _acceptToken, uint256 _amount, bool _commit, address _user) internal {
		IERC20(_acceptToken).safeApprove(_gauge, 0);
    	IERC20(_acceptToken).safeApprove(_gauge, _amount);
    	if (_commit){
    		IGaugeD1(_gauge).deposit(0, _amount, _user);
    	}
    	else {
    		IGaugeD1(_gauge).deposit(_amount, 0, _user);
    	}
    }
}