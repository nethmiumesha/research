pragma solidity ^0.8.0;
library Counters {
  struct Counter {
    uint8 _type;
    uint256 _value;
  }
  function setType(Counter storage counter, uint8 counterType) internal {
    require(
      counterType == 0 || counterType == 1 || counterType == 2,
      'invalid type'
    );
    counter._type = counterType;
  }
  function current(Counter storage counter) internal view returns (uint256) {
    return counter._value;
  }
  function increment(Counter storage counter) internal {
    unchecked {
      uint256 incAmount = 1;
      if (counter._type != 0) {
        if (counter._value == 0) {
          incAmount = counter._type == 1 ? 1 : 2;
        } else {
          incAmount = 2;
        }
      }
      counter._value += incAmount;
    }
  }
  function decrement(Counter storage counter) internal {
    uint256 value = counter._value;
    require(value > 0, 'Counter: decrement overflow');
    unchecked {
      uint256 decAmount = counter._type == 0 ? 1 : counter._value == 1 ? 1 : 2;
      counter._value = value - decAmount;
    }
  }
  function reset(Counter storage counter) internal {
    counter._value = 0;
  }
}