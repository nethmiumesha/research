pragma solidity 0.8.4;
import "../interfaces/IERC721.sol";
contract ERC721ReceiverMock {
  bytes4 constant internal ERC721_RECEIVED_SIG = 0x150b7a02;
  bytes4 constant internal ERC721_RECEIVED_INVALID = 0xdeadbeef;
  bytes4 constant internal IS_ERC721_RECEIVER = 0x150b7a02;
  bool public shouldReject;
  bytes public lastData;
  address public lastOperator;
  uint256 public lastId;
  uint256 public lastValue;
  event TransferReceiver(address _from, address _to, uint256 _fromBalance, uint256 _toBalance, address _tokenOwner);
  function supportsInterface(bytes4 interfaceID)
      external
      pure
      returns (bool)
  {
      return  interfaceID == 0x01ffc9a7 ||
          interfaceID == IS_ERC721_RECEIVER;
  }
  function onERC721Received(
      address,
      address _from,
      uint256 _tokenId,
      bytes memory _data
  )
      public
      returns(bytes4)
  {
      uint256 fromBalance = IERC721(msg.sender).balanceOf(_from);
      uint256 toBalance = IERC721(msg.sender).balanceOf(address(this));
      address tokenOwner = IERC721(msg.sender).ownerOf(_tokenId);
      emit TransferReceiver(_from, address(this), fromBalance, toBalance, tokenOwner);
      if (_data.length != 0) {
          require(
              keccak256(_data) == keccak256(abi.encodePacked("Hello from the other side")),
              "ERC721ReceiverMock#onERC721Received: UNEXPECTED_DATA"
          );
      }
      if (shouldReject == true) {
          return ERC721_RECEIVED_INVALID;
      } else {
          return ERC721_RECEIVED_SIG;
      }
  }
  function setShouldReject(bool _value)
      public
  {
      shouldReject = _value;
  }
}