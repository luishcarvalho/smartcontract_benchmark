



pragma solidity ^0.4.11;




library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {

    uint c = a / b;

    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }


  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}







contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}





contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function allowance(address owner, address spender) constant returns (uint);

  function transfer(address to, uint value) returns (bool ok);
  function transferFrom(address from, address to, uint value) returns (bool ok);
  function approve(address spender, uint value) returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}




contract FractionalERC20 is ERC20 {

  uint public decimals;

}





contract StandardToken is ERC20 {

  using SafeMath for uint;



























































































  function mint(address receiver, uint amount) onlyMintAgent canMint public {

    if(amount == 0) {
      throw;
    }

    totalSupply = totalSupply.add(amount);
    balances[receiver] = balances[receiver].add(amount);
    Transfer(0, receiver, amount);
  }




  function setMintAgent(address addr, bool state) onlyOwner canMint public {
    mintAgents[addr] = state;
    MintingAgentChanged(addr, state);
  }

  modifier onlyMintAgent() {

    if(!mintAgents[msg.sender]) {
        throw;
    }
    _;
  }











contract ReleasableToken is ERC20, Ownable {













  modifier canTransfer(address _sender) {

    if(!released) {
        if(!transferAgents[_sender]) {
            throw;
        }
    }

    _;
  }

  function setReleaseAgent(address addr) onlyOwner inReleaseState(false) public {


    releaseAgent = addr;
  }

  function setTransferAgent(address addr, bool state) onlyOwner inReleaseState(false) public {
    transferAgents[addr] = state;
  }

  function releaseTokenTransfer() public onlyReleaseAgent {
    released = true;
  }













































  event Upgrade(address indexed _from, address indexed _to, uint256 _value);




  event UpgradeAgentSet(address agent);




  function UpgradeableToken(address _upgradeMaster) {
    upgradeMaster = _upgradeMaster;
  }




  function upgrade(uint256 value) public {

      UpgradeState state = getUpgradeState();
      if(!(state == UpgradeState.ReadyToUpgrade || state == UpgradeState.Upgrading)) {

        throw;
      }


      if (value == 0) throw;

      balances[msg.sender] = balances[msg.sender].sub(value);


      totalSupply = totalSupply.sub(value);
      totalUpgraded = totalUpgraded.add(value);


      upgradeAgent.upgradeFrom(msg.sender, value);
      Upgrade(msg.sender, upgradeAgent, value);
  }





  function setUpgradeAgent(address agent) external {

      if(!canUpgrade()) {

        throw;
      }

      if (agent == 0x0) throw;

      if (msg.sender != upgradeMaster) throw;

      if (getUpgradeState() == UpgradeState.Upgrading) throw;

      upgradeAgent = UpgradeAgent(agent);


      if(!upgradeAgent.isUpgradeAgent()) throw;

      if (upgradeAgent.originalSupply() != totalSupply) throw;

      UpgradeAgentSet(upgradeAgent);
  }




  function getUpgradeState() public constant returns(UpgradeState) {
    if(!canUpgrade()) return UpgradeState.NotAllowed;
    else if(address(upgradeAgent) == 0x00) return UpgradeState.WaitingForAgent;
    else if(totalUpgraded == 0) return UpgradeState.ReadyToUpgrade;
    else return UpgradeState.Upgrading;
  }






  function setUpgradeMaster(address master) public {
      if (master == 0x0) throw;
      if (msg.sender != upgradeMaster) throw;
      upgradeMaster = master;
  }




  function canUpgrade() public constant returns(bool) {
     return true;
  }

}

contract CrowdsaleToken is ReleasableToken, MintableToken, UpgradeableToken {

  event UpdatedTokenInformation(string newName, string newSymbol);

  string public name;

  string public symbol;

  uint public decimals;






  function CrowdsaleToken(string _name, string _symbol, uint _initialSupply, uint _decimals, bool _mintable)
    UpgradeableToken(msg.sender) {




    owner = msg.sender;

    name = _name;
    symbol = _symbol;

    totalSupply = _initialSupply;

    decimals = _decimals;


    balances[owner] = totalSupply;

    if(totalSupply > 0) {
      Minted(owner, totalSupply);
    }


    if(!_mintable) {
      mintingFinished = true;
      if(totalSupply == 0) {
        throw;
      }
    }

  }




  function releaseTokenTransfer() public onlyReleaseAgent {
    mintingFinished = true;
    super.releaseTokenTransfer();
  }




  function canUpgrade() public constant returns(bool) {
    return released && super.canUpgrade();
  }




  function setTokenInformation(string _name, string _symbol) onlyOwner {
    name = _name;
    symbol = _symbol;

    UpdatedTokenInformation(name, symbol);
  }

}

contract TapcoinToken is CrowdsaleToken {
  function TapcoinToken(string _name, string _symbol, uint _initialSupply, uint _decimals, bool _mintable)
   CrowdsaleToken(_name, _symbol, _initialSupply, _decimals, _mintable) {
  }
}

contract UpgradeAgent {

  uint public originalSupply;









