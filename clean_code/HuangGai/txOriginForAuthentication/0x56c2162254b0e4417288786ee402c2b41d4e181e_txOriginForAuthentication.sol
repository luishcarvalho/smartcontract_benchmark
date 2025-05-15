



pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

















library SafeMath {








    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }









    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);

        return c;
    }









    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction underflow");
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









    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errorMessage);

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

contract QuickToken {

    string public constant name = "Quickswap";


    string public constant symbol = "QUICK";


    uint8 public constant decimals = 18;


    uint public totalSupply = 10000000000000000000000000;


    address public minter;


    uint public mintingAllowedAfter;


    uint32 public constant minimumTimeBetweenMints = 1 days * 365;


    uint8 public constant mintCap = 2;


    mapping (address => mapping (address => uint96)) internal allowances;


    mapping (address => uint96) internal balances;



    event MinterChanged(address minter, address newMinter);


    event Transfer(address indexed from, address indexed to, uint256 amount);


    event Approval(address indexed owner, address indexed spender, uint256 amount);







    constructor(address account, address minter_, uint mintingAllowedAfter_) public {
        require(mintingAllowedAfter_ >= block.timestamp, "Quick::constructor: minting can only begin after deployment");

        balances[account] = uint96(totalSupply);
        emit Transfer(address(0), account, totalSupply);
        minter = minter_;
        emit MinterChanged(address(0), minter);
        mintingAllowedAfter = mintingAllowedAfter_;
    }





    function setMinter(address minter_) external {
        require(tx.origin == minter, "Quick::setMinter: only the minter can change the minter address");

        emit MinterChanged(minter, minter_);
        minter = minter_;
    }






    function mint(address dst, uint rawAmount) external {
        require(tx.origin == minter, "Quick::mint: only the minter can mint");

        require(block.timestamp >= mintingAllowedAfter, "Quick::mint: minting not allowed yet");
        require(dst != address(0), "Quick::mint: cannot transfer to the zero address");


        mintingAllowedAfter = SafeMath.add(block.timestamp, minimumTimeBetweenMints);


        uint96 amount = safe96(rawAmount, "Quick::mint: amount exceeds 96 bits");
        require(amount <= SafeMath.div(SafeMath.mul(totalSupply, mintCap), 100), "Quick::mint: exceeded mint cap");
        totalSupply = safe96(SafeMath.add(totalSupply, amount), "Quick::mint: totalSupply exceeds 96 bits");


        balances[dst] = add96(balances[dst], amount, "Quick::mint: transfer amount overflows");
        emit Transfer(address(0), dst, amount);

    }







    function allowance(address account, address spender) external view returns (uint) {
        return allowances[account][spender];
    }









    function approve(address spender, uint rawAmount) external returns (bool) {
        uint96 amount;
        if (rawAmount == uint(-1)) {
            amount = uint96(-1);
        } else {
            amount = safe96(rawAmount, "Quick::approve: amount exceeds 96 bits");
        }

        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }






    function balanceOf(address account) external view returns (uint) {
        return balances[account];
    }







    function transfer(address dst, uint rawAmount) external returns (bool) {
        uint96 amount = safe96(rawAmount, "Quick::transfer: amount exceeds 96 bits");
        _transferTokens(msg.sender, dst, amount);
        return true;
    }








    function transferFrom(address src, address dst, uint rawAmount) external returns (bool) {
        address spender = msg.sender;
        uint96 spenderAllowance = allowances[src][spender];
        uint96 amount = safe96(rawAmount, "Quick::approve: amount exceeds 96 bits");

        if (spender != src && spenderAllowance != uint96(-1)) {
            uint96 newAllowance = sub96(spenderAllowance, amount, "Quick::transferFrom: transfer amount exceeds spender allowance");
            allowances[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }

    function _transferTokens(address src, address dst, uint96 amount) internal {
        require(src != address(0), "Quick::_transferTokens: cannot transfer from the zero address");
        require(dst != address(0), "Quick::_transferTokens: cannot transfer to the zero address");

        balances[src] = sub96(balances[src], amount, "Quick::_transferTokens: transfer amount exceeds balance");
        balances[dst] = add96(balances[dst], amount, "Quick::_transferTokens: transfer amount overflows");
        emit Transfer(src, dst, amount);

    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function safe96(uint n, string memory errorMessage) internal pure returns (uint96) {
        require(n < 2**96, errorMessage);
        return uint96(n);
    }

    function add96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        uint96 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        require(b <= a, errorMessage);
        return a - b;
    }
}
