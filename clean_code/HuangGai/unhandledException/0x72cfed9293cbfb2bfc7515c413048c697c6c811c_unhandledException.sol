



pragma solidity 0.5.15;
















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




library Address {

















    function isContract(address account) internal view returns (bool) {




        uint256 size;

        assembly { size := extcodesize(account) }
        return size > 0;
    }

















    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");


        (bool success, ) = (false, bytes(msg.data));
	 recipient.call.value(amount)("");

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


        (bool success, bytes memory returndata) = (false, bytes(msg.data));
	 target.call.value(weiValue)(data);

        if (success) {
            return returndata;
        } else {

            if (returndata.length > 0) {



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









library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }








    function safeApprove(IERC20 token, address spender, uint256 value) internal {




        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }







    function _callOptionalReturn(IERC20 token, bytes memory data) private {




        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {

            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}











contract Context {


    constructor () internal { }

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}













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








    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }





    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


interface YAMv2 {
  function balanceOf(address owner) external view returns (uint256);
}

interface YAMv3 {
  function mint(address owner, uint256 amount) external;
}






contract Migrator is Context, Ownable {

    using SafeMath for uint256;

    address public constant yamV2 = address(0xAba8cAc6866B83Ae4eec97DD07ED254282f6aD8A);

    address public yamV3;

    bool public token_initialized;

    bool public delegatorRewardsSet;

    uint256 public constant vestingDuration = 30 days;

    uint256 public constant delegatorVestingDuration = 90 days;

    uint256 public constant startTime = 1600444800;

    uint256 public constant BASE = 10**18;

    mapping(address => uint256) public delegator_vesting;

    mapping(address => uint256) public delegator_claimed;

    mapping(address => uint256) public vesting;

    mapping(address => uint256) public claimed;

    constructor () public {
    }







    function setV3Address(address yamV3_) public onlyOwner {
        require(!token_initialized, "already set");
        token_initialized = true;
        yamV3 = yamV3_;
    }


    function delegatorRewardsDone() public onlyOwner {
        delegatorRewardsSet = true;
    }


    function vested(address who) public view returns (uint256) {

      uint256 vestedPerc = now.sub(startTime).mul(BASE).div(vestingDuration);

      uint256 delegatorVestedPerc = now.sub(startTime).mul(BASE).div(delegatorVestingDuration);

      if (vestedPerc > BASE) {
          vestedPerc = BASE;
      }
      if (delegatorVestedPerc > BASE) {
          delegatorVestedPerc = BASE;
      }


      uint256 totalVesting = vesting[who];


      uint256 totalVestingRedeemable = totalVesting.mul(vestedPerc).div(BASE);

      uint256 totalVestingDelegator = delegator_vesting[who].mul(delegatorVestedPerc).div(BASE);


      uint256 alreadyClaimed = claimed[who].add(delegator_claimed[who]);


      return totalVestingRedeemable.add(totalVestingDelegator).sub(alreadyClaimed);
    }


    modifier started() {
        require(block.timestamp >= startTime, "!started");
        require(token_initialized, "!initialized");
        require(delegatorRewardsSet, "!delegatorRewards");
        _;
    }






    function migrate()
        external
        started
    {

        uint256 vestedPerc = now.sub(startTime).mul(BASE).div(vestingDuration);


        uint256 delegatorVestedPerc = now.sub(startTime).mul(BASE).div(delegatorVestingDuration);

        if (vestedPerc > BASE) {
            vestedPerc = BASE;
        }
        if (delegatorVestedPerc > BASE) {
            delegatorVestedPerc = BASE;
        }


        uint256 yamValue = YAMv2(yamV2).balanceOf(_msgSender());


        uint256 halfRedeemable = yamValue / 2;

        uint256 mintAmount;


        {

            uint256 totalVesting = vesting[_msgSender()].add(halfRedeemable);


            vesting[_msgSender()] = totalVesting;


            uint256 totalVestingRedeemable = totalVesting.mul(vestedPerc).div(BASE);

            uint256 totalVestingDelegator = delegator_vesting[_msgSender()].mul(delegatorVestedPerc).div(BASE);


            uint256 alreadyClaimed = claimed[_msgSender()];


            uint256 alreadyClaimedDelegator = delegator_claimed[_msgSender()];


            uint256 currVested = totalVestingRedeemable.sub(alreadyClaimed);


            uint256 currVestedDelegator = totalVestingDelegator.sub(alreadyClaimedDelegator);


            mintAmount = halfRedeemable.add(currVested).add(currVestedDelegator);


            claimed[_msgSender()] = claimed[_msgSender()].add(currVested);


            delegator_claimed[_msgSender()] = delegator_claimed[_msgSender()].add(currVestedDelegator);
        }



        SafeERC20.safeTransferFrom(
            IERC20(yamV2),
            _msgSender(),
            address(0x000000000000000000000000000000000000dEaD),
            yamValue
        );


        YAMv3(yamV3).mint(_msgSender(), mintAmount);
    }


    function claimVested()
        external
        started
    {

        uint256 vestedPerc = now.sub(startTime).mul(BASE).div(vestingDuration);


        uint256 delegatorVestedPerc = now.sub(startTime).mul(BASE).div(delegatorVestingDuration);

        if (vestedPerc > BASE) {
            vestedPerc = BASE;
        }
        if (delegatorVestedPerc > BASE) {
          delegatorVestedPerc = BASE;
        }


        uint256 totalVesting = vesting[_msgSender()];


        uint256 totalVestingRedeemable = totalVesting.mul(vestedPerc).div(BASE);

        uint256 totalVestingDelegator = delegator_vesting[_msgSender()].mul(delegatorVestedPerc).div(BASE);


        uint256 alreadyClaimed = claimed[_msgSender()];


        uint256 alreadyClaimedDelegator = delegator_claimed[_msgSender()];


        uint256 currVested = totalVestingRedeemable.sub(alreadyClaimed);


        uint256 currVestedDelegator = totalVestingDelegator.sub(alreadyClaimedDelegator);


        claimed[_msgSender()] = claimed[_msgSender()].add(currVested);


        delegator_claimed[_msgSender()] = delegator_claimed[_msgSender()].add(currVestedDelegator);


        YAMv3(yamV3).mint(_msgSender(), currVested.add(currVestedDelegator));
    }



    function addDelegatorReward(
        address[] calldata delegators,
        uint256[] calldata amounts,
        bool under27
    )
        external
        onlyOwner
    {
        require(!delegatorRewardsSet, "set");
        require(delegators.length == amounts.length, "!len");
        if (!under27) {
            for (uint256 i = 0; i < delegators.length; i++) {
                delegator_vesting[delegators[i]] = amounts[i];
            }
        } else {
            for (uint256 i = 0; i < delegators.length; i++) {
                delegator_vesting[delegators[i]] = 27 * 10**24;
            }
        }
    }


    function rescueTokens(
        address token,
        address to,
        uint256 amount
    )
        external
        onlyOwner
    {

        SafeERC20.safeTransfer(IERC20(token), to, amount);
    }
}
