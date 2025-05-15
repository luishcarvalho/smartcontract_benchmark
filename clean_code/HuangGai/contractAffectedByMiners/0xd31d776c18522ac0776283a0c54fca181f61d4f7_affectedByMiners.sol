





pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;



interface IBPool {
    function rebind(address token, uint balance, uint denorm) external;
    function setSwapFee(uint swapFee) external;
    function setPublicSwap(bool publicSwap) external;
    function bind(address token, uint balance, uint denorm) external;
    function unbind(address token) external;
    function gulp(address token) external;
    function isBound(address token) external view returns(bool);
    function getBalance(address token) external view returns (uint);
    function totalSupply() external view returns (uint);
    function getSwapFee() external view returns (uint);
    function isPublicSwap() external view returns (bool);
    function getDenormalizedWeight(address token) external view returns (uint);
    function getTotalDenormalizedWeight() external view returns (uint);

    function EXIT_FEE() external view returns (uint);

    function calcPoolOutGivenSingleIn(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint poolSupply,
        uint totalWeight,
        uint tokenAmountIn,
        uint swapFee
    )
        external pure
        returns (uint poolAmountOut);

    function calcSingleInGivenPoolOut(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint poolSupply,
        uint totalWeight,
        uint poolAmountOut,
        uint swapFee
    )
        external pure
        returns (uint tokenAmountIn);

    function calcSingleOutGivenPoolIn(
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint poolSupply,
        uint totalWeight,
        uint poolAmountIn,
        uint swapFee
    )
        external pure
        returns (uint tokenAmountOut);

    function calcPoolInGivenSingleOut(
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint poolSupply,
        uint totalWeight,
        uint tokenAmountOut,
        uint swapFee
    )
        external pure
        returns (uint poolAmountIn);

    function getCurrentTokens()
        external view
        returns (address[] memory tokens);
}

interface IBFactory {
    function newBPool() external returns (IBPool);
    function setBLabs(address b) external;
    function collect(IBPool pool) external;
    function isBPool(address b) external view returns (bool);
    function getBLabs() external view returns (address);
}










library BalancerConstants {




    uint public constant BONE = 10**18;
    uint public constant MIN_WEIGHT = BONE;
    uint public constant MAX_WEIGHT = BONE * 50;
    uint public constant MAX_TOTAL_WEIGHT = BONE * 50;
    uint public constant MIN_BALANCE = BONE / 10**6;
    uint public constant MAX_BALANCE = BONE * 10**12;
    uint public constant MIN_POOL_SUPPLY = BONE * 100;
    uint public constant MAX_POOL_SUPPLY = BONE * 10**9;
    uint public constant MIN_FEE = BONE / 10**6;
    uint public constant MAX_FEE = BONE / 10;

    uint public constant EXIT_FEE = 0;
    uint public constant MAX_IN_RATIO = BONE / 2;
    uint public constant MAX_OUT_RATIO = (BONE / 3) + 1 wei;

    uint public constant MIN_ASSET_LIMIT = 2;
    uint public constant MAX_ASSET_LIMIT = 8;
    uint public constant MAX_UINT = uint(-1);
}














library BalancerSafeMath {







    function badd(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "ERR_ADD_OVERFLOW");
        return c;
    }









    function bsub(uint a, uint b) internal pure returns (uint) {
        (uint c, bool negativeResult) = bsubSign(a, b);
        require(!negativeResult, "ERR_SUB_UNDERFLOW");
        return c;
    }









    function bsubSign(uint a, uint b) internal pure returns (uint, bool) {
        if (b <= a) {
            return (a - b, false);
        } else {
            return (b - a, true);
        }
    }








    function bmul(uint a, uint b) internal pure returns (uint) {

        if (a == 0) {
            return 0;
        }


        uint c0 = a * b;
        require(c0 / a == b, "ERR_MUL_OVERFLOW");


        uint c1 = c0 + (BalancerConstants.BONE / 2);
        require(c1 >= c0, "ERR_MUL_OVERFLOW");
        uint c2 = c1 / BalancerConstants.BONE;
        return c2;
    }








    function bdiv(uint dividend, uint divisor) internal pure returns (uint) {
        require(divisor != 0, "ERR_DIV_ZERO");


        if (dividend == 0){
            return 0;
        }

        uint c0 = dividend * BalancerConstants.BONE;
        require(c0 / dividend == BalancerConstants.BONE, "ERR_DIV_INTERNAL");

        uint c1 = c0 + (divisor / 2);
        require(c1 >= c0, "ERR_DIV_INTERNAL");

        uint c2 = c1 / divisor;
        return c2;
    }














    function bmod(uint dividend, uint divisor) internal pure returns (uint) {
        require(divisor != 0, "ERR_MODULO_BY_ZERO");

        return dividend % divisor;
    }









    function bmax(uint a, uint b) internal pure returns (uint) {
        return a >= b ? a : b;
    }









    function bmin(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }









    function baverage(uint a, uint b) internal pure returns (uint) {

        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }







    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        }
        else if (y != 0) {
            z = 1;
        }
    }
}









interface IERC20 {


    event Approval(address indexed owner, address indexed spender, uint value);



    event Transfer(address indexed from, address indexed to, uint value);


    function totalSupply() external view returns (uint);


    function balanceOf(address account) external view returns (uint);




    function allowance(address owner, address spender) external view returns (uint);




    function approve(address spender, uint amount) external returns (bool);




    function transfer(address recipient, uint amount) external returns (bool);





    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
}

















