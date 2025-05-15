



pragma solidity ^0.6.2;













contract Context {


    constructor () internal { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
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

















contract ReentrancyGuard {
    bool private _notEntered;

    constructor () internal {






        _notEntered = true;
    }








    modifier nonReentrant() {

        require(_notEntered, "ReentrancyGuard: reentrant call");


        _notEntered = false;

        _;



        _notEntered = true;
    }
}


interface IStaking {

    function getFrozenFrom() external view returns (uint256);

    function getFrozenUntil() external view returns (uint256);

    function getDripPerBlock() external view returns (uint256);

    function getTotalDeposited() external view returns (uint256);

    function getTokenToStake() external view returns (address);

    function getIssuingToken() external view returns (address);

    function getUserDeposit(address user) external view returns (uint256);

    function initializeNewRound(uint256 frozenFrom, uint256 frozenUntil, uint256 drip) external returns (bool);

    function deposit(uint256 amount) external returns (bool);

    function withdrawAndRedeem(uint256 amount) external returns (bool);

    function redeem() external returns (bool);

    function accumulated(address account) external view returns (uint256);
}

contract Staking is IStaking, Ownable, ReentrancyGuard  {

    using SafeMath for uint256;

    address internal tokenToStake;
    address internal issuingToken;
    uint256 internal frozenFrom;
    uint256 internal frozenUntil;
    uint256 internal dripPerBlock;
    uint256 internal totalDeposited;
    uint256 internal totalDepositedDynamic;
    mapping(address => uint256) internal deposited;
    mapping(address => uint256) internal latestRedeem;

    event Deposited(address account, uint256 amount);
    event WithdrawnAndRedeemed(address acount, uint256 amount, uint256 issued);
    event Redeemed(address account, uint256 amount);

    constructor(
        address stakedToken,
        address issuedToken
    ) public {
        tokenToStake  = stakedToken;
        issuingToken = issuedToken;
    }




    function getFrozenFrom() external view override returns (uint256) {
        return frozenFrom;
    }




    function getFrozenUntil() external view override returns (uint256) {
        return frozenUntil;
    }




    function getDripPerBlock() external view override returns (uint256) {
        return dripPerBlock;
    }




    function getTotalDeposited() external view override returns (uint256) {
        return totalDepositedDynamic;
    }




    function getTokenToStake() external view override returns (address) {
        return tokenToStake;
    }




    function getIssuingToken() external view override returns (address) {
        return issuingToken;
    }




    function getUserDeposit(address user) external view override returns (uint256) {
        return deposited[user];
    }




    function setTimeWindow(uint256 from, uint256 to) internal returns (bool) {
        require(from > block.number, "'from' too small");
        require(to > block.number, "'to' too small");
        require(from < to, "'from' is larger than 'to'");
        frozenFrom = from;
        frozenUntil = to;
        return true;
    }




    function setDripRate(uint256 drip) internal returns (bool) {
        dripPerBlock = drip;
        return true;
    }




    function initializeNewRound(
        uint256 _frozenFrom,
        uint256 _frozenUntil,
        uint256 drip) external onlyOwner override returns (bool) {
        setTimeWindow(_frozenFrom, _frozenUntil);
        dripPerBlock = drip;
        return true;
    }




    function deposit(uint256 amount) external override nonReentrant returns (bool) {
        require(block.number < frozenFrom, "deposits not allowed");
        deposited[msg.sender] = deposited[msg.sender].add(amount);
        totalDeposited = totalDeposited.add(amount);
        totalDepositedDynamic = totalDepositedDynamic.add(amount);
        latestRedeem[msg.sender] = frozenFrom;
        emit Deposited(msg.sender, amount);
        require(IERC20(tokenToStake).transferFrom(msg.sender, address(this), amount),"deposit() failed.");
        return true;
    }




    function withdrawAndRedeem(uint256 amount) external override nonReentrant returns (bool) {
        require(deposited[msg.sender] >= amount, "deposit too small");
        if(block.number < frozenFrom){
            deposited[msg.sender] = deposited[msg.sender].sub(amount);
            totalDeposited = totalDeposited.sub(amount);
            totalDepositedDynamic = totalDepositedDynamic.sub(amount);
            require(IERC20(tokenToStake).transfer(msg.sender, amount),"withdrawAndRedeem() failed.");
        } else {
            require(block.number >= frozenUntil, "withdraws not allowed");
            uint256 accumulated = accumulated(msg.sender);
            deposited[msg.sender] = deposited[msg.sender].sub(amount);
            emit WithdrawnAndRedeemed(msg.sender, amount, accumulated);
            totalDepositedDynamic = totalDepositedDynamic.sub(amount);
            require(_redeem(msg.sender, accumulated), "Failed to redeem tokens");
            require(IERC20(tokenToStake).transfer(msg.sender, amount),"withdrawAndRedeem() failed.");
        }
        return true;
    }




    function redeem() external override nonReentrant returns (bool) {
        uint256 accumulated = accumulated(msg.sender);
        Redeemed(msg.sender, accumulated);
        return _redeem(msg.sender, accumulated);
    }




    function _redeem(address account, uint256 amount) internal returns (bool) {
        if (block.number >= frozenUntil) {
            latestRedeem[account] = frozenUntil;
        } else {
            if(block.number > frozenFrom){
                latestRedeem[account] = block.number;
            } else {
                latestRedeem[account] = frozenFrom;
            }
        }
        if(amount > 0) {
            IERC20(issuingToken).transfer(account, amount);
        }
        return true;
    }




    function accumulated(address account) public view override returns (uint256) {
        if(address(this).balance == 0) {
            return 0;
        }
        if(block.number > frozenFrom) {
            if(block.number <= frozenUntil) {
                return deposited[account].mul(
                    dripPerBlock.mul(
                        block.number.sub(
                            latestRedeem[account]
                        )
                    )
                ).div(totalDeposited);
            } else {
                return deposited[account].mul(
                    dripPerBlock.mul(
                        frozenUntil.sub(
                            latestRedeem[account]
                        )
                    )
                ).div(totalDeposited);
            }
        } else {
            return 0;
        }
    }


}
