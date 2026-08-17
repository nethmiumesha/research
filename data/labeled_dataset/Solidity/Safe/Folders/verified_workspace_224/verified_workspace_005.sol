pragma solidity 0.4.23;
import 'zeppelin-solidity/contracts/token/ERC20.sol';
import 'zeppelin-solidity/contracts/math/SafeMath.sol';
contract TestApprovalRecipient {
    using SafeMath for uint256;
    event ReceivedBytesLength(uint length);
    event ReceivedByte(byte b);
    function TestApprovalRecipient(ERC20 token) public {
        m_token = token;
    }
    function receiveApproval(address _sender, uint256 _value, bytes _extraData) public {
        require(msg.sender == address(m_token));
        require(m_token.transferFrom(_sender, address(this), _value));
        m_bonuses[_sender] = m_bonuses[_sender].add(_value);
        ReceivedBytesLength(_extraData.length);
        for (uint i = 0; i < _extraData.length; ++i)
            ReceivedByte(_extraData[i]);
        if (2 == _extraData.length && byte(0x40) == _extraData[0] && byte(0x41) == _extraData[1])
            m_bonuses[_sender] = m_bonuses[_sender].add(_value);
    }
    mapping(address => uint256) public m_bonuses;
    ERC20 private m_token;
}