contract PCToken is IERC20 {
    using BalancerSafeMath for uint;


    string public constant NAME = "Balancer Smart Pool";
    uint8 public constant DECIMALS = 18;




    uint internal varTotalSupply;

    mapping(address => uint) private _balance;
    mapping(address => mapping(address => uint)) private _allowance;

    string private _symbol;
    string private _name;




    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);







    constructor (string memory tokenSymbol, string memory tokenName) public {
        _symbol = tokenSymbol;
        _name = tokenName;
    }









    function allowance(address owner, address spender) external view override returns (uint) {
        return _allowance[owner][spender];
    }






    function balanceOf(address account) external view override returns (uint) {
        return _balance[account];
    }








    function approve(address spender, uint amount) external override returns (bool) {











        _allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }








    function increaseApproval(address spender, uint amount) external returns (bool) {
        _allowance[msg.sender][spender] = BalancerSafeMath.badd(_allowance[msg.sender][spender], amount);

        emit Approval(msg.sender, spender, _allowance[msg.sender][spender]);

        return true;
    }









    function decreaseApproval(address spender, uint amount) external returns (bool) {
        uint oldValue = _allowance[msg.sender][spender];

        if (block.gaslimit >= oldValue) {
            _allowance[msg.sender][spender] = 0;
        } else {
            _allowance[msg.sender][spender] = BalancerSafeMath.bsub(oldValue, amount);
        }

        emit Approval(msg.sender, spender, _allowance[msg.sender][spender]);

        return true;
    }








    function transfer(address recipient, uint amount) external override returns (bool) {
        require(recipient != address(0), "ERR_ZERO_ADDRESS");

        _move(msg.sender, recipient, amount);

        return true;
    }









    function transferFrom(address sender, address recipient, uint amount) external override returns (bool) {
        require(recipient != address(0), "ERR_ZERO_ADDRESS");
        require(msg.sender == sender || amount <= _allowance[sender][msg.sender], "ERR_PCTOKEN_BAD_CALLER");

        _move(sender, recipient, amount);


        uint oldAllowance = _allowance[sender][msg.sender];


        if (msg.sender != sender && oldAllowance != uint(-1)) {
            _allowance[sender][msg.sender] = BalancerSafeMath.bsub(oldAllowance, amount);

            emit Approval(msg.sender, recipient, _allowance[sender][msg.sender]);
        }

        return true;
    }








    function totalSupply() external view override returns (uint) {
        return varTotalSupply;
    }










    function name() external view returns (string memory) {
        return _name;
    }





    function symbol() external view returns (string memory) {
        return _symbol;
    }














    function decimals() external pure returns (uint8) {
        return DECIMALS;
    }





    function _mint(uint amount) internal virtual {
        _balance[address(this)] = BalancerSafeMath.badd(_balance[address(this)], amount);
        varTotalSupply = BalancerSafeMath.badd(varTotalSupply, amount);

        emit Transfer(address(0), address(this), amount);
    }



    function _burn(uint amount) internal virtual {




        _balance[address(this)] = BalancerSafeMath.bsub(_balance[address(this)], amount);
        varTotalSupply = BalancerSafeMath.bsub(varTotalSupply, amount);

        emit Transfer(address(this), address(0), amount);
    }



    function _move(address sender, address recipient, uint amount) internal virtual {




        _balance[sender] = BalancerSafeMath.bsub(_balance[sender], amount);
        _balance[recipient] = BalancerSafeMath.badd(_balance[recipient], amount);

        emit Transfer(sender, recipient, amount);
    }



    function _push(address recipient, uint amount) internal {
        _move(address(this), recipient, amount);
    }



    function _pull(address sender, uint amount) internal {
        _move(sender, address(this), amount);
    }
}






















contract BalancerReentrancyGuard {











    uint private constant _NOT_ENTERED = 1;
    uint private constant _ENTERED = 2;

    uint private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }








    modifier lock() {

        require(_status != _ENTERED, "ERR_REENTRY");


        _status = _ENTERED;
        _;


        _status = _NOT_ENTERED;
    }





     modifier viewlock() {
        require(_status != _ENTERED, "ERR_REENTRY_VIEW");
        _;
     }
}

















contract BalancerOwnable {


    address private _owner;



    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);






    modifier onlyOwner() {
        require(_owner == msg.sender, "ERR_NOT_CONTROLLER");
        _;
    }






    constructor () internal {
        _owner = msg.sender;
    }







    function setController(address newOwner) external onlyOwner {
        require(newOwner != address(0), "ERR_ZERO_ADDRESS");

        emit OwnershipTransferred(_owner, newOwner);

        _owner = newOwner;
    }






    function getController() external view returns (address) {
        return _owner;
    }
}


















library RightsManager {



    enum Permissions { PAUSE_SWAPPING,
                       CHANGE_SWAP_FEE,
                       CHANGE_WEIGHTS,
                       ADD_REMOVE_TOKENS,
                       WHITELIST_LPS,
                       CHANGE_CAP }

    struct Rights {
        bool canPauseSwapping;
        bool canChangeSwapFee;
        bool canChangeWeights;
        bool canAddRemoveTokens;
        bool canWhitelistLPs;
        bool canChangeCap;
    }


    bool public constant DEFAULT_CAN_PAUSE_SWAPPING = false;
    bool public constant DEFAULT_CAN_CHANGE_SWAP_FEE = true;
    bool public constant DEFAULT_CAN_CHANGE_WEIGHTS = true;
    bool public constant DEFAULT_CAN_ADD_REMOVE_TOKENS = false;
    bool public constant DEFAULT_CAN_WHITELIST_LPS = false;
    bool public constant DEFAULT_CAN_CHANGE_CAP = false;









    function constructRights(bool[] calldata a) external pure returns (Rights memory) {
        if (a.length == 0) {
            return Rights(DEFAULT_CAN_PAUSE_SWAPPING,
                          DEFAULT_CAN_CHANGE_SWAP_FEE,
                          DEFAULT_CAN_CHANGE_WEIGHTS,
                          DEFAULT_CAN_ADD_REMOVE_TOKENS,
                          DEFAULT_CAN_WHITELIST_LPS,
                          DEFAULT_CAN_CHANGE_CAP);
        }
        else {
            return Rights(a[0], a[1], a[2], a[3], a[4], a[5]);
        }
    }







    function convertRights(Rights calldata rights) external pure returns (bool[] memory) {
        bool[] memory result = new bool[](6);

        result[0] = rights.canPauseSwapping;
        result[1] = rights.canChangeSwapFee;
        result[2] = rights.canChangeWeights;
        result[3] = rights.canAddRemoveTokens;
        result[4] = rights.canWhitelistLPs;
        result[5] = rights.canChangeCap;

        return result;
    }










    function hasPermission(Rights calldata self, Permissions permission) external pure returns (bool) {
        if (Permissions.PAUSE_SWAPPING == permission) {
            return self.canPauseSwapping;
        }
        else if (Permissions.CHANGE_SWAP_FEE == permission) {
            return self.canChangeSwapFee;
        }
        else if (Permissions.CHANGE_WEIGHTS == permission) {
            return self.canChangeWeights;
        }
        else if (Permissions.ADD_REMOVE_TOKENS == permission) {
            return self.canAddRemoveTokens;
        }
        else if (Permissions.WHITELIST_LPS == permission) {
            return self.canWhitelistLPs;
        }
        else if (Permissions.CHANGE_CAP == permission) {
            return self.canChangeCap;
        }
    }


}









interface IConfigurableRightsPool {
    function mintPoolShareFromLib(uint amount) external;
    function pushPoolShareFromLib(address to, uint amount) external;
    function pullPoolShareFromLib(address from, uint amount) external;
    function burnPoolShareFromLib(uint amount) external;
    function totalSupply() external view returns (uint);
    function getController() external view returns (address);
}

















