pragma solidity 0.5.12;

import './library/ERC20SafeTransfer';
import './library/IERC20';
import './library/LibNote';
import './library/Pausable';
import './library/SafeMath';

















contract USR is LibNote, Pausable, ERC20SafeTransfer {
    using SafeMath for uint;

    bool private initialized;

    uint public interestRate;
    uint public exchangeRate;
    uint public lastTriggerTime;
    uint public originationFee;

    address public usdx;

    uint public maxDebtAmount;

    uint constant ONE = 10 ** 27;
    uint constant BASE = 10 ** 18;


    string  public name;
    string  public symbol;
    uint8   public decimals;
    uint256 public totalSupply;

    mapping (address => uint)                      public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;


    event Approval(address indexed src, address indexed guy, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);

    event SetMaxDebtAmount(address indexed owner, uint indexed newTokenMaxAmount, uint indexed oldTokenMaxAmount);
    event SetInterestRate(address indexed owner, uint indexed InterestRate, uint indexed oldInterestRate);
    event NewOriginationFee(uint oldOriginationFeeMantissa, uint newOriginationFeeMantissa);







    constructor(string memory _name, string memory _symbol, uint8 _decimals, address _usdx, uint _originationFee, uint _maxDebtAmount) public {
        initialize(_name, _symbol, _decimals, _usdx, _originationFee, _maxDebtAmount);
    }



    function initialize(string memory _name, string memory _symbol, uint8 _decimals, address _usdx, uint _originationFee, uint _maxDebtAmount) public {
        require(!initialized, "initialize: already initialized.");
        require(_originationFee < BASE / 10, "initialize: fee should be less than ten percent.");
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        usdx = _usdx;
        owner = msg.sender;
        interestRate = ONE;
        exchangeRate = ONE;
        lastTriggerTime = now;
        originationFee = _originationFee;
        maxDebtAmount = _maxDebtAmount;
        initialized = true;

        emit SetInterestRate(msg.sender, ONE, 0);
        emit NewOriginationFee(0, _originationFee);
        emit SetMaxDebtAmount(msg.sender, _maxDebtAmount, 0);
    }






    function setInterestRate(uint _interestRate) external onlyOwner {
        uint _oldInterestRate = interestRate;
        require(_interestRate != _oldInterestRate, "setInterestRate: Old and new values cannot be the same.");
        require(_interestRate >= ONE, "setInterestRate: Old and new values cannot be the same.");
        drip();
        interestRate = _interestRate;
        emit SetInterestRate(msg.sender, _interestRate, _oldInterestRate);
    }





    function updateOriginationFee(uint _newOriginationFee) external onlyOwner {
        require(_newOriginationFee < BASE / 10, "updateOriginationFee: fee should be less than ten percent.");
        uint _oldOriginationFee = originationFee;
        require(_oldOriginationFee != _newOriginationFee, "updateOriginationFee: The old and new values cannot be the same.");
        originationFee = _newOriginationFee;
        emit NewOriginationFee(_oldOriginationFee, _newOriginationFee);
    }





    function setMaxDebtAmount(uint _newMaxDebtAmount) external onlyOwner {
        uint _oldTokenMaxAmount = maxDebtAmount;
        require(_oldTokenMaxAmount != _newMaxDebtAmount, "setMaxDebtAmount: The old and new values cannot be the same.");
        maxDebtAmount = _newMaxDebtAmount;
        emit SetMaxDebtAmount(owner, _newMaxDebtAmount, _oldTokenMaxAmount);
    }








    function takeOut(address _token, address _recipient, uint _amount) external onlyManager whenNotPaused {
        require(doTransferOut(_token, _recipient, _amount));
    }


    function rpow(uint x, uint n, uint base) internal pure returns (uint z) {
        assembly {
            switch x case 0 {switch n case 0 {z := base} default {z := 0}}
            default {
                switch mod(n, 2) case 0 { z := base } default { z := x }
                let half := div(base, 2)
                for { n := div(n, 2) } n { n := div(n,2) } {
                    let xx := mul(x, x)
                    if iszero(eq(div(xx, x), x)) { revert(0,0) }
                    let xxRound := add(xx, half)
                    if lt(xxRound, xx) { revert(0,0) }
                    x := div(xxRound, base)
                    if mod(n,2) {
                        let zx := mul(z, x)
                        if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
                        let zxRound := add(zx, half)
                        if lt(zxRound, zx) { revert(0,0) }
                        z := div(zxRound, base)
                    }
                }
            }
        }
    }

    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = x.mul(y) / ONE;
    }
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = x.mul(ONE) / y;
    }
    function rdivup(uint x, uint y) internal pure returns (uint z) {
        z = x.mul(ONE).add(y.sub(1)) / y;
    }

    function mulScale(uint x, uint y) internal pure returns (uint z) {
        z = x.mul(y) / BASE;
    }

    function divScale(uint x, uint y) internal pure returns (uint z) {
        z = x.mul(BASE).add(y.sub(1)) / y;
    }





    function drip() public note returns (uint) {
        if (now > lastTriggerTime) {
            uint _tmp = rmul(rpow(interestRate, now - lastTriggerTime, ONE), exchangeRate);
            exchangeRate = _tmp;
            lastTriggerTime = now;

            return _tmp;
        }

        return exchangeRate;
    }






    function join(address _dst, uint _pie) private note whenNotPaused {
        require(now == lastTriggerTime, "join: last trigger time not updated.");
        require(doTransferFrom(usdx, msg.sender, address(this), _pie));
        uint _wad = rdiv(_pie, exchangeRate);
        balanceOf[_dst] = balanceOf[_dst].add(_wad);
        totalSupply = totalSupply.add(_wad);
        require(rmul(totalSupply, exchangeRate) <= maxDebtAmount, "join: not enough to join.");
        emit Transfer(address(0), _dst, _wad);
    }






    function exit(address _src, uint _wad) private note whenNotPaused {
        require(now == lastTriggerTime, "exit: lastTriggerTime not updated.");
        require(balanceOf[_src] >= _wad, "exit: insufficient balance");
        if (_src != msg.sender && allowance[_src][msg.sender] != uint(-1)) {
            require(allowance[_src][msg.sender] >= _wad, "exit: insufficient allowance");
            allowance[_src][msg.sender] = allowance[_src][msg.sender].sub(_wad);
        }
        balanceOf[_src] = balanceOf[_src].sub(_wad);
        totalSupply = totalSupply.sub(_wad);
        uint earningWithoutFee = rmul(_wad, exchangeRate);

        require(doTransferOut(usdx, msg.sender, mulScale(earningWithoutFee, BASE.sub(originationFee))));
        emit Transfer(_src, address(0), _wad);
    }






    function draw(address _src, uint _pie) private note whenNotPaused {
        require(now == lastTriggerTime, "draw: last trigger time not updated.");
        uint _wad = rdivup(divScale(_pie, BASE.sub(originationFee)), exchangeRate);
        require(balanceOf[_src] >= _wad, "draw: insufficient balance");
        if (_src != msg.sender && allowance[_src][msg.sender] != uint(-1)) {
            require(allowance[_src][msg.sender] >= _wad, "draw: insufficient allowance");
            allowance[_src][msg.sender] = allowance[_src][msg.sender].sub(_wad);
        }
        balanceOf[_src] = balanceOf[_src].sub(_wad);
        totalSupply = totalSupply.sub(_wad);

        require(doTransferOut(usdx, msg.sender, _pie));
        emit Transfer(_src, address(0), _wad);
    }


    function transfer(address _dst, uint _wad) external returns (bool) {
        return transferFrom(msg.sender, _dst, _wad);
    }


    function move(address _src, address _dst, uint _pie) external returns (bool) {
        uint _exchangeRate = (now > lastTriggerTime) ? drip() : exchangeRate;

        return transferFrom(_src, _dst, rdivup(_pie, _exchangeRate));
    }

    function transferFrom(address _src, address _dst, uint _wad) public returns (bool)
    {
        require(balanceOf[_src] >= _wad, "transferFrom: insufficient balance");
        if (_src != msg.sender && allowance[_src][msg.sender] != uint(-1)) {
            require(allowance[_src][msg.sender] >= _wad, "transferFrom: insufficient allowance");
            allowance[_src][msg.sender] = allowance[_src][msg.sender].sub(_wad);
        }
        balanceOf[_src] = balanceOf[_src].sub(_wad);
        balanceOf[_dst] = balanceOf[_dst].add(_wad);
        emit Transfer(_src, _dst, _wad);
        return true;
    }


    function approve(address _spender, uint _wad) external returns (bool) {
        allowance[msg.sender][_spender] = _wad;
        emit Approval(msg.sender, _spender, _wad);
        return true;
    }






    function equity() external view returns (int) {
        uint _totalAmount = rmul(totalSupply, getExchangeRate());
        uint _balance = IERC20(usdx).balanceOf(address(this));
        if (_totalAmount > _balance)
            return -1 * int(_totalAmount.sub(_balance));

        return int(_balance.sub(_totalAmount));
    }






    function share() external view returns (uint) {
        uint _totalAmount = rmul(totalSupply, getExchangeRate());
        uint _tokenMaxAmount = maxDebtAmount;
        return _tokenMaxAmount > _totalAmount ? _tokenMaxAmount.sub(_totalAmount) : 0;
    }






    function getTotalBalance(address _account) external view returns (uint _wad) {
        uint _exchangeRate = getExchangeRate();
        _wad = mulScale(rmul(balanceOf[_account], _exchangeRate), BASE.sub(originationFee));
    }




    function getExchangeRate() public view returns (uint) {
        return getFixedExchangeRate(now.sub(lastTriggerTime));
    }

    function getFixedExchangeRate(uint _interval) public view returns (uint) {
        uint _scale = ONE;
        return rpow(interestRate, _interval, _scale).mul(exchangeRate) / _scale;
    }






    function getFixedInterestRate(uint _interval) external view returns (uint) {
        return rpow(interestRate, _interval, ONE);
    }


    function mint(address _dst, uint _pie) external {
        if (now > lastTriggerTime)
            drip();

        join(_dst, _pie);
    }


    function burn(address _src, uint _wad) external {
        if (now > lastTriggerTime)
            drip();
        exit(_src, _wad);
    }


    function withdraw(address _src, uint _pie) external {
        if (now > lastTriggerTime)
            drip();

        draw(_src, _pie);
    }
}
