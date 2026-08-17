  pragma solidity ^0.4.0;
  contract ConstitutionalDNA {
      struct Person{
          address addr;
          bytes name;
          bytes role;
          uint rank;
      }
      bool onceFlag = false;
      bool isRatified = false;
      address home = 0x0;
      address[]foundingTeamAddresses;
      mapping (address => Person) public foundingTeam;
      mapping(address => bool) mutify;
      uint ratifyCount;
      function ConstitutionalDNA(){
          foundingTeam[msg.sender].addr = msg.sender;
          foundingTeam[msg.sender].role = "Founder";
          foundingTeam[msg.sender].rank = 1;
          foundingTeamAddresses.push(msg.sender);
      }
      struct Articles {
          bytes article;
          uint articleNum;
          uint itemNums;
          bytes[] items;
          bool amendable;
          bool set;
      }
      uint articleNumbers = 0;
      Articles[] public constitutionalArticles;
      event ArticleAddedEvent(uint indexed articleId, bytes articleHeading, bool amendable);
      event ArticleItemAddedEvent(uint indexed articleId, uint indexed itemId, bytes itemText);
      event ArticleAmendedEvent(uint indexed articleId, uint indexed itemId, bytes newItemText);
      event ProfileUpdateEvent(address profileAddress, bytes profileName);
      event FoundingTeamSetEvent(address[] foundingTeam, uint[] ranks);
      event HomeSetEvent(address home);
      function addArticle(bytes _article, bool _amendable) external
          founderCheck
          ratified
          homeIsSet
      {
          constitutionalArticles.length = articleNumbers+1;
          constitutionalArticles[articleNumbers].article = _article;
          constitutionalArticles[articleNumbers].articleNum = articleNumbers;
          constitutionalArticles[articleNumbers].amendable = _amendable;
          constitutionalArticles[articleNumbers].set = true;
          ArticleAddedEvent(articleNumbers, _article, _amendable);
          articleNumbers++;
      }
      function addArticleItem(uint _articleNum, bytes _itemText) external
          founderCheck
          articleSet(_articleNum)
          ratified
          homeIsSet
      {
          uint itemId = constitutionalArticles[_articleNum].itemNums;
          constitutionalArticles[_articleNum].items.length = itemId+1;
          constitutionalArticles[_articleNum].items[itemId] = _itemText;
          constitutionalArticles[_articleNum].itemNums++;
          ArticleItemAddedEvent(_articleNum, itemId, _itemText);
      }
      function amendArticleItem(uint _articleNum, uint _item, bytes _textChange)
          articleSet(_articleNum)
          updaterCheck
          amendable(_articleNum)
      {
          constitutionalArticles[_articleNum].items[_item] = _textChange;
          ArticleAmendedEvent(_articleNum, _item, _textChange);
      }
      function getArticleItem(uint _articleNum, uint _item) public constant returns (bytes article, uint articleNum, bool amendible, bytes itemText)
      {
          return (
              constitutionalArticles[_articleNum].article,
              constitutionalArticles[_articleNum].articleNum,
              constitutionalArticles[_articleNum].amendable,
              constitutionalArticles[_articleNum].items[_item]
          );
      }
      function initializedRatify()
          external
          foundingTeamCheck
          foundationNotSet
          mutifyAlreadySet
          returns (bool success)
      {
          if (ratifyCount == foundingTeamAddresses.length)
          {
              isRatified = true;
              return true;
          }
          else
          {
              mutify[msg.sender] == true;
              ratifyCount++;
              return false;
          }
      }
      function setFoundingTeam(uint[] _founderRanks, address[] _founderAddrs)
          external
          founderCheck
          foundingTeamListHasFounder(_founderRanks,_founderAddrs)
          foundingTeamMatchRank(_founderRanks,_founderAddrs)
      {
          for(uint i = 1; i <_founderRanks.length; i++)
          {
              foundingTeamAddresses.push(_founderAddrs[i]);
              foundingTeam[_founderAddrs[i]].addr = _founderAddrs[i];
              foundingTeam[_founderAddrs[i]].rank = _founderRanks[i];
          }
          FoundingTeamSetEvent(_founderAddrs, _founderRanks);
      }
      function updateProfile(address _addr, bytes _profileName)
          foundingTeamCheck
      {
          foundingTeam[_addr].addr = _addr;
          foundingTeam[msg.sender].name = _profileName;
          ProfileUpdateEvent(_addr, _profileName);
      }
      function setHome (address _consensusX)
          founderCheck
          once
      {
          home = _consensusX;
          HomeSetEvent(home);
      }
      modifier founderCheck()  {
          var (tempAddr, tempRank) = (foundingTeam[msg.sender].addr, foundingTeam[msg.sender].rank);
          if(tempAddr != msg.sender || tempRank != 1 ) throw;
          _;
      }
      modifier foundationNotSet(){
          if(foundingTeam[msg.sender].rank != 1 && mutify[foundingTeamAddresses[0]] == false) throw;
          _;
      }
      modifier mutifyAlreadySet(){
          if (mutify[msg.sender] == true) throw;
          _;
      }
      modifier foundingTeamCheck(){
          if(msg.sender != foundingTeam[msg.sender].addr) throw;
          _;
      }
      modifier articleSet(uint _articleNumber){
          if(constitutionalArticles[_articleNumber].set != true) throw;
          _;
      }
      modifier updaterCheck(){
          if (msg.sender != home) throw;
          _;
      }
      modifier once(){
          if (onceFlag == true) throw;
          onceFlag = true;
          _;
      }
      modifier amendable(uint _articleNum){
          if (constitutionalArticles[_articleNum].amendable == false) throw;
          _;
      }
      modifier homeIsSet(){
          if (home == 0x0) throw;
          _;
      }
      modifier ratified(){
          if (foundingTeam[msg.sender].rank == 1 && isRatified == true) throw;
          _;
      }
      modifier foundingTeamMatchRank(uint[] _founderRanks,address[] _founderAddrs){
          if(_founderRanks.length != _founderAddrs.length) throw;
          _;
      }
      modifier foundingTeamListHasFounder(uint[] _founderRanks,address[] _founderAddrs){
          if(_founderAddrs[0] != foundingTeamAddresses[0] || _founderRanks[0] != 1) throw;
          _;
      }
      function (){
          throw;
      }
  }