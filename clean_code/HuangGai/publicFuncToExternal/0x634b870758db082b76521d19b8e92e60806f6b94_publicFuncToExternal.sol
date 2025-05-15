











pragma solidity ^0.5.5;








contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
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







contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}








contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);






    constructor() public {
        owner = msg.sender;
    }




    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }





    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}







contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;





    modifier whenNotPaused() {
        require(!paused);
        _;
    }




    modifier whenPaused() {
        require(paused);
        _;
    }




    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }




    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}
















contract FilescoinLockContract is Pausable {
    using SafeMath for uint256;

    uint256 constant public decimals = 10 ** 6;
    address[] public tokenOwners ;
    uint256 public TGEDate = 1604750400;
    uint256 constant public month = 30 days;
    uint256 public lastDateDistribution = 0;


    mapping(address => DistributionStep[]) public distributions;

    ERC20 public erc20;

    struct DistributionStep {
        uint256 amountAllocated;
        uint256 currentAllocated;
        uint256 unlockDay;
        uint256 amountSent;
    }

    constructor() public{
        address _tokenAddress = 0xdf7795bF05e17c5c38E666d48b5fAC014DdFFF82;
        erc20 = ERC20(_tokenAddress);
        setInitialDistribution(0xee173282D4B93a5c2a7eF14A3E14818C67303190, 20000000, 6 * month);
    }





    function triggerTokenSend() public whenNotPaused  {

        require(TGEDate != 0, "TGE date not set yet");

        require(block.timestamp > TGEDate, "TGE still has not started");

        require(block.timestamp.sub(lastDateDistribution) > 1 days, "Can only be called once a day");
        lastDateDistribution = block.timestamp;

        for(uint i = 0; i < tokenOwners.length; i++) {

            DistributionStep[] memory d = distributions[tokenOwners[i]];

            for(uint j = 0; j < d.length; j++){
                if( (block.timestamp.sub(TGEDate) > d[j].unlockDay)
                    && (d[j].currentAllocated > 0)
                ){
                    uint256 sendingAmount;
                    sendingAmount = d[j].currentAllocated;
                    distributions[tokenOwners[i]][j].currentAllocated = distributions[tokenOwners[i]][j].currentAllocated.sub(sendingAmount);
                    distributions[tokenOwners[i]][j].amountSent = distributions[tokenOwners[i]][j].amountSent.add(sendingAmount);
                    require(erc20.transfer(tokenOwners[i], sendingAmount));
                }
            }
        }
    }

    function setInitialDistribution(address _address, uint256 _tokenAmount, uint256 _unlockDays) internal onlyOwner whenNotPaused {

        bool isAddressPresent = false;


        for(uint i = 0; i < tokenOwners.length; i++) {
            if(tokenOwners[i] == _address){
                isAddressPresent = true;
            }
        }

        DistributionStep memory distributionStep = DistributionStep(_tokenAmount * decimals, _tokenAmount * decimals, _unlockDays, 0);

        distributions[_address].push(distributionStep);


        if(!isAddressPresent){
            tokenOwners.push(_address);
        }

    }
}
