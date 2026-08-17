pragma solidity 0.4.18;
import "./WalletMainLib.sol";
library WalletAdminLib {
  using WalletMainLib for WalletMainLib.WalletData;
  event LogTransactionConfirmed(bytes32 txid, address sender, uint256 confirmsNeeded);
  event LogOwnerAdded(address newOwner);
  event LogOwnerRemoved(address ownerRemoved);
  event LogOwnerChanged(address from, address to);
  event LogRequirementChange(uint256 newRequired);
  event LogThresholdChange(address token, uint256 newThreshold);
  event LogErrorMsg(uint256 amount, string msg);
  function checkChangeOwnerArgs(uint256 _from, uint256 _to)
           private returns (bool)
  {
    if(_from == 0){
      LogErrorMsg(_from, "Change from address is not an owner");
      return false;
    }
    if(_to != 0){
      LogErrorMsg(_to, "Change to address is an owner");
      return false;
    }
    return true;
  }
  function checkNewOwnerArgs(uint256 _index, uint256 _length, uint256 _max)
           private returns (bool)
  {
    if(_index != 0){
      LogErrorMsg(_index, "New owner already owner");
      return false;
    }
    if((_length + 1) > _max){
      LogErrorMsg(_length, "Too many owners");
      return false;
    }
    return true;
  }
  function checkRemoveOwnerArgs(uint256 _index, uint256 _length, uint256 _min)
           private returns (bool)
  {
    if(_index == 0){
      LogErrorMsg(_index, "Owner removing not an owner");
      return false;
    }
    if(_length - 2 < _min) {
      LogErrorMsg(_index, "Must reduce requiredAdmin first");
      return false;
    }
    return true;
  }
  function checkRequiredChange(uint256 _newRequired, uint256 _length)
           private returns (bool)
  {
    if(_newRequired == 0){
      LogErrorMsg(_newRequired, "Cant reduce to 0");
      return false;
    }
    if(_length - 2 < _newRequired){
      LogErrorMsg(_length, "Making requirement too high");
      return false;
    }
    return true;
  }
  function calcConfirmsNeeded(uint256 _required, uint256 _count) private pure returns (uint256) {
    return _required - _count;
  }
  function changeOwner(WalletMainLib.WalletData storage self,
                       address _from,
                       address _to,
                       bool _confirm,
                       bytes _data)
                       public
                       returns (bool,bytes32)
  {
    bytes32 _id = keccak256("changeOwner",_from,_to);
    uint256 _txIndex = self.transactionInfo[_id].length;
    bool allGood;
    if(msg.sender != address(this)){
      if(!_confirm) {
        allGood = self.revokeConfirm(_id);
        return (allGood,_id);
      } else {
        if(_txIndex == 0 || self.transactionInfo[_id][_txIndex - 1].success){
          require(self.ownerIndex[msg.sender] > 0);
          allGood = checkChangeOwnerArgs(self.ownerIndex[_from], self.ownerIndex[_to]);
          if(!allGood)
            return (false,0);
          self.transactionInfo[_id].length++;
          self.transactionInfo[_id][_txIndex].confirmRequired = self.requiredAdmin;
          self.transactionInfo[_id][_txIndex].day = now / 1 days;
          self.transactions[now / 1 days].push(_id);
        } else {
          _txIndex--;
          allGood = self.checkNotConfirmed(_id, _txIndex);
          if(!allGood)
            return (false,_id);
        }
      }
      self.transactionInfo[_id][_txIndex].confirmedOwners.push(uint256(msg.sender));
      self.transactionInfo[_id][_txIndex].confirmCount++;
    } else {
      _txIndex--;
    }
    if(self.transactionInfo[_id][_txIndex].confirmCount ==
       self.transactionInfo[_id][_txIndex].confirmRequired)
    {
      self.transactionInfo[_id][_txIndex].success = true;
      uint256 i = self.ownerIndex[_from];
      self.ownerIndex[_from] = 0;
      self.owners[i] = _to;
      self.ownerIndex[_to] = i;
      delete self.transactionInfo[_id][_txIndex].data;
      LogOwnerChanged(_from, _to);
    } else {
      if(self.transactionInfo[_id][_txIndex].data.length == 0)
        self.transactionInfo[_id][_txIndex].data = _data;
      uint256 confirmsNeeded = calcConfirmsNeeded(self.transactionInfo[_id][_txIndex].confirmRequired,
                                               self.transactionInfo[_id][_txIndex].confirmCount);
      LogTransactionConfirmed(_id, msg.sender, confirmsNeeded);
    }
    return (true,_id);
	}
  function addOwner(WalletMainLib.WalletData storage self,
                    address _newOwner,
                    bool _confirm,
                    bytes _data)
                    public
                    returns (bool,bytes32)
  {
    bytes32 _id = keccak256("addOwner",_newOwner);
    uint256 _txIndex = self.transactionInfo[_id].length;
    bool allGood;
    if(msg.sender != address(this)){
      require(_newOwner != 0);
      if(!_confirm) {
        allGood = self.revokeConfirm(_id);
        return (allGood,_id);
      } else {
        if(_txIndex == 0 || self.transactionInfo[_id][_txIndex - 1].success){
          require(self.ownerIndex[msg.sender] > 0);
          allGood = checkNewOwnerArgs(self.ownerIndex[_newOwner],
                                      self.owners.length,
                                      self.maxOwners);
          if(!allGood)
            return (false,0);
          self.transactionInfo[_id].length++;
          self.transactionInfo[_id][_txIndex].confirmRequired = self.requiredAdmin;
          self.transactionInfo[_id][_txIndex].day = now / 1 days;
          self.transactions[now / 1 days].push(_id);
        } else {
          _txIndex--;
          allGood = self.checkNotConfirmed(_id, _txIndex);
          if(!allGood)
            return (false,_id);
        }
      }
      self.transactionInfo[_id][_txIndex].confirmedOwners.push(uint256(msg.sender));
      self.transactionInfo[_id][_txIndex].confirmCount++;
    } else {
      _txIndex--;
    }
    if(self.transactionInfo[_id][_txIndex].confirmCount ==
       self.transactionInfo[_id][_txIndex].confirmRequired)
    {
      self.transactionInfo[_id][_txIndex].success = true;
      self.owners.push(_newOwner);
      self.ownerIndex[_newOwner] = self.owners.length - 1;
      delete self.transactionInfo[_id][_txIndex].data;
      LogOwnerAdded(_newOwner);
    } else {
      if(self.transactionInfo[_id][_txIndex].data.length == 0)
        self.transactionInfo[_id][_txIndex].data = _data;
      uint256 confirmsNeeded = calcConfirmsNeeded(self.transactionInfo[_id][_txIndex].confirmRequired,
                                               self.transactionInfo[_id][_txIndex].confirmCount);
      LogTransactionConfirmed(_id, msg.sender, confirmsNeeded);
    }
    return (true,_id);
	}
  function removeOwner(WalletMainLib.WalletData storage self,
                       address _ownerRemoving,
                       bool _confirm,
                       bytes _data)
                       public
                       returns (bool,bytes32)
  {
    bytes32 _id = keccak256("removeOwner",_ownerRemoving);
    uint256 _txIndex = self.transactionInfo[_id].length;
    bool allGood;
    if(msg.sender != address(this)){
      if(!_confirm) {
        allGood = self.revokeConfirm(_id);
        return (allGood,_id);
      } else {
        if(_txIndex == 0 || self.transactionInfo[_id][_txIndex - 1].success){
          require(self.ownerIndex[msg.sender] > 0);
          allGood = checkRemoveOwnerArgs(self.ownerIndex[_ownerRemoving],
                                         self.owners.length,
                                         self.requiredAdmin);
          if(!allGood)
            return (false,0);
          self.transactionInfo[_id].length++;
          self.transactionInfo[_id][_txIndex].confirmRequired = self.requiredAdmin;
          self.transactionInfo[_id][_txIndex].day = now / 1 days;
          self.transactions[now / 1 days].push(_id);
        } else {
          _txIndex--;
          allGood = self.checkNotConfirmed(_id, _txIndex);
          if(!allGood)
            return (false,_id);
        }
      }
      self.transactionInfo[_id][_txIndex].confirmedOwners.push(uint256(msg.sender));
      self.transactionInfo[_id][_txIndex].confirmCount++;
    } else {
      _txIndex--;
    }
    if(self.transactionInfo[_id][_txIndex].confirmCount ==
       self.transactionInfo[_id][_txIndex].confirmRequired)
    {
      self.transactionInfo[_id][_txIndex].success = true;
      self.owners[self.ownerIndex[_ownerRemoving]] = self.owners[self.owners.length - 1];
      self.ownerIndex[self.owners[self.owners.length - 1]] = self.ownerIndex[_ownerRemoving];
      self.ownerIndex[_ownerRemoving] = 0;
      self.owners.length--;
      delete self.transactionInfo[_id][_txIndex].data;
      LogOwnerRemoved(_ownerRemoving);
    } else {
      if(self.transactionInfo[_id][_txIndex].data.length == 0)
        self.transactionInfo[_id][_txIndex].data = _data;
      uint256 confirmsNeeded = calcConfirmsNeeded(self.transactionInfo[_id][_txIndex].confirmRequired,
                                               self.transactionInfo[_id][_txIndex].confirmCount);
      LogTransactionConfirmed(_id, msg.sender, confirmsNeeded);
    }
    return (true,_id);
	}
  function changeRequiredAdmin(WalletMainLib.WalletData storage self,
                               uint256 _requiredAdmin,
                               bool _confirm,
                               bytes _data)
                               public
                               returns (bool,bytes32)
  {
    bytes32 _id = keccak256("changeRequiredAdmin",_requiredAdmin);
    uint256 _txIndex = self.transactionInfo[_id].length;
    if(msg.sender != address(this)){
      bool allGood;
      if(!_confirm) {
        allGood = self.revokeConfirm(_id);
        return (allGood,_id);
      } else {
        if(_txIndex == 0 || self.transactionInfo[_id][_txIndex - 1].success){
          require(self.ownerIndex[msg.sender] > 0);
          allGood = checkRequiredChange(_requiredAdmin, self.owners.length);
          if(!allGood)
            return (false,0);
          self.transactionInfo[_id].length++;
          self.transactionInfo[_id][_txIndex].confirmRequired = self.requiredAdmin;
          self.transactionInfo[_id][_txIndex].day = now / 1 days;
          self.transactions[now / 1 days].push(_id);
        } else {
          _txIndex--;
          allGood = self.checkNotConfirmed(_id, _txIndex);
          if(!allGood)
            return (false,_id);
        }
      }
      self.transactionInfo[_id][_txIndex].confirmedOwners.push(uint256(msg.sender));
      self.transactionInfo[_id][_txIndex].confirmCount++;
    } else {
      _txIndex--;
    }
    if(self.transactionInfo[_id][_txIndex].confirmCount ==
      self.transactionInfo[_id][_txIndex].confirmRequired)
    {
      self.transactionInfo[_id][_txIndex].success = true;
      self.requiredAdmin = _requiredAdmin;
      delete self.transactionInfo[_id][_txIndex].data;
      LogRequirementChange(_requiredAdmin);
    } else {
      if(self.transactionInfo[_id][_txIndex].data.length == 0)
        self.transactionInfo[_id][_txIndex].data = _data;
      uint256 confirmsNeeded = calcConfirmsNeeded(self.transactionInfo[_id][_txIndex].confirmRequired,
                                               self.transactionInfo[_id][_txIndex].confirmCount);
      LogTransactionConfirmed(_id, msg.sender, confirmsNeeded);
    }
    return (true,_id);
	}
  function changeRequiredMajor(WalletMainLib.WalletData storage self,
                               uint256 _requiredMajor,
                               bool _confirm,
                               bytes _data)
                               public
                               returns (bool,bytes32)
  {
    bytes32 _id = keccak256("changeRequiredMajor",_requiredMajor);
    uint256 _txIndex = self.transactionInfo[_id].length;
    if(msg.sender != address(this)){
      bool allGood;
      if(!_confirm) {
        allGood = self.revokeConfirm(_id);
        return (allGood,_id);
      } else {
        if(_txIndex == 0 || self.transactionInfo[_id][_txIndex - 1].success){
          require(self.ownerIndex[msg.sender] > 0);
          allGood = checkRequiredChange(_requiredMajor, self.owners.length);
          if(!allGood)
            return (false,0);
          self.transactionInfo[_id].length++;
          self.transactionInfo[_id][_txIndex].confirmRequired = self.requiredAdmin;
          self.transactionInfo[_id][_txIndex].day = now / 1 days;
          self.transactions[now / 1 days].push(_id);
        } else {
          _txIndex--;
          allGood = self.checkNotConfirmed(_id, _txIndex);
          if(!allGood)
            return (false,_id);
        }
      }
      self.transactionInfo[_id][_txIndex].confirmedOwners.push(uint256(msg.sender));
      self.transactionInfo[_id][_txIndex].confirmCount++;
    } else {
      _txIndex--;
    }
    if(self.transactionInfo[_id][_txIndex].confirmCount ==
       self.transactionInfo[_id][_txIndex].confirmRequired)
    {
      self.transactionInfo[_id][_txIndex].success = true;
      self.requiredMajor = _requiredMajor;
      delete self.transactionInfo[_id][_txIndex].data;
      LogRequirementChange(_requiredMajor);
    } else {
      if(self.transactionInfo[_id][_txIndex].data.length == 0)
        self.transactionInfo[_id][_txIndex].data = _data;
      uint256 confirmsNeeded = calcConfirmsNeeded(self.transactionInfo[_id][_txIndex].confirmRequired,
                                               self.transactionInfo[_id][_txIndex].confirmCount);
      LogTransactionConfirmed(_id, msg.sender, confirmsNeeded);
    }
    return (true,_id);
	}
  function changeRequiredMinor(WalletMainLib.WalletData storage self,
                               uint256 _requiredMinor,
                               bool _confirm,
                               bytes _data)
                               public
                               returns (bool,bytes32)
  {
    bytes32 _id = keccak256("changeRequiredMinor",_requiredMinor);
    uint256 _txIndex = self.transactionInfo[_id].length;
    if(msg.sender != address(this)){
      bool allGood;
      if(!_confirm) {
        allGood = self.revokeConfirm(_id);
        return (allGood,_id);
      } else {
        if(_txIndex == 0 || self.transactionInfo[_id][_txIndex - 1].success){
          require(self.ownerIndex[msg.sender] > 0);
          allGood = checkRequiredChange(_requiredMinor, self.owners.length);
          if(!allGood)
            return (false,0);
          self.transactionInfo[_id].length++;
          self.transactionInfo[_id][_txIndex].confirmRequired = self.requiredAdmin;
          self.transactionInfo[_id][_txIndex].day = now / 1 days;
          self.transactions[now / 1 days].push(_id);
        } else {
          _txIndex--;
          allGood = self.checkNotConfirmed(_id, _txIndex);
          if(!allGood)
            return (false,_id);
        }
      }
      self.transactionInfo[_id][_txIndex].confirmedOwners.push(uint256(msg.sender));
      self.transactionInfo[_id][_txIndex].confirmCount++;
    } else {
      _txIndex--;
    }
    if(self.transactionInfo[_id][_txIndex].confirmCount ==
       self.transactionInfo[_id][_txIndex].confirmRequired)
    {
      self.transactionInfo[_id][_txIndex].success = true;
      self.requiredMinor = _requiredMinor;
      delete self.transactionInfo[_id][_txIndex].data;
      LogRequirementChange(_requiredMinor);
    } else {
      if(self.transactionInfo[_id][_txIndex].data.length == 0)
        self.transactionInfo[_id][_txIndex].data = _data;
      uint256 confirmsNeeded = calcConfirmsNeeded(self.transactionInfo[_id][_txIndex].confirmRequired,
                                               self.transactionInfo[_id][_txIndex].confirmCount);
      LogTransactionConfirmed(_id, msg.sender, confirmsNeeded);
    }
    return (true,_id);
	}
  function changeMajorThreshold(WalletMainLib.WalletData storage self,
                                address _token,
                                uint256 _majorThreshold,
                                bool _confirm,
                                bytes _data)
                                public
                                returns (bool,bytes32)
  {
    bytes32 _id = keccak256("changeMajorThreshold", _token, _majorThreshold);
    uint256 _txIndex = self.transactionInfo[_id].length;
    if(msg.sender != address(this)){
      bool allGood;
      if(!_confirm) {
        allGood = self.revokeConfirm(_id);
        return (allGood,_id);
      } else {
        if(_txIndex == 0 || self.transactionInfo[_id][_txIndex - 1].success){
          require(self.ownerIndex[msg.sender] > 0);
          self.transactionInfo[_id].length++;
          self.transactionInfo[_id][_txIndex].confirmRequired = self.requiredAdmin;
          self.transactionInfo[_id][_txIndex].day = now / 1 days;
          self.transactions[now / 1 days].push(_id);
        } else {
          _txIndex--;
          allGood = self.checkNotConfirmed(_id, _txIndex);
          if(!allGood)
            return (false,_id);
        }
      }
      self.transactionInfo[_id][_txIndex].confirmedOwners.push(uint256(msg.sender));
      self.transactionInfo[_id][_txIndex].confirmCount++;
    } else {
      _txIndex--;
    }
    if(self.transactionInfo[_id][_txIndex].confirmCount ==
       self.transactionInfo[_id][_txIndex].confirmRequired)
    {
      self.transactionInfo[_id][_txIndex].success = true;
      self.majorThreshold[_token] = _majorThreshold;
      delete self.transactionInfo[_id][_txIndex].data;
      LogThresholdChange(_token, _majorThreshold);
    } else {
      if(self.transactionInfo[_id][_txIndex].data.length == 0)
        self.transactionInfo[_id][_txIndex].data = _data;
      uint256 confirmsNeeded = calcConfirmsNeeded(self.transactionInfo[_id][_txIndex].confirmRequired,
                                               self.transactionInfo[_id][_txIndex].confirmCount);
      LogTransactionConfirmed(_id, msg.sender, confirmsNeeded);
    }
    return (true,_id);
	}
}