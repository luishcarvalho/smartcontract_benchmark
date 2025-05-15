




pragma solidity ^0.6.12;





interface IERC20 {



    function totalSupply() external view returns (uint);




    function balanceOf(address account) external view returns (uint);
    function decimals() external view returns (uint);







    function transfer(address recipient, uint amount) external returns (bool);








    function allowance(address owner, address spender) external view returns (uint);















    function approve(address spender, uint amount) external returns (bool);










    function transferFrom(address sender, address recipient, uint amount) external returns (bool);







    event Transfer(address indexed from, address indexed to, uint value);





    event Approval(address indexed owner, address indexed spender, uint value);
}

















library SafeMath {








    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }









    function add(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, errorMessage);

        return c;
    }









    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "Uniloan::SafeMath: subtraction underflow");
    }









    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }









    function mul(uint a, uint b) internal pure returns (uint) {



        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }









    function mul(uint a, uint b, string memory errorMessage) internal pure returns (uint) {



        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }












    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }












    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {

        require(b > 0, errorMessage);
        uint c = a / b;


        return c;
    }












    function mod(uint a, uint b) internal pure returns (uint) {
        return mod(a, b, "SafeMath: modulo by zero");
    }












    function mod(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IUniswapV2SlidingOracle {
    function quote(address tokenIn, uint amountIn, address tokenOut, uint granularity) external view returns (uint amountOut);
}

contract YearnOptionsV1Manager {
    using SafeMath for uint;


    string public name = "Yearn OptionsV1Manager";


    string public symbol = "yOV1M";


    uint8 public constant decimals = 18;


    uint public totalSupply = 0;

    mapping (address => mapping (address => uint)) internal allowances;
    mapping (address => uint) internal balances;


    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint chainId,address verifyingContract)");


    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint value,uint nonce,uint deadline)");


    mapping (address => uint) public nonces;


    event Transfer(address indexed from, address indexed to, uint amount);


    event Approval(address indexed owner, address indexed spender, uint amount);


    event Deposited(address indexed creditor, uint shares, uint credit);


    event Withdrew(address indexed creditor, uint shares, uint credit);


    event Created(uint id, address indexed owner, address indexed tokenIn, uint amountIn, uint amountOut, uint created, uint expire);


    event Excercised(uint id, address indexed owner, address indexed tokenIn, uint amountIn, uint amountOut, uint created, uint expire);


    event Closed(uint id, address indexed owner, uint created, uint expire);

    struct position {
        address owner;
        address asset;
        uint amountIn;
        uint amountOut;
        uint created;
        uint expire;
        bool open;
    }

    IUniswapV2SlidingOracle public constant ORACLE = IUniswapV2SlidingOracle(0xCA2E2df6A7a7Cf5bd19D112E8568910a6C2D3885);

    uint constant public SQRTPERIOD = 777;
    uint constant public PERIOD = 7 days;
    uint constant public GRANULARITY = 8;

    address constant public WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address constant public DAI = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);







    function quote(address tokenIn, uint amountIn) public view returns (uint minOut) {
        uint _wethOut = ORACLE.quote(tokenIn, amountIn, WETH, GRANULARITY);
        minOut = ORACLE.quote(WETH, _wethOut, DAI, GRANULARITY);
    }








    function getStrikeFee(
        uint256 amountIn,
        uint256 amountOut,
        uint256 currentOut
    ) internal pure returns (uint256) {
        if (amountOut > currentOut)
            return amountOut.sub(currentOut).mul(amountIn).div(currentOut);
        return 0;
    }















    function getPeriodFee(
        uint256 amountIn,
        uint256 amountOut,
        uint256 currentOut
    ) internal pure returns (uint256) {
        return amountIn
                .mul(SQRTPERIOD)
                .mul(amountOut)
                .div(currentOut)
                .mul(5500)
                .div(100000000);
    }








    function fees(uint amountIn, uint amountOut, uint currentOut) public pure returns (uint) {
        return getPeriodFee(amountIn, amountOut, currentOut)
                .add(getStrikeFee(amountIn, amountOut, currentOut))
                .add(getSettlementFee(amountIn));
    }






    function getSettlementFee(uint amount) internal pure returns (uint) {
        return amount / 100;
    }


    position[] public positions;


    uint public nextIndex;


    uint public processedIndex;


    mapping(address => uint[]) public options;

    address public governance;
    address public pendingGovernance;

    address public constant reserve = address(0x9cA85572E6A3EbF24dEDd195623F188735A5179f);

    uint public reserveInUse;


    constructor() public {
        governance = msg.sender;
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "::setGovernance: only governance");
        pendingGovernance = _governance;
    }

    function acceptGovernance() external {
        require(msg.sender == pendingGovernance, "::acceptGovernance: only pendingGovernance");
        governance = pendingGovernance;
    }

    function _mint(address dst, uint amount) internal {

        totalSupply = totalSupply.add(amount);


        balances[dst] = balances[dst].add(amount);
        emit Transfer(address(0), dst, amount);
    }

    function _burn(address dst, uint amount) internal {

        totalSupply = totalSupply.sub(amount, "::_burn: underflow");


        balances[dst] = balances[dst].sub(amount, "::_burn: underflow");
        emit Transfer(dst, address(0), amount);
    }





    function withdrawAll() external returns (bool) {
        return withdraw(balances[msg.sender]);
    }

    function liquidityBalance() public view returns (uint) {
        return IERC20(reserve).balanceOf(address(this));
    }

    function inCaseTokensGetStuck(address token) external {
        require(msg.sender == governance, "::inCaseTokensGetStuck: only governance");
        IERC20(token).transfer(governance, IERC20(token).balanceOf(address(this)));
    }






    function withdraw(uint _shares) public returns (bool) {
        uint r = liquidityBalance().mul(_shares).div(totalSupply);
        _burn(msg.sender, _shares);

        IERC20(reserve).transfer(msg.sender, r);
        emit Withdrew(msg.sender, _shares, r);
        return true;
    }





    function depositAll() external returns (bool) {
        return deposit(IERC20(reserve).balanceOf(msg.sender));
    }






    function deposit(uint amount) public returns (bool) {
        IERC20(reserve).transferFrom(msg.sender, address(this), amount);
        uint _shares = 0;
        if (address(this).balance == 0) {
            _shares = amount;
        } else {
            _shares = amount.mul(totalSupply).div(liquidityBalance());
        }
        _mint(msg.sender, _shares);
        emit Deposited(msg.sender, _shares, amount);
        return true;
    }






    function closeInBatches(uint size) external returns (uint) {
        uint i = processedIndex;
        for (; i < size; i++) {
            close(i);
        }
        processedIndex = i;
        return processedIndex;
    }





    function closeAllOpen() external returns (uint) {
        uint i = processedIndex;
        for (; i < nextIndex; i++) {
            close(i);
        }
        processedIndex = i;
        return processedIndex;
    }






    function close(uint id) public returns (bool) {
        position storage _pos = positions[id];
        if (_pos.owner == address(0x0)) {
            return false;
        }
        if (!_pos.open) {
            return false;
        }
        if (_pos.expire > block.timestamp) {
            return false;
        }
        _pos.open = false;
        reserveInUse = reserveInUse.sub(_pos.amountOut);
        emit Closed(id, _pos.owner, _pos.created, _pos.expire);
        return true;
    }

    function calculateFee(address tokenIn, uint amountIn, uint amountOut) public view returns (uint) {
        return fees(amountIn, amountOut, quote(tokenIn, amountIn));
    }







    function createOption(address tokenIn, uint amountIn, uint amountOut) external returns (uint) {
        reserveInUse = reserveInUse.add(amountOut);
        require(liquidityBalance() > reserveInUse, '::createOption: insufficient liquidity');

        IERC20(tokenIn).transferFrom(msg.sender, address(this), calculateFee(tokenIn, amountIn, amountOut));

        positions.push(position(msg.sender, tokenIn, amountIn, amountOut, block.timestamp, block.timestamp.add(PERIOD), true));
        options[msg.sender].push(nextIndex);

        emit Created(nextIndex, msg.sender, tokenIn, amountIn, amountOut, block.timestamp, block.timestamp.add(PERIOD));
        return nextIndex++;
    }






    function exercise(uint id) external returns (bool) {
        position storage _pos = positions[id];
        require(_pos.open, "::exercise: position is closed");
        require(_pos.expire < block.timestamp, "::exercise: position expired");
        IERC20(_pos.asset).transferFrom(msg.sender, address(this), _pos.amountIn);
        IERC20(reserve).transfer(msg.sender, _pos.amountOut);
        _pos.open = false;
        positions[id] = _pos;
        emit Excercised(id, _pos.owner, _pos.asset, _pos.amountIn, _pos.amountOut, _pos.created, _pos.expire);
        return true;
    }







    function allowance(address account, address spender) external view returns (uint) {
        return allowances[account][spender];
    }









    function approve(address spender, uint amount) public returns (bool) {
        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }











    function permit(address owner, address spender, uint amount, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, amount, nonces[owner]++, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "::permit: invalid signature");
        require(signatory == owner, "::permit: unauthorized");
        require(now <= deadline, "::permit: signature expired");

        allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }






    function balanceOf(address account) external view returns (uint) {
        return balances[account];
    }







    function transfer(address dst, uint amount) public returns (bool) {
        _transferTokens(msg.sender, dst, amount);
        return true;
    }








    function transferFrom(address src, address dst, uint amount) external returns (bool) {
        address spender = msg.sender;
        uint spenderAllowance = allowances[src][spender];

        if (spender != src && spenderAllowance != uint(-1)) {
            uint newAllowance = spenderAllowance.sub(amount, "::transferFrom: transfer amount exceeds spender allowance");
            allowances[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }

    function _transferTokens(address src, address dst, uint amount) internal {
        require(src != address(0), "::_transferTokens: cannot transfer from the zero address");
        require(dst != address(0), "::_transferTokens: cannot transfer to the zero address");

        balances[src] = balances[src].sub(amount, "::_transferTokens: transfer amount exceeds balance");
        balances[dst] = balances[dst].add(amount, "::_transferTokens: transfer amount overflows");
        emit Transfer(src, dst, amount);
    }

    function getChainId() internal pure returns (uint) {
        uint chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}
