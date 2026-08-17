pragma solidity 0.4.25;
interface IVault {
    function withdrawTo(
        address _token,
        address _to,
        uint256 _quantity
    )
        external;
    function incrementTokenOwner(
        address _token,
        address _owner,
        uint256 _quantity
    )
        external;
    function decrementTokenOwner(
        address _token,
        address _owner,
        uint256 _quantity
    )
        external;
    function transferBalance(
        address _token,
        address _from,
        address _to,
        uint256 _quantity
    )
        external;
    function batchWithdrawTo(
        address[] _tokens,
        address _to,
        uint256[] _quantities
    )
        external;
    function batchIncrementTokenOwner(
        address[] _tokens,
        address _owner,
        uint256[] _quantities
    )
        external;
    function batchDecrementTokenOwner(
        address[] _tokens,
        address _owner,
        uint256[] _quantities
    )
        external;
    function batchTransferBalance(
        address[] _tokens,
        address _from,
        address _to,
        uint256[] _quantities
    )
        external;
    function getOwnerBalance(
        address _token,
        address _owner
    )
        external
        returns (uint256);
}