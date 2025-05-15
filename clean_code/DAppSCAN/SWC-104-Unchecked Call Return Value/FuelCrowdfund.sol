pragma solidity ^0.4.15;

import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import 'zeppelin-solidity/contracts/ownership/Ownable.sol';
import "./helpers/NonZero.sol";

contract FuelToken {
    function transferFromCrowdfund(address _to, uint256 _amount) returns (bool success);
    function finalizeCrowdfund() returns (bool success);
}

contract FuelCrowdfund is NonZero, Ownable {

    using SafeMath for uint;




    address public tokenAddress;

    address public wallet;


    uint256 public weiRaised = 0;

    uint256 public startsAt;

    uint256 public endsAt;


    FuelToken public token;




    event WalletAddressChanged(address _wallet);

    event AmountRaised(address beneficiary, uint amountRaised);

    event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount);




    modifier crowdfundIsActive() {
        assert(now >= startsAt && now <= endsAt);
        _;
    }




    function FuelCrowdfund(address _tokenAddress) {
        wallet = 0x854f7424b2150bb4c3f42f04dd299318f84e98a5;
        startsAt = 1505458800;
        endsAt = 1507852800;
        tokenAddress = _tokenAddress;
        token = FuelToken(tokenAddress);
    }


    function changeWalletAddress(address _wallet) onlyOwner {
        wallet = _wallet;
        WalletAddressChanged(_wallet);
    }




    function buyTokens(address _to) crowdfundIsActive nonZeroAddress(_to) payable {
        uint256 weiAmount = msg.value;
        uint256 tokens = weiAmount * getIcoPrice();
        weiRaised = weiRaised.add(weiAmount);
        wallet.transfer(weiAmount);
        if (!token.transferFromCrowdfund(_to, tokens)) {
            revert();
        }
        TokenPurchase(_to, weiAmount, tokens);
    }


    function closeCrowdfund() external onlyOwner returns (bool success) {
        AmountRaised(wallet, weiRaised);
        token.finalizeCrowdfund();
        return true;
    }




    function getIcoPrice() public constant returns (uint price) {
        if (now > (startsAt + 3 weeks)) {
           return 1275;
        } else if (now > (startsAt + 2 weeks)) {
           return 1700;
        } else if (now > (startsAt + 1 weeks)) {
           return 2250;
        } else {
           return 3000;
        }
    }



    function () payable nonZeroValue {
        buyTokens(msg.sender);
    }
}
