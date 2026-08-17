pragma solidity 0.7.5;
interface IOwnable {
  function owner() external view returns (address);
  function renounceOwnership() external;
  function transferOwnership( address newOwner_ ) external;
}
library Address {
  function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }
    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}
contract Ownable is IOwnable {
  address internal _owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  constructor () {
    _owner = msg.sender;
    emit OwnershipTransferred( address(0), _owner );
  }
  function owner() public view override returns (address) {
    return _owner;
  }
  modifier onlyOwner() {
    require( _owner == msg.sender, "Ownable: caller is not the owner" );
    _;
  }
  function renounceOwnership() public virtual override onlyOwner() {
    emit OwnershipTransferred( _owner, address(0) );
    _owner = address(0);
  }
  function transferOwnership( address newOwner_ ) public virtual override onlyOwner() {
    require( newOwner_ != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred( _owner, newOwner_ );
    _owner = newOwner_;
  }
}
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
interface IBondingCalculator {
    function calcDebtRatio( uint pendingDebtDue_, uint managedTokenTotalSupply_ ) external pure returns ( uint debtRatio_ );
    function calcBondPremium( uint debtRatio_, uint bondScalingFactor ) external pure returns ( uint premium_ );
    function calcPrincipleValuation( uint k_, uint amountDeposited_, uint totalSupplyOfTokenDeposited_ ) external pure returns ( uint principleValuation_ );
    function principleValuation( address principleTokenAddress_, uint amountDeposited_ ) external view returns ( uint principleValuation_ );
    function calculateBondInterest( address treasury_, address principleTokenAddress_, uint amountDeposited_, uint bondScalingFactor ) external returns ( uint interestDue_ );
}
interface ITreasury {
    function getBondingCalculator() external returns ( address );
    function getTimelockEndBlock() external returns ( uint );
    function getManagedToken() external returns ( address );
}
contract Vault is ITreasury, Ownable {
    using SafeMath for uint;
    using SafeMathInt for int;
    using SafeERC20 for IERC20;
    event TimelockStarted( uint timelockEndBlock );
    bool public isInitialized;
    uint public timelockDurationInBlocks;
    uint public override getTimelockEndBlock;
    address public daoWallet;
    address public LPRewardsContract;
    address public stakingContract;
    uint public LPProfitShare;
    address public override getManagedToken;
    address public getReserveToken;
    address public getPrincipleToken;
    address public override getBondingCalculator;
    mapping( address => bool ) public isPrincipleDepositor;
    mapping( address => bool ) public isReserveDepositor;
    modifier notInitialized() {
        require( !isInitialized );
        _;
    }
    modifier isTimelockExpired() {
        require( getTimelockEndBlock != 1 );
        require( timelockDurationInBlocks > 1 );
        require( block.number >= getTimelockEndBlock );
        _;
    }
    modifier isTimelockStarted() {
        if( getTimelockEndBlock != 0 ) {
          emit TimelockStarted( getTimelockEndBlock );
        }
        _;
    }
    function setDAOWallet( address newDAOWallet_ ) external onlyOwner() returns ( bool ) {
        daoWallet = newDAOWallet_;
        return true;
    }
    function setStakingContract( address newStakingContract_ ) external onlyOwner() returns ( bool ) {
        stakingContract = newStakingContract_;
        return true;
    }
    function setLPRewardsContract( address newLPRewardsContract_ ) external onlyOwner() returns ( bool ) {
        LPRewardsContract = newLPRewardsContract_;
        return true;
    }
    function setLPProfitShare( uint newDAOProfitShare_ ) external onlyOwner() returns ( bool ) {
        LPProfitShare = newDAOProfitShare_;
        return true;
    }
    function initialize(
        address newManagedToken_,
        address newReserveToken_,
        address newBondingCalculator_
    ) external onlyOwner() notInitialized() returns ( bool ) {
        getManagedToken = newManagedToken_;
        getReserveToken = newReserveToken_;
        getBondingCalculator = newBondingCalculator_;
        timelockDurationInBlocks = 1;
        isInitialized = true;
        return true;
    }
    function setPrincipleDepositor( address newDepositor_ ) external onlyOwner() returns ( bool ) {
        isPrincipleDepositor[newDepositor_] = true;
        return true;
    }
    function setReserveDepositor( address newDepositor_ ) external onlyOwner() returns ( bool ) {
        isReserveDepositor[newDepositor_] = true;
        return true;
    }
    function removePrincipleDepositor( address depositor_ ) external onlyOwner() returns ( bool ) {
        isPrincipleDepositor[depositor_] = false;
        return true;
    }
    function removeReserveDepositor( address depositor_ ) external onlyOwner() returns ( bool ) {
        isReserveDepositor[depositor_] = false;
        return true;
    }
    function rewardsDepositPrinciple( uint depositAmount_ ) external returns ( bool ) {
        require(isPrincipleDepositor[msg.sender] == true, "Not allowed to deposit");
        address principleToken = getPrincipleToken;
        IERC20( principleToken ).safeTransferFrom( msg.sender, address(this), depositAmount_ );
        uint value = IBondingCalculator( getBondingCalculator ).principleValuation( principleToken, depositAmount_ ).div( 1e9 );
        uint forLP = value.div( LPProfitShare );
        IERC20Mintable( getManagedToken ).mint( stakingContract, value.sub( forLP ) );
        IERC20Mintable( getManagedToken ).mint( LPRewardsContract, forLP );
        return true;
    }
    function depositReserves( uint amount_ ) external returns ( bool ) {
        require( isReserveDepositor[msg.sender] == true, "Not allowed to deposit" );
        IERC20( getReserveToken ).safeTransferFrom( msg.sender, address(this), amount_ );
        IERC20Mintable( getManagedToken ).mint( msg.sender, amount_.div( 10 ** IERC20( getManagedToken ).decimals() ) );
        return true;
    }
    function depositPrinciple( uint amount_ ) external returns ( bool ) {
        require( isPrincipleDepositor[msg.sender] == true, "Not allowed to deposit" );
        IERC20( getPrincipleToken ).safeTransferFrom( msg.sender, address(this), amount_ );
        uint value = IBondingCalculator( getBondingCalculator ).principleValuation( getPrincipleToken, amount_ ).div( 1e9 );
        IERC20Mintable( getManagedToken ).mint( msg.sender, value );
        return true;
    }
    function migrateReserveAndPrinciple() external onlyOwner() isTimelockExpired() returns ( bool saveGas_ ) {
        IERC20( getReserveToken ).safeTransfer( daoWallet, IERC20( getReserveToken ).balanceOf( address( this ) ) );
        IERC20( getPrincipleToken ).safeTransfer( daoWallet, IERC20( getPrincipleToken ).balanceOf( address( this ) ) );
        return true;
    }
    function setTimelock( uint newTimelockDurationInBlocks_ ) external onlyOwner() returns ( bool ) {
        require( newTimelockDurationInBlocks_ > timelockDurationInBlocks, "Can only extend timelock" );
        timelockDurationInBlocks = newTimelockDurationInBlocks_;
        return true;
    }
    function startTimelock() external onlyOwner() returns ( bool ) {
        require( timelockDurationInBlocks > 1, "Timelock Not Set");
        getTimelockEndBlock = block.number.add( timelockDurationInBlocks );
        emit TimelockStarted( getTimelockEndBlock );
        return true;
    }
}