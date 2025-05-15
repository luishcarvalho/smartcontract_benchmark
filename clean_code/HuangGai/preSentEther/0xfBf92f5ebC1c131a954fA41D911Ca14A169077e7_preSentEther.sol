





pragma solidity ^0.6.12;
















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













abstract contract Context {
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




interface IStrategy {

    function approve(IERC20 _token) external;

    function getValuePerShare(address _vault) external view returns(uint256);
    function pendingValuePerShare(address _vault) external view returns (uint256);


    function deposit(address _vault, uint256 _amount) external;


    function claim(address _vault) external;


    function withdraw(address _vault, uint256 _amount) external;


    function getTargetToken() external view returns(address);
}














































contract SodaMaster is Ownable {

    address public pool;
    address public bank;
    address public revenue;
    address public dev;

    address public soda;
    address public wETH;
    address public usdt;

    address public uniswapV2Factory;

    mapping(address => bool) public isVault;
    mapping(uint256 => address) public vaultByKey;

    mapping(address => bool) public isSodaMade;
    mapping(uint256 => address) public sodaMadeByKey;

    mapping(address => bool) public isStrategy;
    mapping(uint256 => address) public strategyByKey;

    mapping(address => bool) public isCalculator;
    mapping(uint256 => address) public calculatorByKey;


    function setPool(address _pool) external onlyOwner {
        require(pool == address(0));
        pool = _pool;
    }



    function setBank(address _bank) external onlyOwner {
        require(bank == address(0));
        bank = _bank;
    }


    function setRevenue(address _revenue) external onlyOwner {
        revenue = _revenue;
    }


    function setDev(address _dev) external onlyOwner {
        dev = _dev;
    }



    function setUniswapV2Factory(address _uniswapV2Factory) external onlyOwner {
        uniswapV2Factory = _uniswapV2Factory;
    }


    function setWETH(address _wETH) external onlyOwner {
       require(wETH == address(0));
       wETH = _wETH;
    }



    function setUSDT(address _usdt) external onlyOwner {
        require(usdt == address(0));
        usdt = _usdt;
    }


    function setSoda(address _soda) external onlyOwner {
        require(soda == address(0));
        soda = _soda;
    }


    function addVault(uint256 _key, address _vault) external onlyOwner {
        require(vaultByKey[_key] == address(0), "vault: key is taken");

        isVault[_vault] = true;
        vaultByKey[_key] = _vault;
    }


    function addSodaMade(uint256 _key, address _sodaMade) external onlyOwner {
        require(sodaMadeByKey[_key] == address(0), "sodaMade: key is taken");

        isSodaMade[_sodaMade] = true;
        sodaMadeByKey[_key] = _sodaMade;
    }


    function addStrategy(uint256 _key, address _strategy) external onlyOwner {
        isStrategy[_strategy] = true;
        strategyByKey[_key] = _strategy;
    }

    function removeStrategy(uint256 _key) external onlyOwner {
        isStrategy[strategyByKey[_key]] = false;
        delete strategyByKey[_key];
    }


    function addCalculator(uint256 _key, address _calculator) external onlyOwner {
        isCalculator[_calculator] = true;
        calculatorByKey[_key] = _calculator;
    }

    function removeCalculator(uint256 _key) external onlyOwner {
        isCalculator[calculatorByKey[_key]] = false;
        delete calculatorByKey[_key];
    }
}

interface IMasterChef {

    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function pendingSushi(uint256 _pid, address _user) external view returns (uint256);
}



contract EatSushi is IStrategy, Ownable {
    using SafeMath for uint256;

    uint256 constant PER_SHARE_SIZE = 1e12;

    IMasterChef public masterChef;

    SodaMaster public sodaMaster;
    IERC20 public sushiToken;

    struct PoolInfo {
        IERC20 lpToken;
        uint256 poolId;
    }

    mapping(address => PoolInfo) public poolMap;
    mapping(address => uint256) private valuePerShare;





    constructor(SodaMaster _sodaMaster,
                IERC20 _sushiToken,
                IMasterChef _masterChef) public {
        sodaMaster = _sodaMaster;
        sushiToken = _sushiToken;
        masterChef = _masterChef;

        sushiToken.approve(sodaMaster.pool(), type(uint256).max);
    }

    function approve(IERC20 _token) external override onlyOwner {
        _token.approve(sodaMaster.pool(), type(uint256).max);
        _token.approve(address(masterChef), type(uint256).max);
    }

    function setPoolInfo(
        address _vault,
        IERC20 _lpToken,
        uint256 _sushiPoolId
    ) external onlyOwner {
        poolMap[_vault].lpToken = _lpToken;
        poolMap[_vault].poolId = _sushiPoolId;
        _lpToken.approve(sodaMaster.pool(), type(uint256).max);
        _lpToken.approve(address(masterChef), type(uint256).max);
    }

    function getValuePerShare(address _vault) external view override returns(uint256) {
        return valuePerShare[_vault];
    }

    function pendingValuePerShare(address _vault) external view override returns (uint256) {
        uint256 shareAmount = IERC20(_vault).totalSupply();
        if (address(this).balance == 0) {
            return 0;
        }

        uint256 amount = masterChef.pendingSushi(poolMap[_vault].poolId, address(this));
        return amount.mul(PER_SHARE_SIZE).div(shareAmount);
    }

    function _update(address _vault, uint256 _tokenAmountDelta) internal {
        uint256 shareAmount = IERC20(_vault).totalSupply();
        if (shareAmount > 0) {
            valuePerShare[_vault] = valuePerShare[_vault].add(
                _tokenAmountDelta.mul(PER_SHARE_SIZE).div(shareAmount));
        }
    }




    function deposit(address _vault, uint256 _amount) public override {
        require(sodaMaster.isVault(msg.sender), "sender not vault");

        uint256 tokenAmountBefore = sushiToken.balanceOf(address(this));
        masterChef.deposit(poolMap[_vault].poolId, _amount);
        uint256 tokenAmountAfter = sushiToken.balanceOf(address(this));

        _update(_vault, tokenAmountAfter.sub(tokenAmountBefore));
    }




    function claim(address _vault) external override {
        require(sodaMaster.isVault(msg.sender), "sender not vault");


        deposit(_vault, 0);
    }




    function withdraw(address _vault, uint256 _amount) external override {
        require(sodaMaster.isVault(msg.sender), "sender not vault");

        uint256 tokenAmountBefore = sushiToken.balanceOf(address(this));
        masterChef.withdraw(poolMap[_vault].poolId, _amount);
        uint256 tokenAmountAfter = sushiToken.balanceOf(address(this));

        _update(_vault, tokenAmountAfter.sub(tokenAmountBefore));
    }




    function getTargetToken() external view override returns(address) {
        return address(sushiToken);
    }
}
