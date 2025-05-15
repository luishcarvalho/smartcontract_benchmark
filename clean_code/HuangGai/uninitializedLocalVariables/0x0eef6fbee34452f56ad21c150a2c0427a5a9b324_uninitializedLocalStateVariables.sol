



pragma solidity 0.6.11;







library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c ;

    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {

    uint256 c ;


    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c ;

    assert(c >= a);
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

        uint256 valueIndex ;


        if (valueIndex != 0) {




            uint256 toDeleteIndex ;

            uint256 lastIndex ;





            bytes32 lastvalue ;



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
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);






  constructor() public {
    owner = msg.sender;
  }





  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }






  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

interface Token {
    function transferFrom(address, address, uint) external returns (bool);
    function transfer(address, uint) external returns (bool);
}

contract Staking is Ownable {
    using SafeMath for uint;
    using EnumerableSet for EnumerableSet.AddressSet;

    event RewardsTransferred(address holder, uint amount);


    address public constant trustedStakeTokenAddress = 0x66A9D899e8760B0aa897b9aD764e446CFc897C4B;

    address public constant trustedRewardTokenAddress = 0x80bb277f4355A43CDbB86a82F9876C946476d9Eb;


    uint public rewardRatePercentX100 ;

    uint public constant rewardInterval = 365 days;

    uint public totalClaimedRewards ;


    uint public stakingDuration ;



    uint public adminCanClaimAfter ;


    uint public stakingDeployTime;
    uint public adminClaimableTime;
    uint public stakingEndTime;

    EnumerableSet.AddressSet private holders;

    mapping (address => uint) public depositedTokens;
    mapping (address => uint) public stakingTime;
    mapping (address => uint) public lastClaimedTime;
    mapping (address => uint) public totalEarnedTokens;

    constructor () public {
        stakingDeployTime = now;
        stakingEndTime = stakingDeployTime.add(stakingDuration);
        adminClaimableTime = stakingDeployTime.add(adminCanClaimAfter);
    }




    function setRewardRatePercentX100(uint _rewardRatePercentX100) public onlyOwner {
        rewardRatePercentX100 = _rewardRatePercentX100;
    }

    function updateAccount(address account) private {
        uint pendingDivs ;

        if (pendingDivs > 0) {
            require(Token(trustedRewardTokenAddress).transfer(account, pendingDivs), "Could not transfer tokens.");
            totalEarnedTokens[account] = totalEarnedTokens[account].add(pendingDivs);
            totalClaimedRewards = totalClaimedRewards.add(pendingDivs);
            emit RewardsTransferred(account, pendingDivs);
        }
        lastClaimedTime[account] = now;
    }

    function getPendingDivs(address _holder) public view returns (uint) {
        if (!holders.contains(_holder)) return 0;
        if (depositedTokens[_holder] == 0) return 0;

        uint timeDiff;
        uint _now ;

        if (_now > stakingEndTime) {
            _now = stakingEndTime;
        }

        if (lastClaimedTime[_holder] >= _now) {
            timeDiff = 0;
        } else {
            timeDiff = _now.sub(lastClaimedTime[_holder]);
        }

        uint stakedAmount ;


        uint pendingDivs ;


        return pendingDivs;
    }

    function getNumberOfHolders() public view returns (uint) {
        return holders.length();
    }


    function stake(uint amountToStake) public {
        require(amountToStake > 0, "Cannot stake 0 Tokens");
        require(Token(trustedStakeTokenAddress).transferFrom(msg.sender, address(this), amountToStake), "Insufficient Token Allowance");

        updateAccount(msg.sender);

        depositedTokens[msg.sender] = depositedTokens[msg.sender].add(amountToStake);

        if (!holders.contains(msg.sender)) {
            holders.add(msg.sender);
            stakingTime[msg.sender] = now;
        }
    }

    function unstake(uint amountToWithdraw) public {
        require(amountToWithdraw > 0, "Cannot unstake 0 Tokens");
        require(depositedTokens[msg.sender] >= amountToWithdraw, "Invalid amount to withdraw");

        updateAccount(msg.sender);

        require(Token(trustedStakeTokenAddress).transfer(msg.sender, amountToWithdraw), "Could not transfer tokens.");

        depositedTokens[msg.sender] = depositedTokens[msg.sender].sub(amountToWithdraw);

        if (holders.contains(msg.sender) && depositedTokens[msg.sender] == 0) {
            holders.remove(msg.sender);
        }
    }



    function emergencyUnstake(uint amountToWithdraw) public {
        require(amountToWithdraw > 0, "Cannot unstake 0 Tokens");
        require(depositedTokens[msg.sender] >= amountToWithdraw, "Invalid amount to withdraw");


        lastClaimedTime[msg.sender] = now;

        require(Token(trustedStakeTokenAddress).transfer(msg.sender, amountToWithdraw), "Could not transfer tokens.");

        depositedTokens[msg.sender] = depositedTokens[msg.sender].sub(amountToWithdraw);

        if (holders.contains(msg.sender) && depositedTokens[msg.sender] == 0) {
            holders.remove(msg.sender);
        }
    }

    function claim() public {
        updateAccount(msg.sender);
    }

    function getStakersList(uint startIndex, uint endIndex)
        public
        view
        returns (address[] memory stakers,
            uint[] memory stakingTimestamps,
            uint[] memory lastClaimedTimeStamps,
            uint[] memory stakedTokens) {
        require (startIndex < endIndex);

        uint length ;

        address[] memory _stakers = new address[](length);
        uint[] memory _stakingTimestamps = new uint[](length);
        uint[] memory _lastClaimedTimeStamps = new uint[](length);
        uint[] memory _stakedTokens = new uint[](length);

        for (uint i ; i < endIndex; i = i.add(1)) {

            address staker ;

            uint listIndex ;

            _stakers[listIndex] = staker;
            _stakingTimestamps[listIndex] = stakingTime[staker];
            _lastClaimedTimeStamps[listIndex] = lastClaimedTime[staker];
            _stakedTokens[listIndex] = depositedTokens[staker];
        }

        return (_stakers, _stakingTimestamps, _lastClaimedTimeStamps, _stakedTokens);
    }




    function transferAnyERC20Tokens(address _tokenAddr, address _to, uint _amount) public onlyOwner {
        require(_tokenAddr != trustedStakeTokenAddress, "Admin cannot transfer out Stake Tokens from this contract!");

        require((_tokenAddr != trustedRewardTokenAddress) || (now > adminClaimableTime), "Admin cannot Transfer out Reward Tokens yet!");

        Token(_tokenAddr).transfer(_to, _amount);
    }
}
