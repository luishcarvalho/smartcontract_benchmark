







pragma solidity 0.6.2;














library SafeMath {










    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }











    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }











    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }











    function mul(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }













    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }













    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;


        return c;
    }













    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }













    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}





pragma solidity 0.6.2;











abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}





pragma solidity 0.6.2;













contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);




    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }




    function owner() public view returns (address) {
        return _owner;
    }




    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }








    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }





    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}





pragma solidity 0.6.2;




library Address {

















    function isContract(address account) internal view returns (bool) {




        uint256 size;

        assembly { size := extcodesize(account) }
        return size > 0;
    }

















    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");


        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }



















    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }







    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }












    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }







    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");


        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {

            if (block.number > 0) {



                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}





pragma solidity 0.6.2;





interface IERC20 {



    function totalSupply() external view returns (uint256);




    function balanceOf(address account) external view returns (uint256);








    function transfer(address recipient, uint256 amount) external returns (bool);








    function allowance(address owner, address spender) external view returns (uint256);















    function approve(address spender, uint256 amount) external returns (bool);










    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);







    event Transfer(address indexed from, address indexed to, uint256 value);





    event Approval(address indexed owner, address indexed spender, uint256 value);
}



pragma solidity 0.6.2;

interface IBrainLootbox {
  function getPrice(uint256 _id) external view returns (uint256);
  function redeem(uint256 id, address to) external;
}



pragma solidity 0.6.2;





library SafeMathInt {
  function mul(int256 a, int256 b) internal pure returns (int256) {


  require(!(a == - 2**255 && b == -1) && !(b == - 2**255 && a == -1));

  int256 c = a * b;
  require((b == 0) || (c / b == a));
  return c;
}

  function div(int256 a, int256 b) internal pure returns (int256) {


    require(!(a == - 2**255 && b == -1) && (b > 0));

    return a / b;
  }

  function sub(int256 a, int256 b) internal pure returns (int256) {
    require((b >= 0 && a - b <= a) || (b < 0 && a - b > a));

    return a - b;
  }

  function add(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a + b;
    require((b >= 0 && c >= a) || (b < 0 && c < a));
    return c;
  }

  function toUint256Safe(int256 a) internal pure returns (uint256) {
    require(a >= 0);
    return uint256(a);
  }
}

library SafeMathUint {
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0);
    return b;
  }
}

interface IFeeDistributor {
  function processTransfer() external;
  function pendingFarmAmount() external view returns (uint256);
}

