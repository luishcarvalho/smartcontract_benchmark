pragma solidity 0.4.19;

import './safeMath.sol';
import './erc20.sol';







contract BBIToken is StandardToken {

    string public name = "Beluga Banking Infrastructure Token";
    string public symbol = "BBI";

    uint  public decimals    = 18;
    uint  public totalUsed   = 0;
    uint  public etherRaised = 0;

    uint  public etherCap    = 30000e18;









    uint public icoEndDate        = 1522540799;

    uint constant SECONDS_IN_YEAR = 31536000;


    bool public halted = false;

    uint  public maxAvailableForSale    =  40000000e18;
    uint  public tokensTeam             =  30000000e18;
    uint  public tokensCommunity        =   5000000e18;
    uint  public tokensMasterNodes      =   5000000e18;
    uint  public tokensBankPartners     =   5000000e18;
    uint  public tokensDataProviders    =   5000000e18;







   uint constant teamInternal = 1;
   uint constant teamPartners = 2;
   uint constant icoInvestors = 3;








    address public addressETHDeposit       = 0xcc85a2948DF9cfd5d06b2C926bA167562844395b;

    address public addressTeam             = 0xB3C28227d2dd0FbF2838FeD192F38669B2169FE8;
    address public addressCommunity        = 0xbDBE59910D8955F62543Cd35830263bE9C8D731D;
    address public addressBankPartners     = 0xBc78914C15E382b9b3697Cd4352556F8da5fE2ae;
    address public addressDataProviders    = 0x940dCDcd42666f18E229fe917C5c706ad2407C67;
    address public addressMasterNodes      = 0xB8686c1085f1F6e877fb52821f63d593ca2E845e;

    address public addressICOManager       = 0xACfF1E8824EFB2739abfE6Ed6c4ed8F697790d06;







    function BBIToken() public {

                     totalSupply_ = 90000000e18 ;

                     balances[addressTeam] = tokensTeam;
                     balances[addressCommunity] = tokensCommunity;
                     balances[addressBankPartners] = tokensBankPartners;
                     balances[addressDataProviders] = tokensDataProviders;
                     balances[addressMasterNodes] = tokensMasterNodes;
                     balances[addressICOManager] = maxAvailableForSale;

                     Transfer(this, addressTeam, tokensTeam);
                     Transfer(this, addressCommunity, tokensCommunity);
                     Transfer(this, addressBankPartners, tokensBankPartners);
                     Transfer(this, addressDataProviders, tokensDataProviders);
                     Transfer(this, addressMasterNodes, tokensMasterNodes);
                     Transfer(this, addressICOManager, maxAvailableForSale);

            }






    function  halt() onlyManager public{
        require(msg.sender == addressICOManager);
        halted = true;
    }

    function  unhalt() onlyManager public {
        require(msg.sender == addressICOManager);
        halted = false;
    }






    modifier onIcoRunning() {

        require( halted == false);
        _;
    }

    modifier onIcoStopped() {

      require( halted == true);
        _;
    }

    modifier onlyManager() {

        require(msg.sender == addressICOManager);
        _;
    }


















    function transfer(address _to, uint256 _value) public returns (bool success)
    {
           if ( msg.sender == addressICOManager) { return super.transfer(_to, _value); }


           if ( !halted && identifyAddress(msg.sender) == icoInvestors && now > icoEndDate ) { return super.transfer(_to, _value); }


           if ( !halted && identifyAddress(msg.sender) == teamInternal && (SafeMath.add(balances[msg.sender], _value) < SafeMath.div(tokensTeam,2) ) && now > SafeMath.add(icoEndDate, SafeMath.div(SECONDS_IN_YEAR,2))) { return super.transfer(_to, _value); }


           if ( !halted && now > SafeMath.add(icoEndDate , SECONDS_IN_YEAR)) { return super.transfer(_to, _value); }

        return false;

    }


    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success)
    {
           if ( msg.sender == addressICOManager) return super.transferFrom(_from,_to, _value);
           if ( !halted && identifyAddress(msg.sender) == icoInvestors && now > icoEndDate ) return super.transferFrom(_from,_to, _value);
           if ( !halted && identifyAddress(msg.sender) == teamInternal && (SafeMath.add(balances[msg.sender], _value) < SafeMath.div(tokensTeam,2)) && now >SafeMath.add(icoEndDate, SafeMath.div(SECONDS_IN_YEAR,2)) ) return super.transferFrom(_from,_to, _value);
           if ( !halted && now > SafeMath.add(icoEndDate, SECONDS_IN_YEAR)) return super.transferFrom(_from,_to, _value);
        return false;
    }

   function identifyAddress(address _buyer) constant public returns(uint) {
        if (_buyer == addressTeam || _buyer == addressCommunity) return teamInternal;
        if (_buyer == addressMasterNodes || _buyer == addressBankPartners || _buyer == addressDataProviders) return teamPartners;
             return icoInvestors;
    }








    function  burn(uint256 _value)  onlyManager public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        totalSupply_ -= _value;
        return true;
    }









    function buyBBITokens(address _buyer, uint256 _value) public {

            require(_buyer != 0x0);


            require(_value > 0);


            require(!halted);


            require(now < icoEndDate);



            uint tokens = (SafeMath.mul(_value, 960));


            require(SafeMath.add(totalUsed, tokens) < balances[addressICOManager]);


            require(SafeMath.add(etherRaised, _value) < etherCap);

            balances[_buyer] = SafeMath.add( balances[_buyer], tokens);
           	balances[addressICOManager] = SafeMath.sub(balances[addressICOManager], tokens);
            totalUsed += tokens;
            etherRaised += _value;

            addressETHDeposit.transfer(_value);
  			Transfer(this, _buyer, tokens );
        }





    function () payable onIcoRunning public {
                buyBBITokens(msg.sender, msg.value);
            }
}
