pragma solidity ^0.5.16;
import "./VBep20Delegate.sol";
contract VDaiDelegate is VBep20Delegate {
    address public daiJoinAddress;
    address public potAddress;
    address public vatAddress;
    function _becomeImplementation(bytes memory data) public {
        require(msg.sender == admin, "only the admin may initialize the implementation");
        (address daiJoinAddress_, address potAddress_) = abi.decode(data, (address, address));
        return _becomeImplementation(daiJoinAddress_, potAddress_);
    }
    function _becomeImplementation(address daiJoinAddress_, address potAddress_) internal {
        DaiJoinLike daiJoin = DaiJoinLike(daiJoinAddress_);
        PotLike pot = PotLike(potAddress_);
        GemLike dai = daiJoin.dai();
        VatLike vat = daiJoin.vat();
        require(address(dai) == underlying, "DAI must be the same as underlying");
        daiJoinAddress = daiJoinAddress_;
        potAddress = potAddress_;
        vatAddress = address(vat);
        dai.approve(daiJoinAddress, uint(-1));
        vat.hope(potAddress);
        vat.hope(daiJoinAddress);
        pot.drip();
        doTransferIn(address(this), 0);
    }
    function _resignImplementation() public {
        require(msg.sender == admin, "only the admin may abandon the implementation");
        DaiJoinLike daiJoin = DaiJoinLike(daiJoinAddress);
        PotLike pot = PotLike(potAddress);
        VatLike vat = VatLike(vatAddress);
        pot.drip();
        uint pie = pot.pie(address(this));
        pot.exit(pie);
        uint bal = vat.dai(address(this));
        daiJoin.exit(address(this), bal / RAY);
    }
    function accrueInterest() public returns (uint) {
        PotLike(potAddress).drip();
        return super.accrueInterest();
    }
    function getCashPrior() internal view returns (uint) {
        PotLike pot = PotLike(potAddress);
        uint pie = pot.pie(address(this));
        return mul(pot.chi(), pie) / RAY;
    }
    function doTransferIn(address from, uint amount) internal returns (uint) {
        EIP20Interface token = EIP20Interface(underlying);
        require(token.transferFrom(from, address(this), amount), "unexpected EIP-20 transfer in return");
        DaiJoinLike daiJoin = DaiJoinLike(daiJoinAddress);
        GemLike dai = GemLike(underlying);
        PotLike pot = PotLike(potAddress);
        VatLike vat = VatLike(vatAddress);
        daiJoin.join(address(this), dai.balanceOf(address(this)));
        uint bal = vat.dai(address(this));
        uint pie = bal / pot.chi();
        pot.join(pie);
        return amount;
    }
    function doTransferOut(address payable to, uint amount) internal {
        DaiJoinLike daiJoin = DaiJoinLike(daiJoinAddress);
        PotLike pot = PotLike(potAddress);
        uint pie = add(mul(amount, RAY) / pot.chi(), 1);
        pot.exit(pie);
        daiJoin.exit(to, amount);
    }
    uint256 constant RAY = 10 ** 27;
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "add-overflow");
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "mul-overflow");
    }
}
interface PotLike {
    function chi() external view returns (uint);
    function pie(address) external view returns (uint);
    function drip() external returns (uint);
    function join(uint) external;
    function exit(uint) external;
}
interface GemLike {
    function approve(address, uint) external;
    function balanceOf(address) external view returns (uint);
    function transferFrom(address, address, uint) external returns (bool);
}
interface VatLike {
    function dai(address) external view returns (uint);
    function hope(address) external;
}
interface DaiJoinLike {
    function vat() external returns (VatLike);
    function dai() external returns (GemLike);
    function join(address, uint) external payable;
    function exit(address, uint) external;
}