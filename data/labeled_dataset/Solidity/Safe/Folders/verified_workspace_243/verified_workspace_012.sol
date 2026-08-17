pragma solidity 0.4.25;
interface IWhiteList {
    function whiteList(
        address _address
    )
        external
        view
        returns(bool);
    function areValidAddresses(
        address[] _addresses
    )
        external
        view
        returns(bool);
}