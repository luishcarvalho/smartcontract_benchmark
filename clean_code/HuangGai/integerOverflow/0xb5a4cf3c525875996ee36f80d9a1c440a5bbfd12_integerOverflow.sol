





pragma solidity >=0.6.0 <0.7.0;















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


interface IPowerKeeper {
    function usePower(address master) external returns (uint256);
    function power(address master) external view returns (uint256);
    function totalPower() external view returns (uint256);
    event PowerGained(address indexed master, uint256 amount);
    event PowerUsed(address indexed master, uint256 amount);
}

interface IMilker {
    function bandits(uint256 percent) external returns (uint256, uint256, uint256);
    function sheriffsVaultCommission() external returns (uint256);
    function sheriffsPotDistribution() external returns (uint256);
    function isWhitelisted(address holder) external view returns (bool);
    function getPeriod() external view returns (uint256);
}


contract StableV2 is Ownable, IPowerKeeper {
    using SafeMath for uint256;


    struct Stakeshot {
        uint256 block;
        uint256 volume;
        uint256 power;
    }


    IMilker private _milker;


    IERC20 private _token;


    uint256 private _maxUnits;
    uint256 private _tokensToPowerDelimiter;


    mapping(address => uint256) private _tokens;
    uint256 private _totalTokens;


    mapping(address => Stakeshot) private _stakeshots;


    uint256 private _totalPower;
    uint256 private _totalPowerBlock;



    event Staked(address indexed holder, uint256 tokens);
    event Claimed(address indexed holder, uint256 tokens);


    modifier onlyMilker() {
        require(address(_milker) == _msgSender(), "StableV2: caller is not the Milker contract");
        _;
    }


    constructor(address milker, address token, uint256 maxUnits, uint256 tokensToPowerDelimiter) public {
        require(address(milker) != address(0), "StableV2: Milker contract address cannot be empty");
        require(address(token) != address(0), "StableV2: ERC20 token contract address cannot be empty");
        require(tokensToPowerDelimiter > 0, "StableV2: delimiter used to convert between tokens and units cannot be zero");
        _milker = IMilker(milker);
        _token = IERC20(token);
        _maxUnits = maxUnits;
        _tokensToPowerDelimiter = tokensToPowerDelimiter;
        _totalPowerBlock = block.number;
    }

    function stake(uint256 tokens) external {
        address holder = msg.sender;
        require(address(_milker) != address(0), "StableV2: Milker contract is not set up");
        require(!_milker.isWhitelisted(holder), "StableV2: whitelisted holders cannot stake tokens");


        _update(holder);


        bool ok = _token.transferFrom(holder, address(this), tokens);
        require(ok, "StableV2: unable to transfer tokens to the StableV2 contract");


        uint256 units = _maxUnits != 0 ? tokens.mul(_maxUnits.div(_token.totalSupply())) : tokens;
        _tokens[holder] = _tokens[holder].add(units);
        _totalTokens = _totalTokens.add(units);


        _stakeshots[holder].volume = _tokens[holder];


        emit Staked(holder, tokens);
    }

    function claim(uint256 tokens) external {
        address holder = msg.sender;
        require(address(_milker) != address(0), "StableV2: Milker contract is not set up");
        require(!_milker.isWhitelisted(holder), "StableV2: whitelisted holders cannot claim tokens");


        _update(holder);


        bool ok = _token.transfer(holder, tokens);
        require(ok, "StableV2: unable to transfer tokens from the StableV2 contract");


        uint256 units = _maxUnits != 0 ? tokens.mul(_maxUnits.div(_token.totalSupply())) : tokens;
        _tokens[holder] = _tokens[holder].sub(units);
        _totalTokens = _totalTokens.sub(units);


        _stakeshots[holder].volume = _tokens[holder];


        emit Claimed(holder, tokens);
    }

    function usePower(address holder) external override onlyMilker returns (uint256 powerUsed) {


        _update(holder);


        powerUsed = _stakeshots[holder].power;
        _stakeshots[holder].power = 0;
        _totalPower = _totalPower.sub(powerUsed);



        emit PowerUsed(holder, powerUsed);
    }

    function milker() public view returns (address) {
        return address(_milker);
    }

    function token() public view returns (address) {
        return address(_token);
    }

    function tokens(address holder) public view returns (uint256) {
        uint256 unitsPerToken = _maxUnits != 0 ? _maxUnits.div(_token.totalSupply()) : 1;
        return _tokens[holder].div(unitsPerToken);
    }

    function totalTokens() public view returns (uint256) {
        uint256 unitsPerToken = _maxUnits != 0 ? _maxUnits.div(_token.totalSupply()) : 1;
        return _totalTokens.div(unitsPerToken);
    }

    function power(address holder) public view override returns (uint256) {
        Stakeshot storage s = _stakeshots[holder];
        uint256 duration = block.number.sub(s.block);
        if (s.block > 0 && duration > 0) {
            uint256 powerGained = s.volume.div(_tokensToPowerDelimiter).mul(duration);
            return s.power.add(powerGained);
        }
        return s.power;
    }

    function totalPower() public view override returns (uint256) {
        uint256 duration = block.number.sub(_totalPowerBlock);
        if (duration > 0) {
            uint256 powerGained = _totalTokens.div(_tokensToPowerDelimiter).mul(duration);
            return _totalPower.add(powerGained);
        }
        return _totalPower;
    }

    function stakeshot(address holder) public view returns (uint256, uint256, uint256) {
        uint256 unitsPerToken = _maxUnits != 0 ? _maxUnits.div(_token.totalSupply()) : 1;
        Stakeshot storage s = _stakeshots[holder];
        return (s.block, s.volume.div(unitsPerToken), s.power);
    }

    function _update(address holder) private {


        Stakeshot storage s = _stakeshots[holder];
        uint256 duration = block.number.sub(s.block);
        if (s.block > 0 && duration > 0) {
            uint256 powerGained = s.volume.div(_tokensToPowerDelimiter).mul(duration);
            s.power = s.power.add(powerGained);
            emit PowerGained(holder, powerGained);
        }
        s.block = block.number;
        s.volume = _tokens[holder];


        duration = block.number.sub(_totalPowerBlock);
        if (duration > 0) {
            uint256 powerGained = _totalTokens.div(_tokensToPowerDelimiter).mul(duration);
            _totalPower = _totalPower.add(powerGained);
            _totalPowerBlock = block.number;
        }
    }
}
