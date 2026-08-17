pragma solidity ^0.8.0;
import "../proxy/Initializable.sol";
contract SampleHuman is Initializable {
  bool public isHuman;
  function initialize() public initializer {
    isHuman = true;
  }
}
contract SampleMother is Initializable, SampleHuman {
  uint256 public mother;
  function initialize(uint256 value) public initializer virtual {
    SampleHuman.initialize();
    mother = value;
  }
}
contract SampleGramps is Initializable, SampleHuman {
  string public gramps;
  function initialize(string memory value) public initializer virtual {
    SampleHuman.initialize();
    gramps = value;
  }
}
contract SampleFather is Initializable, SampleGramps {
  uint256 public father;
  function initialize(string memory _gramps, uint256 _father) public initializer {
    SampleGramps.initialize(_gramps);
    father = _father;
  }
}
contract SampleChild is Initializable, SampleMother, SampleFather {
  uint256 public child;
  function initialize(uint256 _mother, string memory _gramps, uint256 _father, uint256 _child) public initializer {
    SampleMother.initialize(_mother);
    SampleFather.initialize(_gramps, _father);
    child = _child;
  }
}