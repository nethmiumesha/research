import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import './Whitelist.sol';
pragma solidity "0.8.0";
contract IFOV3 is Whitelist{
    using SafeERC20 for IERC20;
    IERC20 public lpToken;
    IERC20 public offeringToken;
    uint8 public constant numberPools = 3;
    uint256 public startBlock;
    uint256 public endBlock;
    PoolCharacteristics[numberPools] private _poolInformation;
    mapping(address => mapping(uint8 => uint256)) private amountPool;
    struct PoolCharacteristics {
        uint256 offeringAmountPool;
        uint256 priceA;
        uint256 priceB;
        uint256 totalAmountPool;
    }
    event AdminWithdraw(uint256 amountLP, uint256 amountOfferingToken, uint256 amountWei);
    event AdminTokenRecovery(address tokenAddress, uint256 amountTokens);
    event Deposit(address indexed user, uint256 amount, uint8 indexed pid);
    event Harvest(address indexed user, uint256 offeringAmount, uint256 excessAmount, uint8 indexed pid);
    event NewStartAndEndBlocks(uint256 startBlock, uint256 endBlock);
    event PoolParametersSet(uint256 offeringAmountPool, uint priceA_, uint priceB_, uint8 pid);
    modifier TimeLock() {
        require(block.number > endBlock + 90000, 'Admin must wait before calling this function');
    _;}
    constructor(
        IERC20 _lpToken,
        IERC20 _offeringToken,
        uint256 _startBlock,
        uint256 _endBlock,
        address _adminAddress
    ) {
        require(_lpToken.totalSupply() >= 0);
        require(_offeringToken.totalSupply() >= 0);
        require(_lpToken != _offeringToken, "Tokens must be be different");
        lpToken = _lpToken;
        offeringToken = _offeringToken;
        startBlock = _startBlock;
        endBlock = _endBlock;
        transferOwnership(_adminAddress);
    }
    function depositPool(uint256 _amount, uint8 _pid) external {
        require(_pid < numberPools, "Non valid pool id");
        require(_poolInformation[_pid].offeringAmountPool > 0, "Pool not set");
        require(block.number > startBlock, "Too early");
        require(block.number < endBlock, "Too late");
        require(_amount > 0, "Amount must be > 0");
        if(_pid == 0){
          require(
            _poolInformation[_pid].offeringAmountPool >= (_poolInformation[_pid].totalAmountPool + (_amount)) * (_poolInformation[_pid].priceA),
            'not enough Offering Tokens left in Pool1');
        }
        lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        amountPool[msg.sender][_pid] += _amount;
        _poolInformation[_pid].totalAmountPool += _amount;
        emit Deposit(msg.sender, _amount, _pid);
    }
    function harvestPool(uint8 _pid) external {
        require(block.number > endBlock, "Too early to harvest");
        require(_pid < numberPools, "Non valid pool id");
        require(amountPool[msg.sender][_pid] > 0, "Did not participate");
        if(whitelistedMap[msg.sender] != 1 && whitelistStatus == true){
          uint amount = amountPool[msg.sender][_pid];
          amountPool[msg.sender][_pid] = 0;
          lpToken.safeTransfer(address(msg.sender), amount);
          emit Harvest(msg.sender, 0, amount, _pid);
        }else{
          uint256 offeringTokenAmount;
          uint256 refundingTokenAmount;
          (offeringTokenAmount, refundingTokenAmount) = _calculateOfferingAndRefundingAmountsPool(
            msg.sender,
            _pid
          );
          amountPool[msg.sender][_pid] = 0;
          if (offeringTokenAmount > 0) {
            offeringToken.safeTransfer(address(msg.sender), offeringTokenAmount);
          }
          if (refundingTokenAmount > 0) {
            lpToken.safeTransfer(address(msg.sender), refundingTokenAmount);
          }
          emit Harvest(msg.sender, offeringTokenAmount, refundingTokenAmount, _pid);
        }
    }
    function finalWithdraw(uint256 _lpAmount, uint256 _offerAmount, uint256 _weiAmount) external  onlyOwner TimeLock {
        require(_lpAmount <= lpToken.balanceOf(address(this)), "Not enough LP tokens");
        require(_offerAmount <= offeringToken.balanceOf(address(this)), "Not enough offering token");
        if (_lpAmount > 0) {
            lpToken.safeTransfer(address(msg.sender), _lpAmount);
        }
        if (_offerAmount > 0) {
            offeringToken.safeTransfer(address(msg.sender), _offerAmount);
        }
        if (_weiAmount > 0){
            payable(address(msg.sender)).transfer(_weiAmount);
        }
        emit AdminWithdraw(_lpAmount, _offerAmount, _weiAmount);
    }
    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        require(_tokenAddress != address(lpToken), "Cannot be LP token");
        require(_tokenAddress != address(offeringToken), "Cannot be offering token");
        IERC20(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);
        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }
    function setPool(
        uint256 _offeringAmountPool,
        uint256 _priceA,
        uint _priceB,
        uint8 _pid
    ) external  onlyOwner TimeLock {
        require(_pid < numberPools, "Pool does not exist");
        _poolInformation[_pid].offeringAmountPool = _offeringAmountPool;
        _poolInformation[_pid].priceA = _priceA;
        _poolInformation[_pid].priceB = _priceB;
        uint sum = 0;
        for (uint j = 0; j < numberPools; j++){
            sum += _poolInformation[j].offeringAmountPool;
        }
        require(sum <= offeringToken.balanceOf(address(this)),
        'cant offer more than balance');
        emit PoolParametersSet(_offeringAmountPool, _priceA, _priceB, _pid);
    }
    function updateStartAndEndBlocks(uint256 _startBlock, uint256 _endBlock) external onlyOwner TimeLock {
        require(_startBlock < _endBlock, "New startBlock must be lower than new endBlock");
        require(block.number < _startBlock, "New startBlock must be higher than current block");
        for(uint j = 0; j < numberPools; j++){
            _poolInformation[j].totalAmountPool = 0;
        }
        startBlock = _startBlock;
        endBlock = _endBlock;
        emit NewStartAndEndBlocks(_startBlock, _endBlock);
    }
    function viewPoolInformation(uint256 _pid)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            _poolInformation[_pid].offeringAmountPool,
            _poolInformation[_pid].priceA,
            _poolInformation[_pid].priceB,
            _poolInformation[_pid].totalAmountPool
        );
    }
    function viewUserAllocationPools(address _user, uint8[] calldata _pids)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory allocationPools = new uint256[](_pids.length);
        for (uint8 i = 0; i < _pids.length; i++) {
            allocationPools[i] = _getUserAllocationPool(_user, _pids[i]);
        }
        return allocationPools;
    }
    function viewUserAmount(address _user, uint8[] calldata _pids)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory amountPools = new uint256[](_pids.length);
        for (uint8 i = 0; i < numberPools; i++) {
            amountPools[i] = amountPool[_user][i];
        }
        return (amountPools);
    }
    function viewUserOfferingAndRefundingAmountsForPools(address _user, uint8[] calldata _pids)
        external
        view
        returns (uint256[2][] memory)
    {
        uint256[2][] memory amountPools = new uint256[2][](_pids.length);
        for (uint8 i = 0; i < _pids.length; i++) {
            uint256 userOfferingAmountPool;
            uint256 userRefundingAmountPool;
            if (_poolInformation[_pids[i]].offeringAmountPool > 0) {
                (
                    userOfferingAmountPool,
                    userRefundingAmountPool
                ) = _calculateOfferingAndRefundingAmountsPool(_user, _pids[i]);
            }
            amountPools[i] = [userOfferingAmountPool, userRefundingAmountPool];
        }
        return amountPools;
    }
    function _calculateOfferingAndRefundingAmountsPool(address _user, uint8 _pid)
        internal
        view
        returns (
            uint256,
            uint256
        )
    {
      if(amountPool[_user][_pid] == 0){
        return(0, 0);
      }
      uint256 userOfferingAmount;
      uint256 userRefundingAmount;
      if (_pid == 0){
        userOfferingAmount = amountPool[_user][0] * (_poolInformation[0].priceA);
        return (userOfferingAmount, 0);
      }
      uint256 allocation = _getUserAllocationPool(_user, _pid);
      if (_pid == 2){
        userOfferingAmount = _poolInformation[2].offeringAmountPool * (allocation) / (1e12);
        return (userOfferingAmount, 0);
      }
      if (_poolInformation[1].totalAmountPool * (_poolInformation[1].priceA) > _poolInformation[1].offeringAmountPool){
        userOfferingAmount = _poolInformation[1].offeringAmountPool * (allocation) / (1e12);
      }else{
        userOfferingAmount = amountPool[_user][1] * (_poolInformation[1].priceA);
        return(userOfferingAmount, 0);
      }
      if (_poolInformation[1].totalAmountPool * (_poolInformation[1].priceB) <= _poolInformation[1].offeringAmountPool){
        return (userOfferingAmount, 0);
      }else{
        uint notcompensatedAmount = _poolInformation[1].totalAmountPool - (_poolInformation[1].offeringAmountPool / (_poolInformation[1].priceB));
        userRefundingAmount = allocation * (notcompensatedAmount) / (1e12);
        return (userOfferingAmount, userRefundingAmount);
      }
    }
    function _getUserAllocationPool(address _user, uint8 _pid) internal view returns (uint256) {
        if (_poolInformation[_pid].totalAmountPool > 0) {
            return amountPool[_user][_pid] * (1e12) / _poolInformation[_pid].totalAmountPool;
        } else {
            return 0;
        }
    }
    fallback() external payable{}
}