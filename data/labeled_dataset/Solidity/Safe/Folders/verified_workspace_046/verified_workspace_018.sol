pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;
import "./Permissions.sol";
import "./SchainsInternal.sol";
import "./utils/Precompiled.sol";
import "./utils/FieldOperations.sol";
contract SkaleVerifier is Permissions {
    using Fp2Operations for Fp2Operations.Fp2Point;
    function verify(
        Fp2Operations.Fp2Point calldata signature,
        bytes32 hash,
        uint counter,
        uint hashA,
        uint hashB,
        G2Operations.G2Point calldata publicKey
    )
        external
        view
        returns (bool)
    {
        if (!_checkHashToGroupWithHelper(
            hash,
            counter,
            hashA,
            hashB
            )
        )
        {
            return false;
        }
        uint newSignB;
        if (!(signature.a == 0 && signature.b == 0)) {
            newSignB = Fp2Operations.P.sub((signature.b % Fp2Operations.P));
        } else {
            newSignB = signature.b;
        }
        require(G2Operations.isG1Point(signature.a, newSignB), "Sign not in G1");
        require(G2Operations.isG1Point(hashA, hashB), "Hash not in G1");
        G2Operations.G2Point memory g2 = G2Operations.getG2();
        require(
            G2Operations.isG2(publicKey),
            "Public Key not in G2"
        );
        return Precompiled.bn256Pairing(
            signature.a, newSignB,
            g2.x.b, g2.x.a, g2.y.b, g2.y.a,
            hashA, hashB,
            publicKey.x.b, publicKey.x.a, publicKey.y.b, publicKey.y.a
        );
    }
    function initialize(address newContractsAddress) public override initializer {
        Permissions.initialize(newContractsAddress);
    }
    function _checkHashToGroupWithHelper(
        bytes32 hash,
        uint counter,
        uint hashA,
        uint hashB
    )
        private
        pure
        returns (bool)
    {
        uint xCoord = uint(hash) % Fp2Operations.P;
        xCoord = (xCoord.add(counter)) % Fp2Operations.P;
        uint ySquared = addmod(
            mulmod(mulmod(xCoord, xCoord, Fp2Operations.P), xCoord, Fp2Operations.P),
            3,
            Fp2Operations.P
        );
        if (hashB < Fp2Operations.P.div(2) || mulmod(hashB, hashB, Fp2Operations.P) != ySquared || xCoord != hashA) {
            return false;
        }
        return true;
    }
}