pragma solidity 0.5.13;

import "@openzeppelin/contracts/token/ERC721/ERC721Full.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@nomiclabs/buidler/console.sol";
import "./interfaces/ICash.sol";
import "./interfaces/IRealitio.sol";




contract RealityCards is ERC721Full, Ownable {

    using SafeMath for uint256;







    uint256 public numberOfTokens;



    uint256 private nftMintCount;

    bytes32 public questionId;

    uint256 constant private MAX_ITERATIONS = 10;
    enum States {NFTSNOTMINTED, OPEN, LOCKED, WITHDRAW}
    States public state;


    IRealitio public realitio;
    ICash public cash;



    mapping (uint256 => uint256) public price;

    mapping (uint256 => mapping (address => uint256) ) public deposits;

    mapping (address => uint256) public collectedPerUser;

    mapping (uint256 => uint256) public collectedPerToken;

    uint256 public totalCollected;



    mapping (uint256 => mapping (address => uint256) ) public timeHeld;

    mapping (uint256 => uint256) public totalTimeHeld;

    mapping (uint256 => uint256) public timeLastCollected;

    mapping (uint256 => uint256) public timeAcquired;





    mapping (uint256 => mapping (uint256 => rental) ) public ownerTracker;

    mapping (uint256 => uint256) public currentOwnerIndex;

    struct rental { address owner;
                    uint256 price; }

    mapping (uint256 => address[]) public allOwners;

    mapping (uint256 => mapping (address => bool)) private inAllOwners;


    uint256 public winningOutcome;

    uint32 public marketExpectedResolutionTime;

    bool public questionResolvedInvalid = true;

    mapping (address => bool) public userAlreadyWithdrawn;





    constructor(
        address _owner,
        uint256 _numberOfTokens,
        ICash _addressOfCashContract,
        IRealitio _addressOfRealitioContract,
        uint32 _marketExpectedResolutionTime,
        uint256 _templateId,
        string memory _question,
        address _arbitrator,
        uint32 _timeout)
        ERC721Full("realitycards.io", "RC") public
    {

        transferOwnership(_owner);


        numberOfTokens = _numberOfTokens;
        marketExpectedResolutionTime = _marketExpectedResolutionTime;


        realitio = _addressOfRealitioContract;
        cash = _addressOfCashContract;


        questionId = _postQuestion(_templateId, _question, _arbitrator, _timeout, _marketExpectedResolutionTime, 0);
    }





    event LogNewRental(address indexed newOwner, uint256 indexed newPrice, uint256 indexed tokenId);
    event LogPriceChange(uint256 indexed newPrice, uint256 indexed tokenId);
    event LogForeclosure(address indexed prevOwner, uint256 indexed tokenId);
    event LogRentCollection(uint256 indexed rentCollected, uint256 indexed tokenId);
    event LogReturnToPreviousOwner(uint256 indexed tokenId, address indexed previousOwner);
    event LogDepositWithdrawal(uint256 indexed daiWithdrawn, uint256 indexed tokenId, address indexed returnedTo);
    event LogDepositIncreased(uint256 indexed daiDeposited, uint256 indexed tokenId, address indexed sentBy);
    event LogContractLocked(bool indexed didTheEventFinish);
    event LogWinnerKnown(uint256 indexed winningOutcome);
    event LogWinningsPaid(address indexed paidTo, uint256 indexed amountPaid);
    event LogRentReturned(address indexed returnedTo, uint256 indexed amountReturned);
    event LogTimeHeldUpdated(uint256 indexed newTimeHeld, address indexed owner, uint256 indexed tokenId);






    function mintNfts(string calldata _uri) external checkState(States.NFTSNOTMINTED) {
        _mint(address(this), nftMintCount);
        _setTokenURI(nftMintCount, _uri);
        nftMintCount = nftMintCount.add(1);
        if (nftMintCount == numberOfTokens) {
            _incrementState();
        }
    }





    modifier checkState(States currentState) {
        require(state == currentState, "Incorrect state");
        _;
    }


    modifier tokenExists(uint256 _tokenId) {
        require(_tokenId < numberOfTokens, "This token does not exist");
       _;
    }


    modifier amountNotZero(uint256 _dai) {
        require(_dai > 0, "Amount must be above zero");
       _;
    }


    modifier onlyTokenOwner(uint256 _tokenId) {
        require(msg.sender == ownerOf(_tokenId), "Not owner");
       _;
    }






    function rentOwed(uint256 _tokenId) public view returns (uint256) {
        return price[_tokenId].mul(now.sub(timeLastCollected[_tokenId])).div(1 days);
    }



    function currentOwnerRemainingDeposit(uint256 _tokenId) public view returns (uint256) {
        uint256 _rentOwed = rentOwed(_tokenId);
        address _currentOwner = ownerOf(_tokenId);
        if(_rentOwed >= deposits[_tokenId][_currentOwner]) {
            return 0;
        } else {
            return deposits[_tokenId][_currentOwner].sub(_rentOwed);
        }
    }




    function userRemainingDeposit(uint256 _tokenId) external view returns (uint256) {
        if(ownerOf(_tokenId) == msg.sender) {
            return currentOwnerRemainingDeposit(_tokenId);
        } else {
            return deposits[_tokenId][msg.sender];
        }
    }



    function rentalExpiryTime(uint256 _tokenId) external view returns (uint256) {
        uint256 pps;
        pps = price[_tokenId].div(1 days);

        if (pps == 0) {
            return now;
        }
        else {
            return now + currentOwnerRemainingDeposit(_tokenId).div(pps);
        }
    }


    function getWinnings(uint256 _winningOutcome) public view returns (uint256) {
        uint256 _winnersTimeHeld = timeHeld[_winningOutcome][msg.sender];
        uint256 _numerator = totalCollected.mul(_winnersTimeHeld);
        uint256 _winnings = _numerator.div(totalTimeHeld[_winningOutcome]);
        return _winnings;
    }






    function _sendCash(address _to, uint256 _amount) internal {
        require(cash.transfer(_to,_amount), "Cash transfer failed");
    }


    function _receiveCash(address _from, uint256 _amount) internal {
        require(cash.transferFrom(_from, address(this), _amount), "Cash transfer failed");
    }






    function _postQuestion(uint256 template_id, string memory question, address arbitrator, uint32 timeout, uint32 opening_ts, uint256 nonce) internal returns (bytes32) {
        return realitio.askQuestion(template_id, question, arbitrator, timeout, opening_ts, nonce);
    }




    function _getWinner() internal view returns(uint256) {
        bytes32 _winningOutcome = realitio.resultFor(questionId);
        return uint256(_winningOutcome);
    }


    function _isQuestionFinalized() internal view returns (bool) {
        return realitio.isFinalized(questionId);
    }







    function lockContract() external checkState(States.OPEN) {
        require(marketExpectedResolutionTime < (now - 1 hours), "Market has not finished");

        collectRentAllTokens();
        _incrementState();
        emit LogContractLocked(true);
    }


    function determineWinner() external checkState(States.LOCKED) {
        require(_isQuestionFinalized() == true, "Oracle not resolved");

        winningOutcome = _getWinner();

        if (winningOutcome !=  ((2**256)-1)) {
            questionResolvedInvalid = false;
        }
        _incrementState();
        emit LogWinnerKnown(winningOutcome);
    }


    function withdraw() external checkState(States.WITHDRAW) {
        require(!userAlreadyWithdrawn[msg.sender], "Already withdrawn");
        userAlreadyWithdrawn[msg.sender] = true;
        if (!questionResolvedInvalid) {
            _payoutWinnings();
        } else {
             _returnRent();
        }
    }


    function _payoutWinnings() internal {
        uint256 _winningsToTransfer = getWinnings(winningOutcome);
        require(_winningsToTransfer > 0, "Not a winner");
        _sendCash(msg.sender, _winningsToTransfer);
        emit LogWinningsPaid(msg.sender, _winningsToTransfer);
    }


    function _returnRent() internal {
        uint256 _rentCollected = collectedPerUser[msg.sender];
        require(_rentCollected > 0, "Paid no rent");
        _sendCash(msg.sender, _rentCollected);
        emit LogRentReturned(msg.sender, _rentCollected);
    }






    function withdrawDepositAfterMarketEnded() external {
        require(state != States.NFTSNOTMINTED, "Incorrect state");
        require(state != States.OPEN, "Incorrect state");
        for (uint i = 0; i < numberOfTokens; i++) {

            uint256 _depositToReturn = deposits[i][msg.sender];

            if (_depositToReturn > 0) {
                deposits[i][msg.sender] = 0;
                _sendCash(msg.sender, _depositToReturn);
                emit LogDepositWithdrawal(_depositToReturn, i, msg.sender);
            }
        }
    }








    function collectRentAllTokens() public checkState(States.OPEN) {
       for (uint i = 0; i < numberOfTokens; i++) {
            _collectRent(i);
        }
    }


    function newRental(uint256 _newPrice, uint256 _tokenId, uint256 _deposit) external checkState(States.OPEN) tokenExists(_tokenId) amountNotZero(_deposit) {
        uint256 _currentPricePlusTenPercent = price[_tokenId].mul(11).div(10);
        uint256 _oneHoursDeposit = _newPrice.div(24);
        require(_newPrice >= _currentPricePlusTenPercent, "Price not 10% higher");
        require(_deposit >= _oneHoursDeposit, "One hour's rent minimum");
        require(_newPrice >= 0.01 ether, "Minimum rental 0.01 Dai");

        _collectRent(_tokenId);
        _depositDai(_deposit, _tokenId);

        address _currentOwner = ownerOf(_tokenId);

        if (_currentOwner == msg.sender) {
            _changePrice(_newPrice, _tokenId);
        } else {

            currentOwnerIndex[_tokenId] = currentOwnerIndex[_tokenId].add(1);
            ownerTracker[_tokenId][currentOwnerIndex[_tokenId]].price = _newPrice;
            ownerTracker[_tokenId][currentOwnerIndex[_tokenId]].owner = msg.sender;
            timeAcquired[_tokenId] = now;

            if (!inAllOwners[_tokenId][msg.sender]) {
                inAllOwners[_tokenId][msg.sender] = true;
                allOwners[_tokenId].push(msg.sender);
            }

            _transferTokenTo(_currentOwner, msg.sender, _newPrice, _tokenId);
            emit LogNewRental(msg.sender, _newPrice, _tokenId);
        }
    }






    function depositDai(uint256 _dai, uint256 _tokenId) external checkState(States.OPEN) amountNotZero(_dai) tokenExists(_tokenId) {
        _collectRent(_tokenId);
        _depositDai(_dai, _tokenId);
    }



    function changePrice(uint256 _newPrice, uint256 _tokenId) external checkState(States.OPEN) tokenExists(_tokenId) onlyTokenOwner(_tokenId) {
        require(_newPrice > price[_tokenId], "New price must be higher");
        _collectRent(_tokenId);
        _changePrice(_newPrice, _tokenId);
    }




    function withdrawDeposit(uint256 _daiToWithdraw, uint256 _tokenId) public checkState(States.OPEN) tokenExists(_tokenId) amountNotZero(_daiToWithdraw) {
        _collectRent(_tokenId);
        uint256 _remainingDeposit = deposits[_tokenId][msg.sender];

        if (_remainingDeposit > 0) {
            if (_remainingDeposit < _daiToWithdraw) {
                _daiToWithdraw = _remainingDeposit;
            }
            _withdrawDeposit(_daiToWithdraw, _tokenId);
            emit LogDepositWithdrawal(_daiToWithdraw, _tokenId, msg.sender);
        }
    }




    function exit(uint256 _tokenId) external {
        withdrawDeposit(deposits[_tokenId][msg.sender], _tokenId);
    }




    function exitAll() external {
        for (uint i = 0; i < numberOfTokens; i++) {
            uint256 _remainingDeposit = deposits[i][msg.sender];
            if (_remainingDeposit > 0) {
                withdrawDeposit(_remainingDeposit, i);
            }
        }
    }








    function _collectRent(uint256 _tokenId) internal {

        if (ownerOf(_tokenId) != address(this)) {

            uint256 _rentOwed = rentOwed(_tokenId);
            address _currentOwner = ownerOf(_tokenId);
            uint256 _timeOfThisCollection;

            if (_rentOwed >= deposits[_tokenId][_currentOwner]) {

                _timeOfThisCollection = timeLastCollected[_tokenId].add(((now.sub(timeLastCollected[_tokenId])).mul(deposits[_tokenId][_currentOwner]).div(_rentOwed)));
                _rentOwed = deposits[_tokenId][_currentOwner];
                _revertToPreviousOwner(_tokenId);

            } else  {

                _timeOfThisCollection = now;
            }


            deposits[_tokenId][_currentOwner] = deposits[_tokenId][_currentOwner].sub(_rentOwed);


            uint256 _timeHeldToIncrement = (_timeOfThisCollection.sub(timeLastCollected[_tokenId]));



            timeHeld[_tokenId][_currentOwner] = timeHeld[_tokenId][_currentOwner].add(_timeHeldToIncrement);
            totalTimeHeld[_tokenId] = totalTimeHeld[_tokenId].add(_timeHeldToIncrement);
            collectedPerUser[_currentOwner] = collectedPerUser[_currentOwner].add(_rentOwed);
            collectedPerToken[_tokenId] = collectedPerToken[_tokenId].add(_rentOwed);
            totalCollected = totalCollected.add(_rentOwed);

            emit LogTimeHeldUpdated(timeHeld[_tokenId][_currentOwner], _currentOwner, _tokenId);
            emit LogRentCollection(_rentOwed, _tokenId);
        }




        timeLastCollected[_tokenId] = now;
    }



    function _depositDai(uint256 _dai, uint256 _tokenId) internal {
        deposits[_tokenId][msg.sender] = deposits[_tokenId][msg.sender].add(_dai);
        _receiveCash(msg.sender, _dai);
        emit LogDepositIncreased(_dai, _tokenId, msg.sender);
    }



    function _changePrice(uint256 _newPrice, uint256 _tokenId) internal {

        price[_tokenId] = _newPrice;
        ownerTracker[_tokenId][currentOwnerIndex[_tokenId]].price = _newPrice;
        emit LogPriceChange(price[_tokenId], _tokenId);
    }


    function _withdrawDeposit(uint256 _daiToWithdraw, uint256 _tokenId) internal {
        assert(deposits[_tokenId][msg.sender] >= _daiToWithdraw);
        address _currentOwner = ownerOf(_tokenId);


        if(_currentOwner == msg.sender) {
            uint256 _oneHour = 3600;
            uint256 _secondsOwned = now.sub(timeAcquired[_tokenId]);
            if (_secondsOwned < _oneHour) {
                uint256 _oneHoursDeposit = price[_tokenId].div(24);
                uint256 _secondsStillToPay = _oneHour.sub(_secondsOwned);
                uint256 _minDepositToLeave = _oneHoursDeposit.mul(_secondsStillToPay).div(_oneHour);
                uint256 _maxDaiToWithdraw = deposits[_tokenId][msg.sender].sub(_minDepositToLeave);
                if (_maxDaiToWithdraw < _daiToWithdraw) {
                    _daiToWithdraw = _maxDaiToWithdraw;
                }
            }
        }

        deposits[_tokenId][msg.sender] = deposits[_tokenId][msg.sender].sub(_daiToWithdraw);

        if(_currentOwner == msg.sender && deposits[_tokenId][msg.sender] == 0) {
            _revertToPreviousOwner(_tokenId);
        }
        _sendCash(msg.sender, _daiToWithdraw);
    }


    function _revertToPreviousOwner(uint256 _tokenId) internal {
        uint256 _index;
        address _previousOwner;


        for (uint i=0; i < MAX_ITERATIONS; i++)  {
            currentOwnerIndex[_tokenId] = currentOwnerIndex[_tokenId].sub(1);
            _index = currentOwnerIndex[_tokenId];
            _previousOwner = ownerTracker[_tokenId][_index].owner;


            if (_index == 0) {
                _foreclose(_tokenId);
                break;
            } else if (deposits[_tokenId][_previousOwner] > 0) {
                break;
            }
        }


        if (ownerOf(_tokenId) != address(this)) {
            address _currentOwner = ownerOf(_tokenId);
            uint256 _oldPrice = ownerTracker[_tokenId][_index].price;
            _transferTokenTo(_currentOwner, _previousOwner, _oldPrice, _tokenId);
            emit LogReturnToPreviousOwner(_tokenId, _previousOwner);
        }
    }


    function _foreclose(uint256 _tokenId) internal {
        address _currentOwner = ownerOf(_tokenId);

        _transferTokenTo(_currentOwner, address(this), 0, _tokenId);
        emit LogForeclosure(_currentOwner, _tokenId);
    }



    function _transferTokenTo(address _currentOwner, address _newOwner, uint256 _newPrice, uint256 _tokenId) internal {
        require(_currentOwner != address(0) && _newOwner != address(0) , "Cannot send to/from zero address");
        price[_tokenId] = _newPrice;
        _transferFrom(_currentOwner, _newOwner, _tokenId);
    }






    function _incrementState() internal {
        assert(uint256(state) < 4);
        state = States(uint(state) + 1);
    }



    function circuitBreaker() external {
        require(msg.sender == owner() || now > (marketExpectedResolutionTime + 4 weeks), "Not owner or too early");
        questionResolvedInvalid = true;
        state = States.WITHDRAW;
    }


    function transferFrom(address from, address to, uint256 tokenId) public {
        require(false, "Only the contract can make transfers");
        from;
        to;
        tokenId;
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        require(false, "Only the contract can make transfers");
        from;
        to;
        tokenId;
        _data;
    }
}

