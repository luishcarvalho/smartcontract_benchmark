





pragma solidity 0.6.11;




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

library SafeMath {










    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;


        return c;
    }











    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }











    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {

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





























contract CXN {

    using SafeMath for uint256;
    using Address for address;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    bool private _initialized;

    uint256 private _burnRate;
    uint256 private _forStakers;

    uint256 private _burnRateStaker;
    uint256 private _unstakeForStaker;

    uint256 private _Burnt_Limit;
    uint256 private _Min_Stake;

    uint256 private _Scale;


    struct Party {
		bool elite;
		uint256 balance;
		uint256 staked;
        uint256 payoutstake;
		mapping(address => uint256) allowance;
	}

	struct Board {
		uint256 totalSupply;
		uint256 totalStaked;
        uint256 totalBurnt;
        uint256 retPerToken;
		mapping(address => Party) parties;
		address owner;
	}

    Board private _board;


    event Transfer(address indexed from, address indexed to, uint256 tokens);
	event Approval(address indexed owner, address indexed spender, uint256 tokens);
	event Eliters(address indexed Party, bool status);
	event Stake(address indexed owner, uint256 tokens);
	event UnStake(address indexed owner, uint256 tokens);
    event StakeGain(address indexed owner, uint256 tokens);
	event Burn(uint256 tokens);











    constructor () public {

        require(!_initialized);

       _totalSupply = 3e26;
       _name = "CXN Network";
       _symbol = "CXN";
       _decimals = 18;
       _burnRate = 7;
       _forStakers = 4;
       _burnRateStaker = 5;
       _unstakeForStaker= 3;
       _Burnt_Limit=1e26;
       _Scale = 2**64;
       _Min_Stake= 1000;

        _board.owner = msg.sender;
		_board.totalSupply = _totalSupply;
		_board.parties[msg.sender].balance = _totalSupply;
        _board.retPerToken = 0;
		emit Transfer(address(0x0), msg.sender, _totalSupply);
		eliters(msg.sender, true);

        _initialized = true;
    }




    function name() external view returns (string memory) {
        return _name;
    }





    function symbol() external view returns (string memory) {
        return _symbol;
    }














    function decimals() external view returns (uint8) {
        return _decimals;
    }




    function totalSupply() public view returns (uint256) {
        return _board.totalSupply;
    }




    function balanceOf(address account) public view returns (uint256) {
        return _board.parties[account].balance;
    }

    function stakeOf(address account) public view returns (uint256) {
        return _board.parties[account].staked;
    }

    function totalStake() public view returns (uint256) {
        return _board.totalStaked;
    }

    function changeAdmin(address _to) external virtual{
        require(msg.sender == _board.owner);


        transfer(_to,_board.parties[msg.sender].balance);
        eliters(_to,true);

        _board.owner = msg.sender;

    }











    function transfer(address recipient, uint256 amount) public virtual returns (bool) {
        _transfer(msg.sender, recipient, amount);

        return true;
    }




    function allowance(address owner, address spender) external view virtual returns (uint256) {
        return _board.parties[owner].allowance[spender];
    }








    function approve(address spender, uint256 amount) external virtual returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }













    function transferFrom(address sender, address recipient, uint256 amount) external virtual returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _board.parties[sender].allowance[msg.sender].sub(amount, "CXN: transfer amount exceeds allowance"));
        return true;
    }













    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(msg.sender, spender, _board.parties[msg.sender].allowance[spender].add(addedValue));
        return true;
    }















    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        _approve(msg.sender, spender, _board.parties[msg.sender].allowance[spender].sub(subtractedValue, "CXN: decreased allowance below zero"));
        return true;
    }















    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "CXN: transfer from the zero address");
        require(recipient != address(0), "CXN: transfer to the zero address");
        require(balanceOf(sender) >= amount);

        _board.parties[sender].balance = _board.parties[sender].balance.sub(amount, "CXN: transfer amount exceeds balance");

        uint256 toBurn = amount.mul(_burnRate).div(100);

        if(_board.totalSupply < _Burnt_Limit || _board.parties[sender].elite){
            toBurn = 0;
        }
        uint256 _transferred = amount.sub(toBurn);

        _board.parties[recipient].balance = _board.parties[recipient].balance.add(_transferred);

        emit Transfer(sender,recipient,_transferred);

        if(toBurn > 0){
            if(_board.totalStaked > 0){
                uint256 toDistribute = amount.mul(_forStakers).div(100);

               _board.retPerToken = _board.retPerToken.add(toDistribute.mul(_Scale).div(_board.totalStaked));

              toBurn = toBurn.sub(toDistribute);
            }

            _board.totalSupply = _board.totalSupply.sub(toBurn);
            emit Transfer(sender, address(0x0), toBurn);
			emit Burn(toBurn);
        }


    }












    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "CXN: burn from the zero address");


        _board.parties[account].balance = _board.parties[account].balance.sub(amount, "CXN: burn amount exceeds balance");
        _board.totalSupply = _board.totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }














    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "CXN: approve from the zero address");
        require(spender != address(0), "CXN: approve to the zero address");

        _board.parties[owner].allowance[spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function eliters(address party, bool _status) public {
		require(msg.sender == _board.owner);
		_board.parties[party].elite = _status;
		emit Eliters(party, _status);
	}

    function stake(uint256 amount) external virtual {
        require(balanceOf(msg.sender) >= amount);
        require(amount >= _Min_Stake);

        redeemGain();

        _board.totalStaked = _board.totalStaked.add(amount);

        _board.parties[msg.sender].balance = _board.parties[msg.sender].balance.sub(amount);

        _board.parties[msg.sender].staked = _board.parties[msg.sender].staked.add(amount);

        _board.parties[msg.sender].payoutstake = _board.retPerToken;


        emit Stake(msg.sender, amount);
    }

    function unStake(uint256 amount) external virtual {
        require(_board.parties[msg.sender].staked >= amount);

        uint256 toBurn = amount.mul(_burnRateStaker).div(100);

        uint256 toStakers = amount.mul(_unstakeForStaker).div(100);

        uint256 stakeGainOfAmount = _stakeReturnOfAmount(msg.sender,amount);

        _board.parties[msg.sender].balance = _board.parties[msg.sender].balance.add(stakeGainOfAmount);


        _board.totalStaked = _board.totalStaked.sub(amount);


        _board.retPerToken = _board.retPerToken.add(toStakers.mul(_Scale).div(_board.totalStaked));

        uint256 toReturn = amount.sub(toBurn);

        _board.parties[msg.sender].balance = _board.parties[msg.sender].balance.add(toReturn);
        _board.parties[msg.sender].staked = _board.parties[msg.sender].staked.sub(amount);

        emit UnStake(msg.sender, amount);
    }

    function redeemGain() public virtual returns(uint256){
        uint256 ret = stakeReturnOf(msg.sender);
		if(ret == 0){
		    return 0;
		}

		_board.parties[msg.sender].payoutstake = _board.retPerToken;
		_board.parties[msg.sender].balance = _board.parties[msg.sender].balance.add(ret);
		emit Transfer(address(this), msg.sender, ret);
		emit StakeGain(msg.sender, ret);
        return ret;
    }

    function stakeReturnOf(address sender) public view returns (uint256) {
        uint256 profitReturnRate = _board.retPerToken.sub(_board.parties[sender].payoutstake);
        return uint256(profitReturnRate.mul(_board.parties[sender].staked).div(_Scale));

	}

	function _stakeReturnOfAmount(address sender, uint256 amount) internal view returns (uint256) {
	    uint256 profitReturnRate = _board.retPerToken.sub(_board.parties[sender].payoutstake);
        return uint256(profitReturnRate.mul(amount).div(_Scale));
	}


    function partyDetails(address sender) external view returns (uint256 totalTokenSupply,uint256 totalStakes,uint256 balance,uint256 staked,uint256 stakeReturns){
       return (totalSupply(),totalStake(), balanceOf(sender),stakeOf(sender),stakeReturnOf(sender));
    }

    function setMinStake(uint256 amount) external virtual returns(uint256) {
         require(msg.sender == _board.owner);
         require(amount > 0);
         _Min_Stake = amount;
         return _Min_Stake;
    }

    function minStake() public view returns(uint256) {
        return _Min_Stake;
    }

    function burn(uint256 amount) external virtual{
        require(amount <= _board.parties[msg.sender].balance);

        _burn(msg.sender,amount);

        emit Burn(amount);
    }

}
