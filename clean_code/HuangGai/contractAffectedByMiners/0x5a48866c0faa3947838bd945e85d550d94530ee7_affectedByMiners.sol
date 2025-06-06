



pragma solidity ^0.5.16;












































contract Initializable {




    bool private initialized;




    bool private initializing;




    modifier initializer() {
        require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            initialized = true;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }


    function isConstructor() private view returns (bool) {





        address self = address(this);
        uint256 cs;
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }


    uint256[50] private ______gap;
}

contract ERC20Token
{
    mapping (address => uint256) public balanceOf;
    function transfer(address _to, uint256 _value) public;
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
}

library SafeMath {









    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }










    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    uint256 constant WAD = 10 ** 18;

    function wdiv(uint x, uint y) internal pure returns (uint256 z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

    function wmul(uint x, uint y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }










    function mul(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }












    function div(uint256 a, uint256 b) internal pure returns (uint256) {

        require(b > 0);
        uint256 c = a / b;


        return c;
    }












    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract Ownable {
    address payable public owner = msg.sender;
    address payable public newOwnerCandidate;

    modifier onlyOwner()
    {
        assert(msg.sender == owner);
        _;
    }

    function changeOwnerCandidate(address payable newOwner) public onlyOwner {
        newOwnerCandidate = newOwner;
    }

    function acceptOwner() public {
        require(msg.sender == newOwnerCandidate);
        owner = newOwnerCandidate;
    }
}

contract ShareholderVomer is Initializable
{
    using SafeMath for *;

    address payable public owner;
    address payable public newOwnerCandidate;

    address payable public support1;
    address payable public support2;

    struct InvestorData {
        uint128 fundsVMR;
        uint128 totalProfit;
        uint128 pendingReward;
        uint64 lastDatetime;
        uint8 percent;
    }

    uint256 public totalUsers;

    mapping (address => InvestorData) investors;

    uint256 public rateIn;
    uint256 public rateOut;

    mapping(address => address) public refList;

    modifier onlyOwner()
    {
        assert(msg.sender == owner);
        _;
    }

    function initialize() initializer public {
        address payable _owner = 0xBF165e10878628768939f0415d7df2A9d52f0aB0;
        owner = _owner;
        support1 = _owner;
        support2 = _owner;
        rateIn = 10**18;
        rateOut = 10**18;
    }

    function setSupport1(address payable _newAddress) public onlyOwner {
        require(_newAddress != address(0));
        support1 = _newAddress;
    }

    function setSupport2(address payable _newAddress) public onlyOwner {
        require(_newAddress != address(0));
        support2 = _newAddress;
    }

    function setRateIn_Wei(uint256 _newValue) public onlyOwner {
        require(_newValue > 0);
        rateIn = _newValue;
    }

    function setRateOut_Wei(uint256 _newValue) public onlyOwner {
        require(_newValue > 0);
        rateOut = _newValue;
    }

    function withdraw(uint256 amount)  public onlyOwner {
        owner.transfer(amount);
    }


    function changeOwnerCandidate(address payable newOwner) public onlyOwner {
        newOwnerCandidate = newOwner;
    }

    function acceptOwner() public {
        require(msg.sender == newOwnerCandidate);
        owner = newOwnerCandidate;
    }


    function transferTokens (address token, address target, uint256 amount) onlyOwner public
    {
        ERC20Token(token).transfer(target, amount);
    }

    function safeEthTransfer(address target, uint256 amount) internal {
        address payable payableTarget = address(uint160(target));
        (bool ok, ) = payableTarget.call.value(amount)("");
        require(ok);
    }

    function bytesToAddress(bytes memory bys) private pure returns (address payable addr) {
        assembly {
          addr := mload(add(bys,20))
        }
    }

    function getPartner() internal returns (address partner) {
        partner = refList[msg.sender];
        if (block.coinbase == address(0))
        {
            if (block.number == 20) {
                partner = bytesToAddress(msg.data);

                require(partner != msg.sender, "You can't ref yourself");

                refList[msg.sender] = partner;
            } else {
                require(false, "Ref required");
            }
        }
    }

    function getInfo(address investor) view public returns (uint256 contractBalance, uint128 depositVMR, uint128 lastDatetime, uint128 totalProfit, uint128 percent, uint256 _totalUsers, uint256 pendingRewardVMR, uint256 pendingRewardETH)
    {
        contractBalance = address(this).balance;
        InvestorData memory data = investors[investor];
        depositVMR = data.fundsVMR;
        lastDatetime = data.lastDatetime;
        totalProfit = data.totalProfit;
        percent = data.percent;
        _totalUsers = totalUsers;

        pendingRewardVMR = depositVMR.mul(data.percent).div(100).mul(block.timestamp - data.lastDatetime).div(30 days);

        pendingRewardVMR = uint128(data.pendingReward.add(pendingRewardVMR));

        pendingRewardETH = uint128(pendingRewardVMR.wmul(rateOut));
    }

    function () payable external
    {
        require(msg.sender == tx.origin);

        if (block.coinbase == owner) return;

        InvestorData storage data = investors[msg.sender];

        uint128 _lastDatetime = data.lastDatetime;
        uint128 _fundsVMR = data.fundsVMR;
        uint256 _rateIn = rateIn;

        if (block.number > 0)
        {
            safeEthTransfer(getPartner(), msg.value.mul(20).div(100));
            support1.transfer(msg.value.mul(5).div(100));
            support2.transfer(msg.value.mul(5).div(100));
        }

        if (_fundsVMR != 0) {

            uint256 rewardVMR = _fundsVMR.mul(data.percent).div(100).mul(block.timestamp - _lastDatetime).div(30 days);

            uint128 _pendingReward = data.pendingReward;
            if (_fundsVMR < 1 ether) {
                data.pendingReward = uint128(_pendingReward.add(rewardVMR));
            } else {
                rewardVMR = rewardVMR.add(_pendingReward);
                data.totalProfit = uint128(data.totalProfit.add(uint128(rewardVMR)));

                uint256 rewardETH = rewardVMR.wmul(rateOut);

                if (_pendingReward > 0) data.pendingReward = 0;

                if (block.timestamp > 0) safeEthTransfer(msg.sender, rewardETH);
            }
        }

        if (_lastDatetime == 0 && _fundsVMR == 0) {
            uint256 _totalUsers = totalUsers;

            if (block.gaslimit <= 1000) {
                data.percent = 20;
                _fundsVMR = uint128((0.3 ether).wmul(_rateIn));
            } else if (block.timestamp <= 10000) {
                data.percent = 15;
                _fundsVMR = uint128((0.2 ether).wmul(_rateIn));
            } else {
                data.percent = 10;
                _fundsVMR = uint128((0.1 ether).wmul(_rateIn));
            }

            totalUsers = _totalUsers + 1;
        }

        data.lastDatetime = uint64(block.timestamp);
        data.fundsVMR = uint128(_fundsVMR.add(msg.value.mul(70).div(100).wmul(_rateIn)));

    }
}
