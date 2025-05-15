import './SafeMath.sol';
import './Ownable.sol';
import './MoedaToken.sol';

pragma solidity ^0.4.8;


contract Crowdsale is Ownable, SafeMath {
    bool public crowdsaleClosed;

    address public wallet;
    MoedaToken public moedaToken;
    uint256 public etherReceived;
    uint256 public totalTokensSold;
    uint256 public startBlock;
    uint256 public endBlock;


    address public presaleWallet;


    uint256 public constant PRESALE_TOKEN_AMOUNT = 5000000 ether;


    uint256 public constant MINIMUM_BUY = 200 finney;


    uint256 public constant TIER1_RATE = 6 finney;
    uint256 public constant TIER2_RATE = 8 finney;
    uint256 public constant TIER3_RATE = 12 finney;


    uint256 public constant TIER1_CAP =  30000 ether;
    uint256 public constant TIER2_CAP =  70000 ether;
    uint256 public constant TIER3_CAP = 130000 ether;

    event Buy(address indexed donor, uint256 amount, uint256 tokenAmount);

    modifier onlyDuringSale() {
        if (crowdsaleClosed) {
            throw;
        }

        if (block.number < startBlock) {
            throw;
        }

        if (block.number >= endBlock) {
            throw;
        }
        _;
    }





    function Crowdsale(address _wallet, uint _startBlock, uint _endBlock) {
        if (_wallet == address(0)) throw;
        if (_startBlock <= block.number) throw;
        if (_endBlock <= _startBlock) throw;

        crowdsaleClosed = false;
        wallet = _wallet;
        moedaToken = new MoedaToken();
        startBlock = _startBlock;
        endBlock = _endBlock;
    }





    function getLimitAndRate(uint256 totalReceived)
    constant returns (uint256, uint256) {
        uint256 limit = 0;
        uint256 rate = 0;

        if (totalReceived < TIER1_CAP) {
            limit = TIER1_CAP;
            rate = TIER1_RATE;
        }
        else if (totalReceived < TIER2_CAP) {
            limit = TIER2_CAP;
            rate = TIER2_RATE;
        }
        else if (totalReceived < TIER3_CAP) {
            limit = TIER3_CAP;
            rate = TIER3_RATE;
        } else {
            throw;
        }

        return (limit, rate);
    }











    function getTokenAmount(uint256 totalReceived, uint256 requestedAmount)
    constant returns (uint256) {
        if (requestedAmount == 0) return 0;
        uint256 limit = 0;
        uint256 rate = 0;
        (limit, rate) = getLimitAndRate(totalReceived);

        uint256 maxETHSpendableInTier = safeSub(limit, totalReceived);
        uint256 amountToSpend = min256(maxETHSpendableInTier, requestedAmount);
        uint256 tokensToReceiveAtCurrentPrice = safeDiv(
            safeMul(amountToSpend, 1 ether), rate);
        uint256 additionalTokens = getTokenAmount(
            safeAdd(totalReceived, amountToSpend),
            safeSub(requestedAmount, amountToSpend));

        return safeAdd(tokensToReceiveAtCurrentPrice, additionalTokens);
    }


    function processBuy() internal returns (bool) {
        if (msg.value < MINIMUM_BUY) throw;
        if (safeAdd(etherReceived, msg.value) > TIER3_CAP) throw;
        if (!wallet.send(msg.value)) throw;

        uint256 tokenAmount = getTokenAmount(etherReceived, msg.value);

        if (!moedaToken.create(msg.sender, tokenAmount)) throw;
        etherReceived = safeAdd(etherReceived, msg.value);
        totalTokensSold = safeAdd(totalTokensSold, tokenAmount);
        Buy(msg.sender, msg.value, tokenAmount);

        return true;
    }


    function () payable onlyDuringSale {
        if (!processBuy()) throw;
    }


    function finalize() onlyOwner {
        if (block.number < startBlock) throw;
        if (crowdsaleClosed) throw;


        if (!moedaToken.create(wallet, PRESALE_TOKEN_AMOUNT)) throw;


        if(!moedaToken.unlock()) throw;
        crowdsaleClosed = true;
    }
}
