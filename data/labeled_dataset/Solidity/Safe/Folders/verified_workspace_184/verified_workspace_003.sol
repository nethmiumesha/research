pragma solidity ^0.6.11;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
contract STACKToken is ERC20, ERC20Burnable {
	using SafeERC20 for IERC20;
	using Address for address;
    using SafeMath for uint256;
    address public governance;
    mapping(address => bool) public minters;
    constructor () public ERC20("Stacker.vc", "STACK") {
    	governance = msg.sender;
    	minters[msg.sender] = true;
    	_setupDecimals(18);
	}
	function mint(address account, uint amount) external {
		require(minters[msg.sender], "!minter");
		_mint(account, amount);
	}
	function setGovernance(address _governance) external {
		require(msg.sender == governance, "!governance");
		governance = _governance;
	}
	function addMinter(address _minter) external {
		require(msg.sender == governance, "!governance");
		minters[_minter] = true;
	}
	function removeMinter(address _minter) external {
		require(msg.sender == governance, "!governance");
		minters[_minter] = false;
	}
}