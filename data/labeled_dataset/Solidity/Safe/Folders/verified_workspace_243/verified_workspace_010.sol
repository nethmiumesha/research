pragma solidity 0.4.25;
interface ITransferProxy {
    function transfer(
        address _token,
        uint256 _quantity,
        address _from,
        address _to
    )
        external;
    function batchTransfer(
        address[] _tokens,
        uint256[] _quantities,
        address _from,
        address _to
    )
        external;
}