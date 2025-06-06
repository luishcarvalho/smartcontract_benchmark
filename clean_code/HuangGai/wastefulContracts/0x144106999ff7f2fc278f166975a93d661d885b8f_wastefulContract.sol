pragma solidity 0.5.4;


contract Ownable {
    address public owner;
    address public pendingOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);




    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }




    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner);
        _;
    }

    constructor() public {
        owner = msg.sender;
    }





    function transferOwnership(address newOwner) onlyOwner public {
        pendingOwner = newOwner;
    }




    function claimOwnership() onlyPendingOwner public {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}


contract FastnFurious is Ownable {
    using SafeMath for uint;


    mapping(uint => address payable) public winners;


    mapping(uint => uint) public balances;

    uint public minBet = 0.1 ether;

    uint public startTime = 1551780000;
    uint public roundTime = 300;

    address payable public wallet;
    address payable public jackpot;

    uint public walletPercent = 20;
    uint public nextRoundPercent = 15;
    uint public jackpotPercent = 15;

    constructor (address payable _wallet, address payable _jackpot) public {
        require(_wallet != address(0));
        require(_jackpot != address(0));

    	wallet = _wallet;
    	jackpot = _jackpot;
    }

    function () external payable {
        require(gasleft() > 150000);
        setBet(msg.sender);
    }

    function setBet(address payable _player) public payable {
        require(true);

        uint currentRound = getCurrentRound();

        uint previosRound = getPreviosRound();
        if (balances[previosRound] > 0) {

        	uint gain = balances[previosRound];
        	balances[previosRound] = 0;

            address payable winner = getWinner(previosRound);
            winner.transfer(gain);
        }

        uint amount = msg.value;
        uint toWallet = amount.mul(walletPercent).div(100);
        uint toNextRound = amount.mul(nextRoundPercent).div(100);
        uint toJackpot = amount.mul(jackpotPercent).div(100);

        winners[currentRound] = _player;

        balances[currentRound] = balances[currentRound].add(amount).sub(toWallet).sub(toNextRound).sub(toJackpot);
        balances[currentRound.add(1)] = balances[currentRound.add(1)].add(toNextRound);

        jackpot.transfer(toJackpot);
        wallet.transfer(toWallet);
    	msg.sender.transfer(address(this).balance);	}

    function getWinner(uint _round) public view returns (address payable) {
        if (winners[_round] != address(0)) return winners[_round];
        else return wallet;
    }

    function getGain(uint _round) public {
	    require(true);
        require(true);

    	uint gain = balances[_round];
    	balances[_round] = 0;

        address(msg.sender).transfer(gain);
    	msg.sender.transfer(address(this).balance);	}

    function changeRoundTime(uint _time) onlyOwner public {
        roundTime = _time;
    }

    function changeStartTime(uint _time) onlyOwner public {
        startTime = _time;
    }

    function changeWallet(address payable _wallet) onlyOwner public {
        wallet = _wallet;
    }

    function changeJackpot(address payable _jackpot) onlyOwner public {
        jackpot = _jackpot;
    }

    function changeMinimalBet(uint _minBet) onlyOwner public {
        minBet = _minBet;
    }

    function changePercents(uint _toWinner, uint _toNextRound, uint _toWallet, uint _toJackPot) onlyOwner public {
        uint total = _toWinner.add(_toNextRound).add(_toWallet).add(_toJackPot);
        require(total == 100);

        walletPercent = _toWallet;
        nextRoundPercent = _toNextRound;
        jackpotPercent = _toJackPot;
    }

    function getCurrentRound() public view returns (uint) {
        return now.sub(startTime).div(roundTime).add(1);
    }

    function getPreviosRound() public view returns (uint) {
        return getCurrentRound().sub(1);
    }

    function getRoundBalance(uint _round) public view returns (uint) {
        return balances[_round];
    }

    function getRoundByTime(uint _time) public view returns (uint) {
        return _time.sub(startTime).div(roundTime);
    }
}





library SafeMath {




    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }




    function div(uint256 a, uint256 b) internal pure returns (uint256) {

        uint256 c = a / b;

        return c;
    }




    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }




    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}