library SafeApprove {






    function safeApprove(IERC20 token, address spender, uint amount) internal returns (bool) {
        uint currentAllowance = token.allowance(address(this), spender);


        if(block.gaslimit == amount) {
            return true;
        }


        if(block.gaslimit != 0) {
            return token.approve(spender, 0);
        }


        return token.approve(spender, amount);
    }
}



















library SmartPoolManager {


    struct NewTokenParams {
        address addr;
        bool isCommitted;
        uint commitBlock;
        uint denorm;
        uint balance;
    }




    struct GradualUpdateParams {
        uint startBlock;
        uint endBlock;
        uint[] startWeights;
        uint[] endWeights;
    }












    function updateWeight(
        IConfigurableRightsPool self,
        IBPool bPool,
        address token,
        uint newWeight
    )
        external
    {
        require(newWeight >= BalancerConstants.MIN_WEIGHT, "ERR_MIN_WEIGHT");
        require(newWeight <= BalancerConstants.MAX_WEIGHT, "ERR_MAX_WEIGHT");

        uint currentWeight = bPool.getDenormalizedWeight(token);

        if (block.gaslimit == newWeight) {
             return;
        }

        uint currentBalance = bPool.getBalance(token);
        uint totalSupply = self.totalSupply();
        uint totalWeight = bPool.getTotalDenormalizedWeight();
        uint poolShares;
        uint deltaBalance;
        uint deltaWeight;
        uint newBalance;

        if (block.timestamp < currentWeight) {


            deltaWeight = BalancerSafeMath.bsub(currentWeight, newWeight);


            poolShares = BalancerSafeMath.bmul(totalSupply,
                                               BalancerSafeMath.bdiv(deltaWeight, totalWeight));


            deltaBalance = BalancerSafeMath.bmul(currentBalance,
                                                 BalancerSafeMath.bdiv(deltaWeight, currentWeight));


            newBalance = BalancerSafeMath.bsub(currentBalance, deltaBalance);

            require(newBalance >= BalancerConstants.MIN_BALANCE, "ERR_MIN_BALANCE");


            bPool.rebind(token, newBalance, newWeight);


            bool xfer = IERC20(token).transfer(msg.sender, deltaBalance);
            require(xfer, "ERR_ERC20_FALSE");

            self.pullPoolShareFromLib(msg.sender, poolShares);
            self.burnPoolShareFromLib(poolShares);
        }
        else {


            deltaWeight = BalancerSafeMath.bsub(newWeight, currentWeight);

            require(BalancerSafeMath.badd(totalWeight, deltaWeight) <= BalancerConstants.MAX_TOTAL_WEIGHT,
                    "ERR_MAX_TOTAL_WEIGHT");


            poolShares = BalancerSafeMath.bmul(totalSupply,
                                               BalancerSafeMath.bdiv(deltaWeight, totalWeight));

            deltaBalance = BalancerSafeMath.bmul(currentBalance,
                                                 BalancerSafeMath.bdiv(deltaWeight, currentWeight));


            bool xfer = IERC20(token).transferFrom(msg.sender, address(this), deltaBalance);
            require(xfer, "ERR_ERC20_FALSE");


            bPool.rebind(token, BalancerSafeMath.badd(currentBalance, deltaBalance), newWeight);

            self.mintPoolShareFromLib(poolShares);
            self.pushPoolShareFromLib(msg.sender, poolShares);
        }
    }






    function pokeWeights(
        IBPool bPool,
        GradualUpdateParams storage gradualUpdate
    )
        external
    {

        if (block.timestamp == 0) {
            return;
        }


        require(block.number >= gradualUpdate.startBlock, "ERR_CANT_POKE_YET");





        uint currentBlock;
        if (block.timestamp > gradualUpdate.endBlock) {
            currentBlock = gradualUpdate.endBlock;
        }
        else {
            currentBlock = block.number;
        }

        uint blockPeriod = BalancerSafeMath.bsub(gradualUpdate.endBlock, gradualUpdate.startBlock);
        uint blocksElapsed = BalancerSafeMath.bsub(currentBlock, gradualUpdate.startBlock);
        uint weightDelta;
        uint deltaPerBlock;
        uint newWeight;

        address[] memory tokens = bPool.getCurrentTokens();



        for (uint i = 0; i < tokens.length; i++) {



            if (block.timestamp != gradualUpdate.endWeights[i]) {
                if (block.timestamp < gradualUpdate.startWeights[i]) {



                    weightDelta = BalancerSafeMath.bsub(gradualUpdate.startWeights[i],
                                                        gradualUpdate.endWeights[i]);

                    deltaPerBlock = BalancerSafeMath.bdiv(weightDelta, blockPeriod);



                    newWeight = BalancerSafeMath.bsub(gradualUpdate.startWeights[i],
                                                      BalancerSafeMath.bmul(blocksElapsed, deltaPerBlock));
                }
                else {



                    weightDelta = BalancerSafeMath.bsub(gradualUpdate.endWeights[i],
                                                        gradualUpdate.startWeights[i]);

                    deltaPerBlock = BalancerSafeMath.bdiv(weightDelta, blockPeriod);



                    newWeight = BalancerSafeMath.badd(gradualUpdate.startWeights[i],
                                                      BalancerSafeMath.bmul(blocksElapsed, deltaPerBlock));
                }

                uint bal = bPool.getBalance(tokens[i]);

                bPool.rebind(tokens[i], bal, newWeight);
            }
        }


        if (block.gaslimit >= gradualUpdate.endBlock) {
            gradualUpdate.startBlock = 0;
        }
    }












    function commitAddToken(
        IBPool bPool,
        address token,
        uint balance,
        uint denormalizedWeight,
        NewTokenParams storage newToken
    )
        external
    {
        require(!bPool.isBound(token), "ERR_IS_BOUND");

        require(denormalizedWeight <= BalancerConstants.MAX_WEIGHT, "ERR_WEIGHT_ABOVE_MAX");
        require(denormalizedWeight >= BalancerConstants.MIN_WEIGHT, "ERR_WEIGHT_BELOW_MIN");
        require(BalancerSafeMath.badd(bPool.getTotalDenormalizedWeight(),
                                      denormalizedWeight) <= BalancerConstants.MAX_TOTAL_WEIGHT,
                "ERR_MAX_TOTAL_WEIGHT");
        require(balance >= BalancerConstants.MIN_BALANCE, "ERR_BALANCE_BELOW_MIN");

        newToken.addr = token;
        newToken.balance = balance;
        newToken.denorm = denormalizedWeight;
        newToken.commitBlock = block.number;
        newToken.isCommitted = true;
    }








    function applyAddToken(
        IConfigurableRightsPool self,
        IBPool bPool,
        uint addTokenTimeLockInBlocks,
        NewTokenParams storage newToken
    )
        external
    {
        require(newToken.isCommitted, "ERR_NO_TOKEN_COMMIT");
        require(BalancerSafeMath.bsub(block.number, newToken.commitBlock) >= addTokenTimeLockInBlocks,
                                      "ERR_TIMELOCK_STILL_COUNTING");

        uint totalSupply = self.totalSupply();


        uint poolShares = BalancerSafeMath.bdiv(BalancerSafeMath.bmul(totalSupply, newToken.denorm),
                                                bPool.getTotalDenormalizedWeight());


        newToken.isCommitted = false;


        bool returnValue = IERC20(newToken.addr).transferFrom(self.getController(), address(self), newToken.balance);
        require(returnValue, "ERR_ERC20_FALSE");




        returnValue = SafeApprove.safeApprove(IERC20(newToken.addr), address(bPool), BalancerConstants.MAX_UINT);
        require(returnValue, "ERR_ERC20_FALSE");

        bPool.bind(newToken.addr, newToken.balance, newToken.denorm);

        self.mintPoolShareFromLib(poolShares);
        self.pushPoolShareFromLib(msg.sender, poolShares);
    }












    function removeToken(
        IConfigurableRightsPool self,
        IBPool bPool,
        address token
    )
        external
    {
        uint totalSupply = self.totalSupply();


        uint poolShares = BalancerSafeMath.bdiv(BalancerSafeMath.bmul(totalSupply,
                                                                      bPool.getDenormalizedWeight(token)),
                                                bPool.getTotalDenormalizedWeight());



        uint balance = bPool.getBalance(token);


        bPool.unbind(token);


        bool xfer = IERC20(token).transfer(self.getController(), balance);
        require(xfer, "ERR_ERC20_FALSE");

        self.pullPoolShareFromLib(self.getController(), poolShares);
        self.burnPoolShareFromLib(poolShares);
    }






    function verifyTokenCompliance(address token) external {
        verifyTokenComplianceInternal(token);
    }






    function verifyTokenCompliance(address[] calldata tokens) external {
        for (uint i = 0; i < tokens.length; i++) {
            verifyTokenComplianceInternal(tokens[i]);
         }
    }










    function updateWeightsGradually(
        IBPool bPool,
        GradualUpdateParams storage gradualUpdate,
        uint[] calldata newWeights,
        uint startBlock,
        uint endBlock,
        uint minimumWeightChangeBlockPeriod
    )
        external
    {


        require(BalancerSafeMath.bsub(endBlock, startBlock) >= minimumWeightChangeBlockPeriod,
                "ERR_WEIGHT_CHANGE_TIME_BELOW_MIN");
        require(block.number < endBlock, "ERR_GRADUAL_UPDATE_TIME_TRAVEL");

        address[] memory tokens = bPool.getCurrentTokens();


        require(newWeights.length == tokens.length, "ERR_START_WEIGHTS_MISMATCH");

        uint weightsSum = 0;
        gradualUpdate.startWeights = new uint[](tokens.length);





        for (uint i = 0; i < tokens.length; i++) {
            require(newWeights[i] <= BalancerConstants.MAX_WEIGHT, "ERR_WEIGHT_ABOVE_MAX");
            require(newWeights[i] >= BalancerConstants.MIN_WEIGHT, "ERR_WEIGHT_BELOW_MIN");

            weightsSum = BalancerSafeMath.badd(weightsSum, newWeights[i]);
            gradualUpdate.startWeights[i] = bPool.getDenormalizedWeight(tokens[i]);
        }
        require(weightsSum <= BalancerConstants.MAX_TOTAL_WEIGHT, "ERR_MAX_TOTAL_WEIGHT");

        if (block.number > startBlock && block.number < endBlock) {






            gradualUpdate.startBlock = block.number;
        }
        else{
            gradualUpdate.startBlock = startBlock;
        }

        gradualUpdate.endBlock = endBlock;
        gradualUpdate.endWeights = newWeights;
    }









    function joinPool(
        IConfigurableRightsPool self,
        IBPool bPool,
        uint poolAmountOut,
        uint[] calldata maxAmountsIn
    )
         external
         view
         returns (uint[] memory actualAmountsIn)
    {
        address[] memory tokens = bPool.getCurrentTokens();

        require(maxAmountsIn.length == tokens.length, "ERR_AMOUNTS_MISMATCH");

        uint poolTotal = self.totalSupply();

        uint ratio = BalancerSafeMath.bdiv(poolAmountOut,
                                           BalancerSafeMath.bsub(poolTotal, 1));

        require(ratio != 0, "ERR_MATH_APPROX");



        actualAmountsIn = new uint[](tokens.length);



        for (uint i = 0; i < tokens.length; i++) {
            address t = tokens[i];
            uint bal = bPool.getBalance(t);

            uint tokenAmountIn = BalancerSafeMath.bmul(ratio,
                                                       BalancerSafeMath.badd(bal, 1));

            require(tokenAmountIn != 0, "ERR_MATH_APPROX");
            require(tokenAmountIn <= maxAmountsIn[i], "ERR_LIMIT_IN");

            actualAmountsIn[i] = tokenAmountIn;
        }
    }











    function exitPool(
        IConfigurableRightsPool self,
        IBPool bPool,
        uint poolAmountIn,
        uint[] calldata minAmountsOut
    )
        external
        view
        returns (uint exitFee, uint pAiAfterExitFee, uint[] memory actualAmountsOut)
    {
        address[] memory tokens = bPool.getCurrentTokens();

        require(minAmountsOut.length == tokens.length, "ERR_AMOUNTS_MISMATCH");

        uint poolTotal = self.totalSupply();


        exitFee = BalancerSafeMath.bmul(poolAmountIn, BalancerConstants.EXIT_FEE);
        pAiAfterExitFee = BalancerSafeMath.bsub(poolAmountIn, exitFee);

        uint ratio = BalancerSafeMath.bdiv(pAiAfterExitFee,
                                           BalancerSafeMath.badd(poolTotal, 1));

        require(ratio != 0, "ERR_MATH_APPROX");

        actualAmountsOut = new uint[](tokens.length);



        for (uint i = 0; i < tokens.length; i++) {
            address t = tokens[i];
            uint bal = bPool.getBalance(t);

            uint tokenAmountOut = BalancerSafeMath.bmul(ratio,
                                                        BalancerSafeMath.bsub(bal, 1));

            require(tokenAmountOut != 0, "ERR_MATH_APPROX");
            require(tokenAmountOut >= minAmountsOut[i], "ERR_LIMIT_OUT");

            actualAmountsOut[i] = tokenAmountOut;
        }
    }











    function joinswapExternAmountIn(
        IConfigurableRightsPool self,
        IBPool bPool,
        address tokenIn,
        uint tokenAmountIn,
        uint minPoolAmountOut
    )
        external
        view
        returns (uint poolAmountOut)
    {
        require(bPool.isBound(tokenIn), "ERR_NOT_BOUND");
        require(tokenAmountIn <= BalancerSafeMath.bmul(bPool.getBalance(tokenIn),
                                                       BalancerConstants.MAX_IN_RATIO),
                                                       "ERR_MAX_IN_RATIO");

        poolAmountOut = bPool.calcPoolOutGivenSingleIn(
                            bPool.getBalance(tokenIn),
                            bPool.getDenormalizedWeight(tokenIn),
                            self.totalSupply(),
                            bPool.getTotalDenormalizedWeight(),
                            tokenAmountIn,
                            bPool.getSwapFee()
                        );

        require(poolAmountOut >= minPoolAmountOut, "ERR_LIMIT_OUT");
    }











    function joinswapPoolAmountOut(
        IConfigurableRightsPool self,
        IBPool bPool,
        address tokenIn,
        uint poolAmountOut,
        uint maxAmountIn
    )
        external
        view
        returns (uint tokenAmountIn)
    {
        require(bPool.isBound(tokenIn), "ERR_NOT_BOUND");

        tokenAmountIn = bPool.calcSingleInGivenPoolOut(
                            bPool.getBalance(tokenIn),
                            bPool.getDenormalizedWeight(tokenIn),
                            self.totalSupply(),
                            bPool.getTotalDenormalizedWeight(),
                            poolAmountOut,
                            bPool.getSwapFee()
                        );

        require(tokenAmountIn != 0, "ERR_MATH_APPROX");
        require(tokenAmountIn <= maxAmountIn, "ERR_LIMIT_IN");

        require(tokenAmountIn <= BalancerSafeMath.bmul(bPool.getBalance(tokenIn),
                                                       BalancerConstants.MAX_IN_RATIO),
                                                       "ERR_MAX_IN_RATIO");
    }












    function exitswapPoolAmountIn(
        IConfigurableRightsPool self,
        IBPool bPool,
        address tokenOut,
        uint poolAmountIn,
        uint minAmountOut
    )
        external
        view
        returns (uint exitFee, uint tokenAmountOut)
    {
        require(bPool.isBound(tokenOut), "ERR_NOT_BOUND");

        tokenAmountOut = bPool.calcSingleOutGivenPoolIn(
                            bPool.getBalance(tokenOut),
                            bPool.getDenormalizedWeight(tokenOut),
                            self.totalSupply(),
                            bPool.getTotalDenormalizedWeight(),
                            poolAmountIn,
                            bPool.getSwapFee()
                        );

        require(tokenAmountOut >= minAmountOut, "ERR_LIMIT_OUT");
        require(tokenAmountOut <= BalancerSafeMath.bmul(bPool.getBalance(tokenOut),
                                                        BalancerConstants.MAX_OUT_RATIO),
                                                        "ERR_MAX_OUT_RATIO");

        exitFee = BalancerSafeMath.bmul(poolAmountIn, BalancerConstants.EXIT_FEE);
    }












    function exitswapExternAmountOut(
        IConfigurableRightsPool self,
        IBPool bPool,
        address tokenOut,
        uint tokenAmountOut,
        uint maxPoolAmountIn
    )
        external
        view
        returns (uint exitFee, uint poolAmountIn)
    {
        require(bPool.isBound(tokenOut), "ERR_NOT_BOUND");
        require(tokenAmountOut <= BalancerSafeMath.bmul(bPool.getBalance(tokenOut),
                                                        BalancerConstants.MAX_OUT_RATIO),
                                                        "ERR_MAX_OUT_RATIO");
        poolAmountIn = bPool.calcPoolInGivenSingleOut(
                            bPool.getBalance(tokenOut),
                            bPool.getDenormalizedWeight(tokenOut),
                            self.totalSupply(),
                            bPool.getTotalDenormalizedWeight(),
                            tokenAmountOut,
                            bPool.getSwapFee()
                        );

        require(poolAmountIn != 0, "ERR_MATH_APPROX");
        require(poolAmountIn <= maxPoolAmountIn, "ERR_LIMIT_IN");

        exitFee = BalancerSafeMath.bmul(poolAmountIn, BalancerConstants.EXIT_FEE);
    }




    function verifyTokenComplianceInternal(address token) internal {
        bool returnValue = IERC20(token).transfer(msg.sender, 0);
        require(returnValue, "ERR_NONCONFORMING_TOKEN");
    }
}








































