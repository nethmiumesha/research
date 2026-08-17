pragma solidity >= 0.5.0 <0.6.0;
import "../../libs/ProofUtils.sol";
contract ProofUtilsTest {
    using ProofUtils for uint24;
    function getProofComponents(uint24 proof) public pure returns (uint8 epoch, uint8 category, uint8 id) {
        return proof.getProofComponents();
    }
}