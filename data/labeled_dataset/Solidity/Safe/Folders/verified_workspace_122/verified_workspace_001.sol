pragma solidity 0.8.5;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./BlocksStaking.sol";
contract BlocksRewardsManager is Ownable {
    struct UserInfo {
        uint256 amount;
        uint256 pendingRewards;
        uint256 rewardsDebt;
    }
    struct SpaceInfo {
        uint256 spaceId;
        uint256 amountOfBlocksBought;
        address contractAddress;
        uint256 blsPerBlockAreaPerBlock;
        uint256 blsRewardsAcc;
        uint256 blsRewardsAccLastUpdated;
    }
    uint256 constant MAX_TREASURY_FEE = 5;
    uint256 constant MAX_LIQUIDITY_FEE = 10;
    uint256 constant MAX_PREVIOUS_OWNER_FEE = 50;
    uint256 public treasuryFee = 5;
    uint256 public liquidityFee = 10;
    uint256 public previousOwnerFee = 25;
    address payable public treasury;
    IERC20 public blsToken;
    BlocksStaking public blocksStaking;
    SpaceInfo[] public spaceInfo;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    mapping(address => uint256) public spaceIdMapping;
    uint256 public blsPerBlock;
    uint256 public blsLastRewardsBlock;
    uint256 public blsSpacesRewardsDebt;
    uint256 public blsSpacesDebtLastUpdatedBlock;
    uint256 public blsSpacesRewardsClaimed;
    event SpaceAdded(uint256 indexed spaceId, address indexed space, address indexed addedBy);
    event Claim(address indexed user, uint256 amount);
    event BlsPerBlockAreaPerBlockUpdated(uint256 spaceId, uint256 newAmount);
    event TreasuryFeeSet(uint256 newFee);
    event LiquidityFeeSet(uint256 newFee);
    event PreviousOwnerFeeSet(uint256 newFee);
    event BlocksStakingContractUpdated(address add);
    event TreasuryWalletUpdated(address newWallet);
    event BlsRewardsForDistributionDeposited(uint256 amount);
    constructor(IERC20 blsAddress_, address blocksStakingAddress_, address treasury_) {
        blsToken = IERC20(blsAddress_);
        blocksStaking = BlocksStaking(blocksStakingAddress_);
        treasury = payable(treasury_);
    }
    function spacesLength() external view returns (uint256) {
        return spaceInfo.length;
    }
    function addSpace(address spaceContract_, uint256 blsPerBlockAreaPerBlock_) external onlyOwner {
        require(spaceIdMapping[spaceContract_] == 0, "Space is already added.");
        require(spaceInfo.length < 20, "Max spaces limit reached.");
        uint256 spaceId = spaceInfo.length;
        spaceIdMapping[spaceContract_] = spaceId + 1;
        SpaceInfo storage newSpace = spaceInfo.push();
        newSpace.contractAddress = spaceContract_;
        newSpace.spaceId = spaceId;
        newSpace.blsPerBlockAreaPerBlock = blsPerBlockAreaPerBlock_;
        emit SpaceAdded(spaceId, spaceContract_, msg.sender);
    }
    function updateBlsPerBlockAreaPerBlock(uint256 spaceId_, uint256 newAmount_) external onlyOwner {
        SpaceInfo storage space = spaceInfo[spaceId_];
        require(space.contractAddress != address(0), "SpaceInfo does not exist");
        massUpdateSpaces();
        uint256 oldSpaceBlsPerBlock = space.blsPerBlockAreaPerBlock * space.amountOfBlocksBought;
        uint256 newSpaceBlsPerBlock = newAmount_ * space.amountOfBlocksBought;
        blsPerBlock = blsPerBlock + newSpaceBlsPerBlock - oldSpaceBlsPerBlock;
        space.blsPerBlockAreaPerBlock = newAmount_;
        recalculateLastRewardBlock();
        emit BlsPerBlockAreaPerBlockUpdated(spaceId_, newAmount_);
    }
    function pendingBlsTokens(uint256 spaceId_, address user_) public view returns (uint256) {
        SpaceInfo storage space = spaceInfo[spaceId_];
        UserInfo storage user = userInfo[spaceId_][user_];
        uint256 rewards;
        if (user.amount > 0 && space.blsRewardsAccLastUpdated < block.number) {
            uint256 multiplier = getMultiplier(space.blsRewardsAccLastUpdated);
            uint256 blsRewards = multiplier * space.blsPerBlockAreaPerBlock;
            rewards = user.amount * blsRewards;
        }
        return user.amount * space.blsRewardsAcc + rewards + user.pendingRewards - user.rewardsDebt;
    }
    function getMultiplier(uint256 lastRewardCalcBlock) internal view returns (uint256) {
        if (block.number > blsLastRewardsBlock) {
            if(blsLastRewardsBlock >= lastRewardCalcBlock){
                return blsLastRewardsBlock - lastRewardCalcBlock;
            }else{
                return 0;
            }
        } else {
            return block.number - lastRewardCalcBlock;
        }
    }
    function massUpdateSpaces() public {
        uint256 length = spaceInfo.length;
        for (uint256 spaceId = 0; spaceId < length; ++spaceId) {
            updateSpace(spaceId);
        }
        updateManagerState();
    }
    function updateManagerState() internal {
        blsSpacesRewardsDebt = blsSpacesRewardsDebt + getMultiplier(blsSpacesDebtLastUpdatedBlock) * blsPerBlock;
        blsSpacesDebtLastUpdatedBlock = block.number;
    }
    function updateSpace(uint256 spaceId_) internal {
        SpaceInfo storage space = spaceInfo[spaceId_];
        if (block.number <= space.blsRewardsAccLastUpdated) {
            return;
        }
        if (space.amountOfBlocksBought == 0) {
            space.blsRewardsAccLastUpdated = block.number;
            return;
        }
        if (block.number > space.blsRewardsAccLastUpdated) {
            uint256 multiplierSpace = getMultiplier(space.blsRewardsAccLastUpdated);
            space.blsRewardsAcc = space.blsRewardsAcc + multiplierSpace * space.blsPerBlockAreaPerBlock;
            space.blsRewardsAccLastUpdated = block.number;
        }
    }
    function blocksAreaBoughtOnSpace(
        address buyer_,
        address[] calldata previousBlockOwners_,
        uint256[] calldata previousOwnersPrices_
    ) external payable {
        uint256 spaceId_ = spaceIdMapping[msg.sender];
        require(spaceId_ > 0, "Call not from BlocksSpace");
        spaceId_ = spaceId_ - 1;
        updateSpace(spaceId_);
        SpaceInfo storage space = spaceInfo[spaceId_];
        UserInfo storage user = userInfo[spaceId_][buyer_];
        uint256 spaceBlsRewardsAcc = space.blsRewardsAcc;
        if (user.amount > 0) {
            user.pendingRewards = pendingBlsTokens(spaceId_, buyer_);
        }
        uint256 numberOfBlocksAddedToSpace;
        uint256 allPreviousOwnersPaid;
        {
            uint256 numberOfBlocksBought = previousBlockOwners_.length;
            uint256 numberOfBlocksToRemove;
            for (uint256 i = 0; i < numberOfBlocksBought; ++i) {
                if (previousBlockOwners_[i] != address(0)) {
                    allPreviousOwnersPaid = allPreviousOwnersPaid + previousOwnersPrices_[i];
                    UserInfo storage prevUser = userInfo[spaceId_][previousBlockOwners_[i]];
                    prevUser.pendingRewards = pendingBlsTokens(spaceId_, previousBlockOwners_[i]);
                    --prevUser.amount;
                    prevUser.rewardsDebt = prevUser.amount * spaceBlsRewardsAcc;
                    ++numberOfBlocksToRemove;
                }
            }
            numberOfBlocksAddedToSpace = numberOfBlocksBought - numberOfBlocksToRemove;
            user.amount = user.amount + numberOfBlocksBought;
            user.rewardsDebt = user.amount * spaceBlsRewardsAcc;
        }
        if (numberOfBlocksAddedToSpace > 0) {
            updateManagerState();
            blsPerBlock = blsPerBlock + space.blsPerBlockAreaPerBlock * numberOfBlocksAddedToSpace;
            space.amountOfBlocksBought = space.amountOfBlocksBought + numberOfBlocksAddedToSpace;
            recalculateLastRewardBlock();
        }
        (uint256 rewardToForward, uint256[] memory prevOwnersRewards) = calculateAndDistributeFees(
            msg.value,
            previousOwnersPrices_,
            allPreviousOwnersPaid
        );
        blocksStaking.distributeRewards{value: rewardToForward}(previousBlockOwners_, prevOwnersRewards);
    }
    function calculateAndDistributeFees(
        uint256 rewardReceived_,
        uint256[] calldata previousOwnersPrices_,
        uint256 previousOwnersPaid_
    ) internal returns (uint256, uint256[] memory) {
        uint256 numberOfBlocks = previousOwnersPrices_.length;
        uint256 feesTaken;
        uint256 previousOwnersFeeValue;
        uint256[] memory previousOwnersRewardWei = new uint256[](numberOfBlocks);
        if (previousOwnerFee > 0 && previousOwnersPaid_ != 0) {
            previousOwnersFeeValue = (rewardReceived_ * previousOwnerFee) / 100;
            uint256 onePartForPreviousOwners = (previousOwnersFeeValue * 1e9) / previousOwnersPaid_;
            for (uint256 i = 0; i < numberOfBlocks; ++i) {
                previousOwnersRewardWei[i] = (onePartForPreviousOwners * previousOwnersPrices_[i]) / 1e9;
            }
        }
        if (treasuryFee > 0) {
            uint256 treasuryFeeValue = (rewardReceived_ * treasuryFee) / 100;
            if (treasuryFeeValue > 0) {
                feesTaken = feesTaken + treasuryFeeValue;
            }
        }
        if (liquidityFee > 0) {
            uint256 liquidityFeeValue = (rewardReceived_ * liquidityFee) / 100;
            if (liquidityFeeValue > 0) {
                feesTaken = feesTaken + liquidityFeeValue;
            }
        }
        if (feesTaken > 0) {
            (bool sent,) = treasury.call{value: feesTaken}("");
            require(sent, "Failed to send moneyz");
        }
        return (rewardReceived_ - feesTaken, previousOwnersRewardWei);
    }
    function claim(uint256 spaceId_) external {
        updateSpace(spaceId_);
        UserInfo storage user = userInfo[spaceId_][msg.sender];
        uint256 toClaimAmount = pendingBlsTokens(spaceId_, msg.sender);
        if (toClaimAmount > 0) {
            uint256 claimedAmount = safeBlsTransfer(msg.sender, toClaimAmount);
            emit Claim(msg.sender, claimedAmount);
            user.pendingRewards = toClaimAmount - claimedAmount;
            user.rewardsDebt = spaceInfo[spaceId_].blsRewardsAcc * user.amount;
            blsSpacesRewardsClaimed = blsSpacesRewardsClaimed + claimedAmount;
        }
    }
    function safeBlsTransfer(address to_, uint256 amount_) internal returns (uint256) {
        uint256 blsBalance = blsToken.balanceOf(address(this));
        if (amount_ > blsBalance) {
            blsToken.transfer(to_, blsBalance);
            return blsBalance;
        } else {
            blsToken.transfer(to_, amount_);
            return amount_;
        }
    }
    function setTreasuryFee(uint256 newFee_) external onlyOwner {
        require(newFee_ <= MAX_TREASURY_FEE);
        treasuryFee = newFee_;
        emit TreasuryFeeSet(newFee_);
    }
    function setLiquidityFee(uint256 newFee_) external onlyOwner {
        require(newFee_ <= MAX_LIQUIDITY_FEE);
        liquidityFee = newFee_;
        emit LiquidityFeeSet(newFee_);
    }
    function setPreviousOwnerFee(uint256 newFee_) external onlyOwner {
        require(newFee_ <= MAX_PREVIOUS_OWNER_FEE);
        previousOwnerFee = newFee_;
        emit PreviousOwnerFeeSet(newFee_);
    }
    function updateBlocksStakingContract(address address_) external onlyOwner {
        blocksStaking = BlocksStaking(address_);
        emit BlocksStakingContractUpdated(address_);
    }
    function updateTreasuryWallet(address newWallet_) external onlyOwner {
        treasury = payable(newWallet_);
        emit TreasuryWalletUpdated(newWallet_);
    }
    function depositBlsRewardsForDistribution(uint256 amount_) external onlyOwner {
        blsToken.transferFrom(address(msg.sender), address(this), amount_);
        massUpdateSpaces();
        recalculateLastRewardBlock();
        emit BlsRewardsForDistributionDeposited(amount_);
    }
    function recalculateLastRewardBlock() internal {
        uint256 blsBalance = blsToken.balanceOf(address(this));
        if (blsBalance + blsSpacesRewardsClaimed >= blsSpacesRewardsDebt && blsPerBlock > 0) {
            uint256 blocksTillBlsRunOut = (blsBalance + blsSpacesRewardsClaimed - blsSpacesRewardsDebt) / blsPerBlock;
            blsLastRewardsBlock = block.number + blocksTillBlsRunOut;
        }
    }
}