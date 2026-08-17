pragma solidity ^0.4.24;
import "zos-lib/contracts/Initializable.sol";
import "openzeppelin-eth/contracts/token/ERC20/ERC20Detailed.sol";
import "tpl-contracts-eth/contracts/token/TPLRestrictedReceiverToken.sol";
import "./PropsSidechainCompatible.sol";
contract PropsToken is Initializable, TPLRestrictedReceiverToken, ERC20Detailed, PropsSidechainCompatible {
  function initialize(
    address _holder,
    AttributeRegistryInterface _jurisdictionAddress,
    uint256 _validRecipientAttributeId
  )
    initializer
    public
  {
    uint8 decimals = 18;
    uint256 totalSupply = 1e9 * (10 ** uint256(decimals));
    ERC20Detailed.initialize("DEV_Token", "DEV_TOKEN", decimals);
    TPLRestrictedReceiverToken.initialize(_jurisdictionAddress, _validRecipientAttributeId);
    _mint(_holder, totalSupply);
  }
}