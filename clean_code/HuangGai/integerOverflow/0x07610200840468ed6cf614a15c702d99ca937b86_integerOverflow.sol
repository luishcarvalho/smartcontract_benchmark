



pragma solidity 0.6.12;







library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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

    return c;
  }
}

























library EnumerableSet {









    struct Set {

        bytes32[] _values;



        mapping (bytes32 => uint256) _indexes;
    }







    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);


            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }







    function _remove(Set storage set, bytes32 value) private returns (bool) {

        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {




            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;




            bytes32 lastvalue = set._values[lastIndex];


            set._values[toDeleteIndex] = lastvalue;

            set._indexes[lastvalue] = toDeleteIndex + 1;


            set._values.pop();


            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }




    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }




    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }











    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }



    struct AddressSet {
        Set _inner;
    }







    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }







    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }




    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }




    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }











    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }




    struct UintSet {
        Set _inner;
    }







    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }







    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }




    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }




    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }











    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}






contract Ownable {
  address public admin;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);






  constructor() public {
    admin = msg.sender;
  }





  modifier onlyOwner() {
    require(msg.sender == admin);
    _;
  }






  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(admin, newOwner);
    admin = newOwner;
  }
}


interface Token {
    function transferFrom(address, address, uint) external returns (bool);
    function transfer(address, uint) external returns (bool);
}

contract Pool2 is Ownable {
    using SafeMath for uint;
    using EnumerableSet for EnumerableSet.AddressSet;

    event RewardsTransferred(address holder, uint amount);


    address public tokenAddress;
    address public liquiditytoken1;


    uint public rewardRate = 60000;
    uint public rewardInterval = 365 days;


    uint public stakingFeeRate = 0;


    uint public unstakingFeeRate = 0;


    uint public PossibleUnstakeTime = 24 hours;

    uint public totalClaimedRewards = 0;
    uint private FundedTokens;


    bool public stakingStatus = false;

    EnumerableSet.AddressSet private holders;

    mapping (address => uint) public depositedTokens;
    mapping (address => uint) public stakingTime;
    mapping (address => uint) public lastClaimedTime;
    mapping (address => uint) public totalEarnedTokens;



    function setTokenAddresses(address _tokenAddr, address _liquidityAddr) public onlyOwner returns(bool){
     require(_tokenAddr != address(0) && _liquidityAddr != address(0), "Invalid addresses format are not supported");
     tokenAddress = _tokenAddr;
     liquiditytoken1 = _liquidityAddr;

    }

    function stakingFeeRateSet(uint _stakingFeeRate, uint _unstakingFeeRate) public onlyOwner returns(bool){
     stakingFeeRate = _stakingFeeRate;
     unstakingFeeRate = _unstakingFeeRate;

    }

     function rewardRateSet(uint _rewardRate) public onlyOwner returns(bool){
     rewardRate = _rewardRate;

     }

     function StakingReturnsAmountSet(uint _poolreward) public onlyOwner returns(bool){
     FundedTokens = _poolreward;

     }


    function possibleUnstakeTimeSet(uint _possibleUnstakeTime) public onlyOwner returns(bool){

     PossibleUnstakeTime = _possibleUnstakeTime;

     }

    function rewardIntervalSet(uint _rewardInterval) public onlyOwner returns(bool){

     rewardInterval = _rewardInterval;

     }


    function allowStaking(bool _status) public onlyOwner returns(bool){
        require(tokenAddress != address(0) && liquiditytoken1 != address(0), "Interracting token addresses are not yet configured");
        stakingStatus = _status;
    }

    function transferAnyERC20Tokens(address _tokenAddr, address _to, uint _amount) public onlyOwner {
        if (_tokenAddr == tokenAddress) {
            if (_amount > getFundedTokens()) {
                revert();
            }
            totalClaimedRewards = totalClaimedRewards.add(_amount);

        }
        Token(_tokenAddr).transfer(_to, _amount);
    }


    function updateAccount(address account) private {
        uint unclaimedDivs = getUnclaimedDivs(account);
        if (unclaimedDivs > 0) {
            require(Token(tokenAddress).transfer(account, unclaimedDivs), "Could not transfer tokens.");
            totalEarnedTokens[account] = totalEarnedTokens[account].add(unclaimedDivs);
            totalClaimedRewards = totalClaimedRewards.add(unclaimedDivs);
            emit RewardsTransferred(account, unclaimedDivs);
        }
        lastClaimedTime[account] = now;
    }

    function getUnclaimedDivs(address _holder) public view returns (uint) {

        if (!holders.contains(_holder)) return 0;
        if (depositedTokens[_holder] == 0) return 0;

        uint timeDiff = now.sub(lastClaimedTime[_holder]);

        uint stakedAmount = depositedTokens[_holder];

        uint unclaimedDivs = stakedAmount
                            .mul(rewardRate)
                            .mul(timeDiff)
                            .div(rewardInterval)
                            .div(1e4);

        return unclaimedDivs;
    }

    function getNumberOfHolders() public view returns (uint) {
        return holders.length();
    }

    function plant(uint amountToStake) public {
        require(stakingStatus == true, "Staking is not yet initialized");
        require(amountToStake > 0, "Cannot deposit 0 Tokens");
        require(Token(liquiditytoken1).transferFrom(msg.sender, address(this), amountToStake), "Insufficient Token Allowance");

        updateAccount(msg.sender);

        uint fee = amountToStake.mul(stakingFeeRate).div(1e4);
        uint amountAfterFee = amountToStake.sub(fee);
        require(Token(liquiditytoken1).transfer(admin, fee), "Could not transfer deposit fee.");

        depositedTokens[msg.sender] = depositedTokens[msg.sender].add(amountAfterFee);

        if (!holders.contains(msg.sender)) {
            holders.add(msg.sender);
            stakingTime[msg.sender] = now;
        }
    }

    function unplant(uint amountToWithdraw) public {

        require(depositedTokens[msg.sender] >= amountToWithdraw, "Invalid amount to withdraw");

        require(now.sub(stakingTime[msg.sender]) > PossibleUnstakeTime, "You have not staked for a while yet, kindly wait a bit more");

        updateAccount(msg.sender);

        uint fee = amountToWithdraw.mul(unstakingFeeRate).div(1e4);
        uint amountAfterFee = amountToWithdraw.sub(fee);

        require(Token(liquiditytoken1).transfer(admin, fee), "Could not transfer withdraw fee.");
        require(Token(liquiditytoken1).transfer(msg.sender, amountAfterFee), "Could not transfer tokens.");

        depositedTokens[msg.sender] = depositedTokens[msg.sender].sub(amountToWithdraw);

        if (holders.contains(msg.sender) && depositedTokens[msg.sender] == 0) {
            holders.remove(msg.sender);
        }
    }

    function reap() public {
        updateAccount(msg.sender);
    }

    function getFundedTokens() public view returns (uint) {
        if (totalClaimedRewards >= FundedTokens) {
            return 0;
        }
        uint remaining = FundedTokens.sub(totalClaimedRewards);
        return remaining;
    }


}
