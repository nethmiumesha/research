pragma solidity ^0.5.16;
import "./Owned.sol";
import "./MixinResolver.sol";
import "./Pausable.sol";
import "./Wrapper.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IFeePool.sol";
import "./interfaces/IFlexibleStorage.sol";
import "./interfaces/IWrapperFactory.sol";
contract WrapperFactory is Owned, MixinResolver, IWrapperFactory {
    bytes32 public constant CONTRACT_NAME = "WrapperFactory";
    bytes32 internal constant CONTRACT_FLEXIBLESTORAGE = "FlexibleStorage";
    bytes32 internal constant CONTRACT_SYNTH_SUSD = "SynthsUSD";
    bytes32 internal constant CONTRACT_FEEPOOL = "FeePool";
    uint internal constant WRAPPER_VERSION = 1;
    constructor(address _owner, address _resolver) public Owned(_owner) MixinResolver(_resolver) {}
    function resolverAddressesRequired() public view returns (bytes32[] memory addresses) {
        addresses = new bytes32[](3);
        addresses[0] = CONTRACT_SYNTH_SUSD;
        addresses[1] = CONTRACT_FLEXIBLESTORAGE;
        addresses[2] = CONTRACT_FEEPOOL;
    }
    function synthsUSD() internal view returns (IERC20) {
        return IERC20(requireAndGetAddress(CONTRACT_SYNTH_SUSD));
    }
    function flexibleStorage() internal view returns (IFlexibleStorage) {
        return IFlexibleStorage(requireAndGetAddress(CONTRACT_FLEXIBLESTORAGE));
    }
    function feePool() internal view returns (IFeePool) {
        return IFeePool(requireAndGetAddress(CONTRACT_FEEPOOL));
    }
    function isWrapper(address possibleWrapper) external view returns (bool) {
        return flexibleStorage().getUIntValue(CONTRACT_NAME, bytes32(uint(address(possibleWrapper)))) > 0;
    }
    function feesEscrowed() public view returns (uint) {
        return synthsUSD().balanceOf(address(this));
    }
    function() external payable {
        revert("Contract is not payable");
    }
    function createWrapper(
        IERC20 token,
        bytes32 currencyKey,
        bytes32 synthContractName
    ) external onlyOwner returns (address) {
        Wrapper wrapper = new Wrapper(owner, address(resolver), token, currencyKey, synthContractName);
        wrapper.rebuildCache();
        flexibleStorage().setUIntValue(CONTRACT_NAME, bytes32(uint(address(wrapper))), WRAPPER_VERSION);
        emit WrapperCreated(address(token), currencyKey, address(wrapper));
        return address(wrapper);
    }
    function distributeFees() external {
        uint amountSUSD = feesEscrowed();
        if (amountSUSD > 0) {
            bool success = synthsUSD().transfer(feePool().FEE_ADDRESS(), amountSUSD);
            require(success, "Transfer did not succeed");
        }
    }
    event WrapperCreated(address indexed token, bytes32 indexed currencyKey, address wrapperAddress);
}