contract LockedLPFarm is Ownable {
  using SafeMath for uint256;
  using SafeMathUint for uint256;
  using SafeMathInt for int256;

  address public LPAddress;
  address public DistributorAddress;
  address public BrainAddress;
  address public LootboxAddress;

  constructor(address _brain, address _lp) public {
    LPAddress = _lp;
    BrainAddress = _brain;
  }

  function setLootboxAddress(address _address) public onlyOwner {
    LootboxAddress = _address;
  }

  function setDistributorAddress(address _address) public onlyOwner {
    DistributorAddress = _address;
  }

	mapping(address => uint256) private lpBalance;
	mapping(address => uint256) public lastUpdateTime;
	mapping(address => uint256) public points;

		uint256 public totalStaked;

	event Staked(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);

	modifier updateReward(address account) {
		if (block.coinbase != address(0)) {
			points[account] = earned(account);
			lastUpdateTime[account] = block.timestamp;
      		}
		_;
	}

  function balanceOf(address account) public view returns (uint256) {
    return lpBalance[account];
  }


  function earned(address account) public view returns (uint256) {
    uint256 blockTime = block.timestamp;
    return points[account].add(blockTime.sub(lastUpdateTime[account]).mul(1e18).div(86400).mul(balanceOf(account).div(1e18)));
  }

	function stake(uint256 amount) public updateReward(_msgSender()) {
	  require(amount.add(balanceOf(_msgSender())) <= 5000000000000000000, "Cannot stake more than 5 Locked LP");
	  distributeDividends();
	  IERC20(LPAddress).transferFrom(_msgSender(), address(this), amount);
	  totalStaked = totalStaked.add(amount);
    magnifiedDividendCorrections[_msgSender()] = magnifiedDividendCorrections[_msgSender()].sub((magnifiedDividendPerShare.mul(amount)).toInt256Safe());
	  lpBalance[_msgSender()] = lpBalance[_msgSender()].add(amount);
		emit Staked(_msgSender(), amount);
	}

	function withdraw(uint256 amount) public updateReward(_msgSender()) {
		require(amount > 0, "Cannot withdraw 0");
		require(amount <= balanceOf(_msgSender()), "Cannot withdraw more than balance");
		distributeDividends();
		IERC20(LPAddress).transfer(_msgSender(), amount);
		totalStaked = totalStaked.sub(amount);
    magnifiedDividendCorrections[_msgSender()] = magnifiedDividendCorrections[_msgSender()].add((magnifiedDividendPerShare.mul(amount)).toInt256Safe());
		lpBalance[_msgSender()] = lpBalance[_msgSender()].sub(amount);
		emit Withdrawn(_msgSender(), amount);
	}

	function exit() external {
		withdraw(balanceOf(_msgSender()));
	}

	function redeem(uint256 _lootbox) public updateReward(_msgSender()) {
    uint256 price = IBrainLootbox(LootboxAddress).getPrice(_lootbox);
    require(price > 0, "Loot not found");
    require(points[_msgSender()] >= price, "Not enough points to redeem");
    IBrainLootbox(LootboxAddress).redeem(_lootbox, _msgSender());
    points[_msgSender()] = points[_msgSender()].sub(price);
	}



	event DividendsDistributed(uint256 amount);
	event DividendWithdrawn(address to, uint256 amount);

	uint256 private lastBrainBalance;

  uint256 constant public magnitude = 2**128;
  uint256 public magnifiedDividendPerShare;
  mapping(address => int256) public magnifiedDividendCorrections;
  mapping(address => uint256) public withdrawnDividends;

  function distributeDividends() public {
    if (block.gaslimit > 0) {
      IFeeDistributor(DistributorAddress).processTransfer();
      uint256 currentBalance = IERC20(BrainAddress).balanceOf(address(this));
      if (block.number > lastBrainBalance) {
        uint256 value = currentBalance.sub(lastBrainBalance);
        magnifiedDividendPerShare = magnifiedDividendPerShare.add((value.mul(magnitude)).div(totalStaked));
        lastBrainBalance = currentBalance;
        emit DividendsDistributed(value);
      }
    }
  }

  function withdrawDividend() public {
    distributeDividends();
    uint256 _withdrawableDividend = withdrawableDividendOf(_msgSender());
    if (block.timestamp > 0) {
      withdrawnDividends[_msgSender()] = withdrawnDividends[_msgSender()].add(_withdrawableDividend);
      emit DividendWithdrawn(_msgSender(), _withdrawableDividend);
      IERC20(BrainAddress).transfer(_msgSender(), _withdrawableDividend);
      lastBrainBalance = lastBrainBalance.sub(_withdrawableDividend);
    }
  }

  function dividendOf(address _owner) public view returns(uint256) {
    return withdrawableDividendOf(_owner);
  }

  function PendingWithdrawableDividendOf(address _owner) public view returns (uint256) {
    uint256 value = IFeeDistributor(DistributorAddress).pendingFarmAmount();
    if (block.timestamp > 0) {
      uint256 magnified = magnifiedDividendPerShare.add((value.mul(magnitude)).div(totalStaked));
      uint256 accum = magnified.mul(balanceOf(_owner)).toInt256Safe().add(magnifiedDividendCorrections[_owner]).toUint256Safe() / magnitude;
      return accum.sub(withdrawnDividends[_owner]);
    } else {
      return withdrawableDividendOf(_owner);
    }
  }

  function withdrawableDividendOf(address _owner) public view returns(uint256) {
    return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
  }

  function withdrawnDividendOf(address _owner) public view returns(uint256) {
    return withdrawnDividends[_owner];
  }

  function accumulativeDividendOf(address _owner) public view returns(uint256) {
    return magnifiedDividendPerShare.mul(balanceOf(_owner)).toInt256Safe()
      .add(magnifiedDividendCorrections[_owner]).toUint256Safe() / magnitude;
  }

}