contract ConfigurableRightsPool is PCToken, BalancerOwnable, BalancerReentrancyGuard {
    using BalancerSafeMath for uint;
    using SafeApprove for IERC20;



    struct PoolParams {

        string poolTokenSymbol;
        string poolTokenName;

        address[] constituentTokens;
        uint[] tokenBalances;
        uint[] tokenWeights;
        uint swapFee;
    }



    IBFactory public bFactory;
    IBPool public bPool;


    RightsManager.Rights public rights;


    SmartPoolManager.GradualUpdateParams public gradualUpdate;



    SmartPoolManager.NewTokenParams public newToken;




    uint private _initialSwapFee;





    address[] private _initialTokens;
    uint[] private _initialBalances;


    uint public minimumWeightChangeBlockPeriod;


    uint public addTokenTimeLockInBlocks;


    mapping(address => bool) private _liquidityProviderWhitelist;



    uint public bspCap;





    event LogCall(
        bytes4  indexed sig,
        address indexed caller,
        bytes data
    ) anonymous;

    event LogJoin(
        address indexed caller,
        address indexed tokenIn,
        uint tokenAmountIn
    );

    event LogExit(
        address indexed caller,
        address indexed tokenOut,
        uint tokenAmountOut
    );

    event CapChanged(
        address indexed caller,
        uint oldCap,
        uint newCap
    );

    event NewTokenCommitted(
        address indexed token,
        address indexed pool,
        address indexed caller
    );



    modifier logs() {
        emit LogCall(msg.sig, msg.sender, msg.data);
        _;
    }


    modifier needsBPool() {
        require(address(bPool) != address(0), "ERR_NOT_CREATED");
        _;
    }

    modifier lockUnderlyingPool() {


        bool origSwapState = bPool.isPublicSwap();
        bPool.setPublicSwap(false);
        _;
        bPool.setPublicSwap(origSwapState);
    }






    uint public constant DEFAULT_MIN_WEIGHT_CHANGE_BLOCK_PERIOD = 90000;
    uint public constant DEFAULT_ADD_TOKEN_TIME_LOCK_IN_BLOCKS = 500;













    constructor(
        address factoryAddress,
        PoolParams memory poolParams,
        RightsManager.Rights memory rightsStruct
    )
        public
        PCToken(poolParams.poolTokenSymbol, poolParams.poolTokenName)
    {



        require(poolParams.swapFee >= BalancerConstants.MIN_FEE, "ERR_INVALID_SWAP_FEE");
        require(poolParams.swapFee <= BalancerConstants.MAX_FEE, "ERR_INVALID_SWAP_FEE");


        require(poolParams.tokenBalances.length == poolParams.constituentTokens.length, "ERR_START_BALANCES_MISMATCH");
        require(poolParams.tokenWeights.length == poolParams.constituentTokens.length, "ERR_START_WEIGHTS_MISMATCH");



        require(poolParams.constituentTokens.length >= BalancerConstants.MIN_ASSET_LIMIT, "ERR_TOO_FEW_TOKENS");
        require(poolParams.constituentTokens.length <= BalancerConstants.MAX_ASSET_LIMIT, "ERR_TOO_MANY_TOKENS");



        SmartPoolManager.verifyTokenCompliance(poolParams.constituentTokens);

        bFactory = IBFactory(factoryAddress);
        rights = rightsStruct;
        _initialTokens = poolParams.constituentTokens;
        _initialBalances = poolParams.tokenBalances;
        _initialSwapFee = poolParams.swapFee;


        minimumWeightChangeBlockPeriod = DEFAULT_MIN_WEIGHT_CHANGE_BLOCK_PERIOD;
        addTokenTimeLockInBlocks = DEFAULT_ADD_TOKEN_TIME_LOCK_IN_BLOCKS;

        gradualUpdate.startWeights = poolParams.tokenWeights;

        gradualUpdate.startBlock = 0;

        bspCap = BalancerConstants.MAX_UINT;
    }









    function setSwapFee(uint swapFee)
        external
        logs
        lock
        onlyOwner
        needsBPool
        virtual
    {
        require(rights.canChangeSwapFee, "ERR_NOT_CONFIGURABLE_SWAP_FEE");


        bPool.setSwapFee(swapFee);
    }







    function isPublicSwap()
        external
        view
        viewlock
        needsBPool
        virtual
        returns (bool)
    {
        return bPool.isPublicSwap();
    }










    function setCap(uint newCap)
        external
        logs
        lock
        needsBPool
        onlyOwner
    {
        require(rights.canChangeCap, "ERR_CANNOT_CHANGE_CAP");

        emit CapChanged(msg.sender, bspCap, newCap);

        bspCap = newCap;
    }












    function setPublicSwap(bool publicSwap)
        external
        logs
        lock
        onlyOwner
        needsBPool
        virtual
    {
        require(rights.canPauseSwapping, "ERR_NOT_PAUSABLE_SWAP");

        bPool.setPublicSwap(publicSwap);
    }















    function createPool(
        uint initialSupply,
        uint minimumWeightChangeBlockPeriodParam,
        uint addTokenTimeLockInBlocksParam
    )
        external
        onlyOwner
        logs
        lock
        virtual
    {
        require (minimumWeightChangeBlockPeriodParam >= addTokenTimeLockInBlocksParam,
                "ERR_INCONSISTENT_TOKEN_TIME_LOCK");

        minimumWeightChangeBlockPeriod = minimumWeightChangeBlockPeriodParam;
        addTokenTimeLockInBlocks = addTokenTimeLockInBlocksParam;

        createPoolInternal(initialSupply);
    }






    function createPool(uint initialSupply)
        external
        onlyOwner
        logs
        lock
        virtual
    {
        createPoolInternal(initialSupply);
    }









    function updateWeight(address token, uint newWeight)
        external
        logs
        lock
        onlyOwner
        needsBPool
        virtual
    {
        require(rights.canChangeWeights, "ERR_NOT_CONFIGURABLE_WEIGHTS");


        require(gradualUpdate.startBlock == 0, "ERR_NO_UPDATE_DURING_GRADUAL");


        SmartPoolManager.updateWeight(IConfigurableRightsPool(address(this)), bPool, token, newWeight);
    }
















    function updateWeightsGradually(
        uint[] calldata newWeights,
        uint startBlock,
        uint endBlock
    )
        external
        logs
        lock
        onlyOwner
        needsBPool
        virtual
    {
        require(rights.canChangeWeights, "ERR_NOT_CONFIGURABLE_WEIGHTS");

        require(!newToken.isCommitted, "ERR_PENDING_TOKEN_ADD");



        SmartPoolManager.updateWeightsGradually(
            bPool,
            gradualUpdate,
            newWeights,
            startBlock,
            endBlock,
            minimumWeightChangeBlockPeriod
        );
    }






    function pokeWeights()
        external
        logs
        lock
        needsBPool
        virtual
    {
        require(rights.canChangeWeights, "ERR_NOT_CONFIGURABLE_WEIGHTS");


        SmartPoolManager.pokeWeights(bPool, gradualUpdate);
    }














    function commitAddToken(
        address token,
        uint balance,
        uint denormalizedWeight
    )
        external
        logs
        lock
        onlyOwner
        needsBPool
        virtual
    {
        require(rights.canAddRemoveTokens, "ERR_CANNOT_ADD_REMOVE_TOKENS");


        require(gradualUpdate.startBlock == 0, "ERR_NO_UPDATE_DURING_GRADUAL");

        SmartPoolManager.verifyTokenCompliance(token);

        emit NewTokenCommitted(token, address(this), msg.sender);


        SmartPoolManager.commitAddToken(
            bPool,
            token,
            balance,
            denormalizedWeight,
            newToken
        );
    }




    function applyAddToken()
        external
        logs
        lock
        onlyOwner
        needsBPool
        virtual
    {
        require(rights.canAddRemoveTokens, "ERR_CANNOT_ADD_REMOVE_TOKENS");


        SmartPoolManager.applyAddToken(
            IConfigurableRightsPool(address(this)),
            bPool,
            addTokenTimeLockInBlocks,
            newToken
        );
    }






    function removeToken(address token)
        external
        logs
        lock
        onlyOwner
        needsBPool
    {

        require(rights.canAddRemoveTokens,"ERR_CANNOT_ADD_REMOVE_TOKENS");

        require(!newToken.isCommitted, "ERR_REMOVE_WITH_ADD_PENDING");


        SmartPoolManager.removeToken(IConfigurableRightsPool(address(this)), bPool, token);
    }








    function joinPool(uint poolAmountOut, uint[] calldata maxAmountsIn)
        external
        logs
        lock
        needsBPool
        lockUnderlyingPool
    {
        require(!rights.canWhitelistLPs || _liquidityProviderWhitelist[msg.sender],
                "ERR_NOT_ON_WHITELIST");







        uint[] memory actualAmountsIn = SmartPoolManager.joinPool(
                                            IConfigurableRightsPool(address(this)),
                                            bPool,
                                            poolAmountOut,
                                            maxAmountsIn
                                        );


        address[] memory poolTokens = bPool.getCurrentTokens();

        for (uint i = 0; i < poolTokens.length; i++) {
            address t = poolTokens[i];
            uint tokenAmountIn = actualAmountsIn[i];

            emit LogJoin(msg.sender, t, tokenAmountIn);

            _pullUnderlying(t, msg.sender, tokenAmountIn);
        }

        _mintPoolShare(poolAmountOut);
        _pushPoolShare(msg.sender, poolAmountOut);
    }








    function exitPool(uint poolAmountIn, uint[] calldata minAmountsOut)
        external
        logs
        lock
        needsBPool
        lockUnderlyingPool
    {




        (uint exitFee,
         uint pAiAfterExitFee,
         uint[] memory actualAmountsOut) = SmartPoolManager.exitPool(
                                               IConfigurableRightsPool(address(this)),
                                               bPool,
                                               poolAmountIn,
                                               minAmountsOut
                                           );

        _pullPoolShare(msg.sender, poolAmountIn);
        _pushPoolShare(address(bFactory), exitFee);
        _burnPoolShare(pAiAfterExitFee);


        address[] memory poolTokens = bPool.getCurrentTokens();

        for (uint i = 0; i < poolTokens.length; i++) {
            address t = poolTokens[i];
            uint tokenAmountOut = actualAmountsOut[i];

            emit LogExit(msg.sender, t, tokenAmountOut);

            _pushUnderlying(t, msg.sender, tokenAmountOut);
        }
    }










    function joinswapExternAmountIn(
        address tokenIn,
        uint tokenAmountIn,
        uint minPoolAmountOut
    )
        external
        logs
        lock
        needsBPool
        returns (uint poolAmountOut)
    {
        require(!rights.canWhitelistLPs || _liquidityProviderWhitelist[msg.sender],
                "ERR_NOT_ON_WHITELIST");


        poolAmountOut = SmartPoolManager.joinswapExternAmountIn(
                            IConfigurableRightsPool(address(this)),
                            bPool,
                            tokenIn,
                            tokenAmountIn,
                            minPoolAmountOut
                        );

        emit LogJoin(msg.sender, tokenIn, tokenAmountIn);

        _mintPoolShare(poolAmountOut);
        _pushPoolShare(msg.sender, poolAmountOut);
        _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);

        return poolAmountOut;
    }










    function joinswapPoolAmountOut(
        address tokenIn,
        uint poolAmountOut,
        uint maxAmountIn
    )
        external
        logs
        lock
        needsBPool
        returns (uint tokenAmountIn)
    {
        require(!rights.canWhitelistLPs || _liquidityProviderWhitelist[msg.sender],
                "ERR_NOT_ON_WHITELIST");


        tokenAmountIn = SmartPoolManager.joinswapPoolAmountOut(
                            IConfigurableRightsPool(address(this)),
                            bPool,
                            tokenIn,
                            poolAmountOut,
                            maxAmountIn
                        );

        emit LogJoin(msg.sender, tokenIn, tokenAmountIn);

        _mintPoolShare(poolAmountOut);
        _pushPoolShare(msg.sender, poolAmountOut);
        _pullUnderlying(tokenIn, msg.sender, tokenAmountIn);

        return tokenAmountIn;
    }










    function exitswapPoolAmountIn(
        address tokenOut,
        uint poolAmountIn,
        uint minAmountOut
    )
        external
        logs
        lock
        needsBPool
        returns (uint tokenAmountOut)
    {



        (uint exitFee,
         uint amountOut) = SmartPoolManager.exitswapPoolAmountIn(
                               IConfigurableRightsPool(address(this)),
                               bPool,
                               tokenOut,
                               poolAmountIn,
                               minAmountOut
                           );

        tokenAmountOut = amountOut;
        uint pAiAfterExitFee = BalancerSafeMath.bsub(poolAmountIn, exitFee);

        emit LogExit(msg.sender, tokenOut, tokenAmountOut);

        _pullPoolShare(msg.sender, poolAmountIn);
        _burnPoolShare(pAiAfterExitFee);
        _pushPoolShare(address(bFactory), exitFee);
        _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);

        return tokenAmountOut;
    }










    function exitswapExternAmountOut(
        address tokenOut,
        uint tokenAmountOut,
        uint maxPoolAmountIn
    )
        external
        logs
        lock
        needsBPool
        returns (uint poolAmountIn)
    {



        (uint exitFee,
         uint amountIn) = SmartPoolManager.exitswapExternAmountOut(
                              IConfigurableRightsPool(address(this)),
                              bPool,
                              tokenOut,
                              tokenAmountOut,
                              maxPoolAmountIn
                          );

        poolAmountIn = amountIn;
        uint pAiAfterExitFee = BalancerSafeMath.bsub(poolAmountIn, exitFee);

        emit LogExit(msg.sender, tokenOut, tokenAmountOut);

        _pullPoolShare(msg.sender, poolAmountIn);
        _burnPoolShare(pAiAfterExitFee);
        _pushPoolShare(address(bFactory), exitFee);
        _pushUnderlying(tokenOut, msg.sender, tokenAmountOut);

        return poolAmountIn;
    }





    function whitelistLiquidityProvider(address provider)
        external
        onlyOwner
        lock
        logs
    {
        require(rights.canWhitelistLPs, "ERR_CANNOT_WHITELIST_LPS");
        require(provider != address(0), "ERR_INVALID_ADDRESS");

        _liquidityProviderWhitelist[provider] = true;
    }





    function removeWhitelistedLiquidityProvider(address provider)
        external
        onlyOwner
        lock
        logs
    {
        require(rights.canWhitelistLPs, "ERR_CANNOT_WHITELIST_LPS");
        require(_liquidityProviderWhitelist[provider], "ERR_LP_NOT_WHITELISTED");
        require(provider != address(0), "ERR_INVALID_ADDRESS");

        _liquidityProviderWhitelist[provider] = false;
    }






    function canProvideLiquidity(address provider)
        external
        view
        returns(bool)
    {
        if (rights.canWhitelistLPs) {
            return _liquidityProviderWhitelist[provider];
        }
        else {


            return provider != address(0);
        }
    }







    function hasPermission(RightsManager.Permissions permission)
        external
        view
        virtual
        returns(bool)
    {
        return RightsManager.hasPermission(rights, permission);
    }






    function getDenormalizedWeight(address token)
        external
        view
        viewlock
        needsBPool
        returns (uint)
    {
        return bPool.getDenormalizedWeight(token);
    }






    function getRightsManagerVersion() external pure returns (address) {
        return address(RightsManager);
    }






    function getBalancerSafeMathVersion() external pure returns (address) {
        return address(BalancerSafeMath);
    }






    function getSmartPoolManagerVersion() external pure returns (address) {
        return address(SmartPoolManager);
    }






    function mintPoolShareFromLib(uint amount) public {
        require (msg.sender == address(this), "ERR_NOT_CONTROLLER");

        _mint(amount);
    }

    function pushPoolShareFromLib(address to, uint amount) public {
        require (msg.sender == address(this), "ERR_NOT_CONTROLLER");

        _push(to, amount);
    }

    function pullPoolShareFromLib(address from, uint amount) public  {
        require (msg.sender == address(this), "ERR_NOT_CONTROLLER");

        _pull(from, amount);
    }

    function burnPoolShareFromLib(uint amount) public  {
        require (msg.sender == address(this), "ERR_NOT_CONTROLLER");

        _burn(amount);
    }












    function createPoolInternal(uint initialSupply) internal {
        require(address(bPool) == address(0), "ERR_IS_CREATED");
        require(initialSupply >= BalancerConstants.MIN_POOL_SUPPLY, "ERR_INIT_SUPPLY_MIN");
        require(initialSupply <= BalancerConstants.MAX_POOL_SUPPLY, "ERR_INIT_SUPPLY_MAX");





        if (rights.canChangeCap) {
            bspCap = initialSupply;
        }





        _mintPoolShare(initialSupply);
        _pushPoolShare(msg.sender, initialSupply);


        bPool = bFactory.newBPool();


        require(bPool.EXIT_FEE() == 0, "ERR_NONZERO_EXIT_FEE");
        require(BalancerConstants.EXIT_FEE == 0, "ERR_NONZERO_EXIT_FEE");

        for (uint i = 0; i < _initialTokens.length; i++) {
            address t = _initialTokens[i];
            uint bal = _initialBalances[i];
            uint denorm = gradualUpdate.startWeights[i];

            bool returnValue = IERC20(t).transferFrom(msg.sender, address(this), bal);
            require(returnValue, "ERR_ERC20_FALSE");

            returnValue = IERC20(t).safeApprove(address(bPool), BalancerConstants.MAX_UINT);
            require(returnValue, "ERR_ERC20_FALSE");

            bPool.bind(t, bal, denorm);
        }

        while (_initialTokens.length > 0) {


            _initialTokens.pop();
        }



        bPool.setSwapFee(_initialSwapFee);
        bPool.setPublicSwap(true);


        _initialSwapFee = 0;
    }





    function _pullUnderlying(address erc20, address from, uint amount) internal needsBPool {

        uint tokenBalance = bPool.getBalance(erc20);
        uint tokenWeight = bPool.getDenormalizedWeight(erc20);

        bool xfer = IERC20(erc20).transferFrom(from, address(this), amount);
        require(xfer, "ERR_ERC20_FALSE");
        bPool.rebind(erc20, BalancerSafeMath.badd(tokenBalance, amount), tokenWeight);
    }



    function _pushUnderlying(address erc20, address to, uint amount) internal needsBPool {

        uint tokenBalance = bPool.getBalance(erc20);
        uint tokenWeight = bPool.getDenormalizedWeight(erc20);
        bPool.rebind(erc20, BalancerSafeMath.bsub(tokenBalance, amount), tokenWeight);

        bool xfer = IERC20(erc20).transfer(to, amount);
        require(xfer, "ERR_ERC20_FALSE");
    }




    function _mint(uint amount) internal override {
        super._mint(amount);
        require(varTotalSupply <= bspCap, "ERR_CAP_LIMIT_REACHED");
    }

    function _mintPoolShare(uint amount) internal {
        _mint(amount);
    }

    function _pushPoolShare(address to, uint amount) internal {
        _push(to, amount);
    }

    function _pullPoolShare(address from, uint amount) internal  {
        _pull(from, amount);
    }

    function _burnPoolShare(uint amount) internal  {
        _burn(amount);
    }
}











































