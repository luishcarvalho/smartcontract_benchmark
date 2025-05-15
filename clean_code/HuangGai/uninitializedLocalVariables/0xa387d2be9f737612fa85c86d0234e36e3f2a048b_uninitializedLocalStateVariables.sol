



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

contract VaultTimely is Ownable {
    using SafeMath for uint;
    using EnumerableSet for EnumerableSet.AddressSet;

    event RewardsTransferred(address holder, uint amount);


    address public constant trustedDepositTokenAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address public constant trustedRewardTokenAddress = 0xf4CD3d3Fda8d7Fd6C5a500203e38640A70Bf9577;

    uint public rewardRatePercentX100 ;

    uint public constant rewardInterval = 365 days;
    uint public cliffTime ;

    uint public withdrawFeePercentX100 ;


    uint public totalClaimedRewards ;


    uint public vaultDuration ;



    uint public adminCanClaimAfter ;


    uint public vaultDeployTime;
    uint public adminClaimableTime;
    uint public vaultEndTime;

    EnumerableSet.AddressSet private holders;

    mapping (address => uint) public depositedTokens;
    mapping (address => uint) public depositTime;
    mapping (address => uint) public lastClaimedTime;
    mapping (address => uint) public totalEarnedTokens;

    constructor () public {
        vaultDeployTime = now;
        vaultEndTime = vaultDeployTime.add(vaultDuration);
        adminClaimableTime = vaultDeployTime.add(adminCanClaimAfter);
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

        if (_now > vaultEndTime) {
            _now = vaultEndTime;
        }

        if (lastClaimedTime[_holder] >= _now) {
            timeDiff = 0;
        } else {
            timeDiff = _now.sub(lastClaimedTime[_holder]);
        }

        uint depositedAmount ;


        uint pendingDivs ;


        return pendingDivs;
    }

    function getNumberOfHolders() public view returns (uint) {
        return holders.length();
    }


    function deposit(uint amountToDeposit) public {
        require(amountToDeposit > 0, "Cannot deposit 0 Tokens");
        require(Token(trustedDepositTokenAddress).transferFrom(msg.sender, address(this), amountToDeposit), "Insufficient Token Allowance");

        updateAccount(msg.sender);

        depositedTokens[msg.sender] = depositedTokens[msg.sender].add(amountToDeposit);

        if (!holders.contains(msg.sender)) {
            holders.add(msg.sender);
            depositTime[msg.sender] = now;
        }
    }

    function withdraw(uint amountToWithdraw) public {
        require(amountToWithdraw > 0, "Cannot withdraw 0 Tokens");
        require(depositedTokens[msg.sender] >= amountToWithdraw, "Invalid amount to withdraw");



        updateAccount(msg.sender);

        uint fee ;

        uint amountAfterFee ;


        require(Token(trustedDepositTokenAddress).transfer(owner, fee), "Could not transfer fee!");
        require(Token(trustedDepositTokenAddress).transfer(msg.sender, amountAfterFee), "Could not transfer tokens.");

        depositedTokens[msg.sender] = depositedTokens[msg.sender].sub(amountToWithdraw);

        if (holders.contains(msg.sender) && depositedTokens[msg.sender] == 0) {
            holders.remove(msg.sender);
        }
    }



    function emergencyWithdraw(uint amountToWithdraw) public {
        require(amountToWithdraw > 0, "Cannot withdraw 0 Tokens");
        require(depositedTokens[msg.sender] >= amountToWithdraw, "Invalid amount to withdraw");


        lastClaimedTime[msg.sender] = now;

        uint fee ;

        uint amountAfterFee ;


        require(Token(trustedDepositTokenAddress).transfer(owner, fee), "Could not transfer fee!");
        require(Token(trustedDepositTokenAddress).transfer(msg.sender, amountAfterFee), "Could not transfer tokens.");

        depositedTokens[msg.sender] = depositedTokens[msg.sender].sub(amountToWithdraw);

        if (holders.contains(msg.sender) && depositedTokens[msg.sender] == 0) {
            holders.remove(msg.sender);
        }
    }

    function claim() public {
        updateAccount(msg.sender);
    }

    function getDepositorsList(uint startIndex, uint endIndex)
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
            _stakingTimestamps[listIndex] = depositTime[staker];
            _lastClaimedTimeStamps[listIndex] = lastClaimedTime[staker];
            _stakedTokens[listIndex] = depositedTokens[staker];
        }

        return (_stakers, _stakingTimestamps, _lastClaimedTimeStamps, _stakedTokens);
    }




    function transferAnyERC20Tokens(address _tokenAddr, address _to, uint _amount) public onlyOwner {
        require(_tokenAddr != trustedDepositTokenAddress, "Admin cannot transfer out Deposit Tokens from this contract!");

        require((_tokenAddr != trustedRewardTokenAddress) || (now > adminClaimableTime), "Admin cannot Transfer out Reward Tokens yet!");

        Token(_tokenAddr).transfer(_to, _amount);
    }
}
