





pragma solidity 0.6.6;
















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




abstract contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;






    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }




    function name() public view returns (string memory) {
        return _name;
    }





    function symbol() public view returns (string memory) {
        return _symbol;
    }













    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

enum RebaseResult { Double, Park, Draw }

contract TautrinoToken is ERC20Detailed {

    using SafeMath for uint;
    using Address for address;

    event LogTokenRebase(uint64 epoch, RebaseResult result, uint totalSupply);

    address public governance;

    uint private _baseTotalSupply;
    uint256 private _factor2;

    uint64 private _lastRebaseEpoch;
    RebaseResult private _lastRebaseResult;

    mapping(address => uint) private _baseBalances;


    mapping (address => mapping (address => uint)) private _allowedFragments;




    modifier onlyGovernance() {
        require(governance == msg.sender, "governance!");
        _;
    }






    constructor(string memory symbol) public ERC20Detailed("Tautrino", symbol, 18) {
        governance = msg.sender;
        _baseTotalSupply = 300 * (10**uint(decimals()));
        _baseBalances[msg.sender] = totalSupply();
        _factor2 = 0;
        emit Transfer(address(0x0), msg.sender, totalSupply());
    }






    function setGovernance(address _governance) public onlyGovernance {
        governance = _governance;
    }






    function rebase(RebaseResult _result) public onlyGovernance returns (uint) {
        if (_result == RebaseResult.Double) {
            _factor2 = _factor2.add(1);
        } else if (_result == RebaseResult.Park) {
            _factor2 = 0;
        }

        _lastRebaseResult = _result;
        _lastRebaseEpoch = uint64(block.timestamp);

        uint _totalSupply = totalSupply();
        LogTokenRebase(_lastRebaseEpoch, _lastRebaseResult, _totalSupply);

        return _totalSupply;
    }





    function totalSupply() public override view returns (uint) {
        return _baseTotalSupply.mul(2 ** _factor2);
    }






    function balanceOf(address who) public override view returns (uint) {
        return _baseBalances[who].mul(2 ** _factor2);
    }








    function transfer(address to, uint value) public override returns (bool) {
        uint merValue = value.div(2 ** _factor2);
        _baseBalances[msg.sender] = _baseBalances[msg.sender].sub(merValue);
        _baseBalances[to] = _baseBalances[to].add(merValue);
        emit Transfer(msg.sender, to, value);
        return true;
    }








    function allowance(address owner_, address spender) public override view returns (uint) {
        return _allowedFragments[owner_][spender];
    }








    function transferFrom(address from, address to, uint value) public override returns (bool) {
        _allowedFragments[from][msg.sender] = _allowedFragments[from][msg.sender].sub(value);

        uint merValue = value.div(2 ** _factor2);
        _baseBalances[from] = _baseBalances[from].sub(merValue);
        _baseBalances[to] = _baseBalances[to].add(merValue);
        emit Transfer(from, to, value);

        return true;
    }













    function approve(address spender, uint value) public override returns (bool) {
        _allowedFragments[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }









    function increaseAllowance(address spender, uint addedValue) public returns (bool) {
        _allowedFragments[msg.sender][spender] = _allowedFragments[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }








    function decreaseAllowance(address spender, uint subtractedValue) public returns (bool) {
        uint oldValue = _allowedFragments[msg.sender][spender];
        if (subtractedValue >= oldValue) {
        _allowedFragments[msg.sender][spender] = 0;
        } else {
        _allowedFragments[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }





    function lastRebaseEpoch() public view returns (uint64) {
        return _lastRebaseEpoch;
    }





    function lastRebaseResult() public view returns (RebaseResult) {
        return _lastRebaseResult;
    }





    function factor2() public view returns (uint) {
        return _factor2;
    }
}