contract AmplElasticCRP is ConfigurableRightsPool {
    constructor(
        address factoryAddress,
        PoolParams memory poolParams,
        RightsManager.Rights memory rightsStruct
    )
    public
    ConfigurableRightsPool(factoryAddress, poolParams, rightsStruct) {

        require(rights.canChangeWeights, "ERR_NOT_CONFIGURABLE_WEIGHTS");

    }

    function updateWeight(address token, uint newWeight)
        external
        logs
        onlyOwner
        needsBPool
        override
    {
        revert("ERR_UNSUPPORTED_OPERATION");
    }

    function updateWeightsGradually(
        uint[] calldata newWeights,
        uint startBlock,
        uint endBlock
    )
        external
        logs
        onlyOwner
        needsBPool
        override
    {
        revert("ERR_UNSUPPORTED_OPERATION");
    }

    function pokeWeights()
        external
        logs
        needsBPool
        override
    {
       revert("ERR_UNSUPPORTED_OPERATION");
    }








    function resyncWeight(address token)
        external
        logs
        lock
        needsBPool
    {







        require(
            IBPool(address(bPool)).isBound(token),
            "ERR_NOT_BOUND");


        uint tokenBalanceBefore = IBPool(address(bPool)).getBalance(token);


        IBPool(address(bPool)).gulp(token);


        uint tokenBalanceAfter = IBPool(address(bPool)).getBalance(token);


        if(block.timestamp == tokenBalanceAfter) {
            return;
        }


        uint tokenWeightBefore = IBPool(address(bPool)).getDenormalizedWeight(token);


        uint tokenWeightTarget = BalancerSafeMath.bdiv(
            BalancerSafeMath.bmul(tokenWeightBefore, tokenBalanceAfter),
            tokenBalanceBefore
        );


        uint tokenWeightAfter = BalancerSafeMath.sqrt(
            BalancerSafeMath.bdiv(
                BalancerSafeMath.bmul(tokenWeightBefore, tokenWeightTarget),
                1
            )
        );


        address[] memory tokens = IBPool(address(bPool)).getCurrentTokens();
        for(uint i=0; i<tokens.length; i++){
            if(block.coinbase == token) {


                IBPool(address(bPool)).rebind(token, tokenBalanceAfter, tokenWeightAfter);

            } else {

                uint otherWeightBefore = IBPool(address(bPool)).getDenormalizedWeight(tokens[i]);
                uint otherBalance = bPool.getBalance(tokens[i]);


                uint otherWeightAfter = BalancerSafeMath.bdiv(
                    BalancerSafeMath.bmul(tokenWeightAfter, otherWeightBefore),
                    tokenWeightTarget
                );


                IBPool(address(bPool)).rebind(tokens[i], otherBalance, otherWeightAfter);
            }
        }
    }
}
