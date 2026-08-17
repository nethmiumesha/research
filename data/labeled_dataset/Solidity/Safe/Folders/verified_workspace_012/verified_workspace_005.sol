pragma solidity 0.4.24;
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
contract Whitelist is Ownable {
    mapping(address => bool) public whitelist;
    event AddedBeneficiary(address indexed _beneficiary);
    event RemovedBeneficiary(address indexed _beneficiary);
    function addAddressToWhitelist(address[] _beneficiaries) public onlyOwner {
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            whitelist[_beneficiaries[i]] = true;
            emit AddedBeneficiary(_beneficiaries[i]);
        }
    }
    function addToWhitelist(address _beneficiary) public onlyOwner {
        whitelist[_beneficiary] = true;
        emit AddedBeneficiary(_beneficiary);
    }
    function removeFromWhitelist(address _beneficiary) public onlyOwner {
        whitelist[_beneficiary] = false;
        emit RemovedBeneficiary(_beneficiary);
    }
}