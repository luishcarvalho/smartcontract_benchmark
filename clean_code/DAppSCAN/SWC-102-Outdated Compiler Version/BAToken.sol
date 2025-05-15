pragma solidity ^0.4.10;
import "./StandardToken.sol";
import "./SafeMath.sol";

contract BAToken is StandardToken, SafeMath {


    string public constant name = "Basic Attention Token";
    string public constant symbol = "BAT";
    uint8 public constant decimals = 18;
    string public version = "0.9";


    address public ethFundDeposit;
    address public batFundDeposit;


    bool public isFunding;
    uint256 public fundingStartBlock;
    uint256 public fundingEndBlock;
    uint256 public batFund = 300 * 10**24;
    uint256 public constant tokenExchangeRate = 4000;
    uint256 public constant tokenCreationCap =  1000 * 10**24;
    uint256 public constant tokenCreationMin =  490 * 10**24;



    event LogRefund(address indexed to, uint256 value);



    function BAToken(
        address _ethFundDeposit,
        address _batFundDeposit,
        uint256 _fundingStartBlock,
        uint256 _fundingEndBlock)
    {
      isFunding = true;
      ethFundDeposit = _ethFundDeposit;
      batFundDeposit = _batFundDeposit;
      fundingStartBlock = _fundingStartBlock;
      fundingEndBlock = _fundingEndBlock;
      totalSupply = batFund;
      balances[batFundDeposit] = batFund;
    }


    function createTokens() payable external {
      if (!isFunding) throw;
      if (block.number < fundingStartBlock) throw;
      if (block.number > fundingEndBlock) throw;
      if (msg.value == 0) throw;
      uint256 tokens = safeMult(msg.value, tokenExchangeRate);
      uint256 tmpSupply = safeAdd(totalSupply, tokens);
      if(tokenCreationCap >= tmpSupply) {
        totalSupply += tokens;
        balances[msg.sender] += tokens;
        Transfer(0, msg.sender, tokens);
      } else {
        throw;
      }
    }


    function finalize() external {
      if (!isFunding) throw;
      if (msg.sender != ethFundDeposit) throw;
      if ((block.number <= fundingEndBlock ||
           totalSupply < tokenCreationMin) &&
          totalSupply < tokenCreationCap) throw;

      isFunding = false;
      if(!ethFundDeposit.send(this.balance)) throw;
    }


    function refund() external {
      if(!isFunding) throw;
      if (block.number <= fundingEndBlock) throw;
      if(totalSupply >= tokenCreationMin) throw;
      var batVal = balances[msg.sender];
      if (batVal == 0) throw;
      balances[msg.sender] = 0;
      totalSupply -= batVal;
      var ethVal = batVal / tokenExchangeRate;
      LogRefund(msg.sender, ethVal);
      if (!msg.sender.send(ethVal)) throw;
    }

}
