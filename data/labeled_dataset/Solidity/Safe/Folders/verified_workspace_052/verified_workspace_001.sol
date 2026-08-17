pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "@opengsn/gsn/contracts/forwarder/IForwarder.sol";
contract UmbraForwarder is IForwarder {
  using ECDSA for bytes32;
  receive() external payable {}
  function getNonce(address from) public view override returns (uint256) {
    (from);
    return 0;
  }
  function verify(
    ForwardRequest memory req,
    bytes32 domainSeparator,
    bytes32 requestTypeHash,
    bytes calldata suffixData,
    bytes calldata sig
  ) external view override {
    (req, domainSeparator, requestTypeHash, suffixData, sig);
  }
  function execute(
    ForwardRequest memory req,
    bytes32 domainSeparator,
    bytes32 requestTypeHash,
    bytes calldata suffixData,
    bytes calldata sig
  ) external payable override returns (bool success, bytes memory ret) {
    (domainSeparator, requestTypeHash, suffixData, sig);
    (success, ret) = req.to.call{gas: req.gas, value: req.value}(abi.encodePacked(req.data, req.from));
    if (address(this).balance > 0) {
      payable(req.from).transfer(address(this).balance);
    }
    return (success, ret);
  }
  function registerRequestType(string calldata typeName, string calldata typeSuffix) external override {
    (typeName, typeSuffix);
  }
  function registerDomainSeparator(string calldata name, string calldata version) external override {
    (name, version);
  }
}