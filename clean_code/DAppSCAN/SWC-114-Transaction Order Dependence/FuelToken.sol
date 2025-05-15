pragma solidity ^0.4.15;

import "zeppelin-solidity/contracts/math/SafeMath.sol";
import 'zeppelin-solidity/contracts/ownership/Ownable.sol';
import 'zeppelin-solidity/contracts/token/ERC20.sol';
import "./helpers/NonZero.sol";


contract FuelToken is ERC20, Ownable, NonZero {

    using SafeMath for uint;


    string public constant name = "Fuel Token";
    string public constant symbol = "FUEL";

    uint8 public decimals = 18;


    mapping (address => uint256) balances;

    mapping (address => mapping (address => uint256)) allowed;




    uint256 public totalAllocatedTokens;

    uint256 public vanbexTeamSupply;

    uint256 public platformSupply;

    uint256 public amountOfPublicTokensToAllocate;

    uint256 public presaleSupply;

    uint256 public presaleAmountRemaining;

    uint256 public icoSupply;

    uint256 public incentivisingEffortsSupply;

    uint256 public crowdfundEndsAt;

    uint256 public vanbexTeamVestingPeriod;


    address public crowdfundAddress;

    address public vanbexTeamAddress;

    address public platformAddress;

    address public incentivisingEffortsAddress;

    address public etherpartyAddress;


    bool public presaleFinalized = false;

    bool public crowdfundFinalized = false;




    event CrowdfundFinalized(uint tokens);

    event PresaleFinalized(uint tokens);




    modifier notBeforeCrowdfundEnds(){
        require(now >= crowdfundEndsAt);
        _;
    }


    modifier checkVanbexTeamVestingPeriod() {
        assert(now >= vanbexTeamVestingPeriod);
        _;
    }


    modifier onlyCrowdfund() {
        require(msg.sender == crowdfundAddress);
        _;
    }




    function transfer(address _to, uint256 _amount) notBeforeCrowdfundEnds nonZeroAmount(_amount) returns (bool success) {
        require(balanceOf(msg.sender) >= _amount);
        addToBalance(_to, _amount);
        decrementBalance(msg.sender, _amount);
        Transfer(msg.sender, _to, _amount);
        return true;
    }


    function transferFrom(address _from, address _to, uint256 _amount) notBeforeCrowdfundEnds nonZeroAmount(_amount) returns (bool success) {
        require(allowance(_from, msg.sender) >= _amount);
        addToBalance(_to, _amount);
        decrementBalance(_from, _amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        Transfer(_from, _to, _amount);
        return true;
    }


    function approve(address _spender, uint256 _value) returns (bool success) {
        require((_value == 0) || (allowance(msg.sender, _spender) == 0));
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }


    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }


    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }




    function FuelToken() {
        crowdfundEndsAt = 1507852800;
        vanbexTeamVestingPeriod = crowdfundEndsAt.add(183 * 1 days);

        totalSupply = 1 * 10**27;
        vanbexTeamSupply = 5 * 10**25;
        platformSupply = 5 * 10**25;
        incentivisingEffortsSupply = 1 * 10**26;
        presaleSupply = 54 * 10**25;
        icoSupply = 26 * 10**25;

        amountOfPublicTokensToAllocate = presaleSupply + icoSupply;
        presaleAmountRemaining = presaleSupply;
        vanbexTeamAddress = 0x413ea1484137526f3b1bd412e2f897c94c8e198d;
        platformAddress = 0xa1602060f4630ef560009a3377a6b788d2b90484;
        incentivisingEffortsAddress = 0xc82fe29c67e63df7a09902140c5354fd6279c86c;

        addToBalance(incentivisingEffortsAddress, incentivisingEffortsSupply);
        addToBalance(platformAddress, platformSupply);

        allocateTokens(incentivisingEffortsSupply);
        allocateTokens(platformSupply);
    }


    function setCrowdfundAddress(address _crowdfundAddress) external onlyOwner nonZeroAddress(_crowdfundAddress) {
        require(crowdfundAddress == 0x0);
        crowdfundAddress = _crowdfundAddress;
        addToBalance(crowdfundAddress, icoSupply);
    }


    function setEtherpartyAddress(address _etherpartyAddress) external onlyOwner nonZeroAddress(_etherpartyAddress) {
        etherpartyAddress = _etherpartyAddress;
    }


    function transferFromCrowdfund(address _to, uint256 _amount) onlyCrowdfund nonZeroAmount(_amount) nonZeroAddress(_to) returns (bool success) {
        require(balanceOf(crowdfundAddress) >= _amount);
        decrementBalance(crowdfundAddress, _amount);
        addToBalance(_to, _amount);
        allocateTokens(_amount);
        Transfer(crowdfundAddress, _to, _amount);
        return true;
    }


    function releaseVanbexTeamTokens() checkVanbexTeamVestingPeriod onlyOwner returns(bool success) {
        require(vanbexTeamSupply > 0);
        addToBalance(vanbexTeamAddress, vanbexTeamSupply);
        Transfer(this, vanbexTeamAddress, vanbexTeamSupply);
        allocateTokens(vanbexTeamSupply);
        vanbexTeamSupply = 0;
        return true;
    }


    function finalizePresale() external onlyOwner returns (bool success) {
        require(presaleFinalized == false);
        uint256 amount = presaleAmountRemaining;
        if (amount != 0) {
            presaleAmountRemaining = 0;
            addToBalance(crowdfundAddress, amount);
        }
        presaleFinalized = true;
        PresaleFinalized(amount);
        return true;
    }


    function finalizeCrowdfund() external onlyCrowdfund notBeforeCrowdfundEnds returns (bool success) {
        require(crowdfundFinalized == false);
        uint256 amount = balanceOf(crowdfundAddress);
        if (amount > 0) {
            balances[crowdfundAddress] = 0;
            addToBalance(platformAddress, amount);
            Transfer(crowdfundAddress, platformAddress, amount);
        }
        crowdfundFinalized = true;
        CrowdfundFinalized(amount);
        return true;
    }



    function deliverPresaleFuelBalances(address[] _batchOfAddresses, uint[] _amountOfFuel) external onlyOwner returns (bool success) {
        for (uint256 i = 0; i < _batchOfAddresses.length; i++) {
            deliverPresaleFuelBalance(_batchOfAddresses[i], _amountOfFuel[i]);
        }
        return true;
    }



    function deliverPresaleFuelBalance(address _accountHolder, uint _amountOfBoughtFuel) internal onlyOwner {
        require(balanceOf(_accountHolder) == 0 && presaleAmountRemaining > 0);
        addToBalance(_accountHolder, _amountOfBoughtFuel);
        Transfer(this, _accountHolder, _amountOfBoughtFuel);
        presaleAmountRemaining = presaleAmountRemaining.sub(_amountOfBoughtFuel);
        allocateTokens(_amountOfBoughtFuel);
    }


    function addToBalance(address _address, uint _amount) internal {
    	balances[_address] = balances[_address].add(_amount);
    }


    function decrementBalance(address _address, uint _amount) internal {
    	balances[_address] = balances[_address].sub(_amount);
    }


    function allocateTokens(uint _amount) internal {
    	totalAllocatedTokens = totalAllocatedTokens.add(_amount);
    }


    function () {
        revert();
    }
}
