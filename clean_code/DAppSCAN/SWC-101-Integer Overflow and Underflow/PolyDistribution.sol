pragma solidity ^0.4.18;

import './interfaces/IERC20.sol';
import './PolyToken.sol';
import './SafeMath.sol';
import './Ownable.sol';






contract PolyDistribution is Ownable {
  using SafeMath for uint256;

  PolyToken public POLY;

  uint256 private constant decimalFactor = 10**uint256(18);
  enum AllocationType { PRESALE, FOUNDER, AIRDROP, ADVISOR, RESERVE, BONUS1, BONUS2, BONUS3 }
  uint256 public constant INITIAL_SUPPLY   = 1000000000 * decimalFactor;
  uint256 public AVAILABLE_TOTAL_SUPPLY    = 1000000000 * decimalFactor;
  uint256 public AVAILABLE_PRESALE_SUPPLY  =  240000000 * decimalFactor;
  uint256 public AVAILABLE_FOUNDER_SUPPLY  =  150000000 * decimalFactor;
  uint256 public AVAILABLE_AIRDROP_SUPPLY  =   10000000 * decimalFactor;
  uint256 public AVAILABLE_ADVISOR_SUPPLY  =   25000000 * decimalFactor;
  uint256 public AVAILABLE_RESERVE_SUPPLY  =  495000000 * decimalFactor;

  uint256 public AVAILABLE_BONUS1_SUPPLY  =    20000000 * decimalFactor;
  uint256 public AVAILABLE_BONUS2_SUPPLY  =    30000000 * decimalFactor;
  uint256 public AVAILABLE_BONUS3_SUPPLY  =    30000000 * decimalFactor;

  uint256 public grandTotalClaimed = 0;
  uint256 public startTime;


  struct Allocation {
    uint8 AllocationSupply;
    uint256 endCliff;
    uint256 endVesting;
    uint256 totalAllocated;
    uint256 amountClaimed;
  }
  mapping (address => Allocation) public allocations;


  mapping (address => bool) public airdropAdmins;


  mapping (address => bool) public airdrops;

  modifier onlyOwnerOrAdmin() {
    require(msg.sender == owner || airdropAdmins[msg.sender]);
    _;
  }

  event LogNewAllocation(address indexed _recipient, AllocationType indexed _fromSupply, uint256 _totalAllocated, uint256 _grandTotalAllocated);
  event LogPolyClaimed(address indexed _recipient, uint8 indexed _fromSupply, uint256 _amountClaimed, uint256 _totalAllocated, uint256 _grandTotalClaimed);





    function PolyDistribution(uint256 _startTime) public {
      require(_startTime >= now);
      require(AVAILABLE_TOTAL_SUPPLY == AVAILABLE_PRESALE_SUPPLY.add(AVAILABLE_FOUNDER_SUPPLY).add(AVAILABLE_AIRDROP_SUPPLY).add(AVAILABLE_ADVISOR_SUPPLY).add(AVAILABLE_BONUS1_SUPPLY).add(AVAILABLE_BONUS2_SUPPLY).add(AVAILABLE_BONUS3_SUPPLY).add(AVAILABLE_RESERVE_SUPPLY));
      startTime = _startTime;
      POLY = new PolyToken(this);
    }







  function setAllocation (address _recipient, uint256 _totalAllocated, AllocationType _supply) onlyOwner public {
    require(allocations[_recipient].totalAllocated == 0 && _totalAllocated > 0);
    require(_supply >= AllocationType.PRESALE && _supply <= AllocationType.BONUS3);
    require(_recipient != address(0));
    if (_supply == AllocationType.PRESALE) {
      AVAILABLE_PRESALE_SUPPLY = AVAILABLE_PRESALE_SUPPLY.sub(_totalAllocated);
      allocations[_recipient] = Allocation(uint8(AllocationType.PRESALE), 0, 0, _totalAllocated, 0);
    } else if (_supply == AllocationType.FOUNDER) {
      AVAILABLE_FOUNDER_SUPPLY = AVAILABLE_FOUNDER_SUPPLY.sub(_totalAllocated);
      allocations[_recipient] = Allocation(uint8(AllocationType.FOUNDER), startTime + 1 years, startTime + 4 years, _totalAllocated, 0);
    } else if (_supply == AllocationType.ADVISOR) {
      AVAILABLE_ADVISOR_SUPPLY = AVAILABLE_ADVISOR_SUPPLY.sub(_totalAllocated);
      allocations[_recipient] = Allocation(uint8(AllocationType.ADVISOR), startTime + 212 days, 0, _totalAllocated, 0);
    } else if (_supply == AllocationType.RESERVE) {
      AVAILABLE_RESERVE_SUPPLY = AVAILABLE_RESERVE_SUPPLY.sub(_totalAllocated);
      allocations[_recipient] = Allocation(uint8(AllocationType.RESERVE), startTime + 182 days, startTime + 4 years, _totalAllocated, 0);
    } else if (_supply == AllocationType.BONUS1) {
      AVAILABLE_BONUS1_SUPPLY = AVAILABLE_BONUS1_SUPPLY.sub(_totalAllocated);
      allocations[_recipient] = Allocation(uint8(AllocationType.BONUS1), startTime + 1 years, startTime + 1 years, _totalAllocated, 0);
    } else if (_supply == AllocationType.BONUS2) {
      AVAILABLE_BONUS2_SUPPLY = AVAILABLE_BONUS2_SUPPLY.sub(_totalAllocated);
      allocations[_recipient] = Allocation(uint8(AllocationType.BONUS2), startTime + 2 years, startTime + 2 years, _totalAllocated, 0);
    } else if (_supply == AllocationType.BONUS3) {
      AVAILABLE_BONUS3_SUPPLY = AVAILABLE_BONUS3_SUPPLY.sub(_totalAllocated);
      allocations[_recipient] = Allocation(uint8(AllocationType.BONUS3), startTime + 3 years, startTime + 3 years, _totalAllocated, 0);
    }
    AVAILABLE_TOTAL_SUPPLY = AVAILABLE_TOTAL_SUPPLY.sub(_totalAllocated);
    LogNewAllocation(_recipient, _supply, _totalAllocated, grandTotalAllocated());
  }




  function setAirdropAdmin(address _admin, bool _isAdmin) public onlyOwner {
    airdropAdmins[_admin] = _isAdmin;
  }





  function airdropTokens(address[] _recipient) public onlyOwnerOrAdmin {
    require(now >= startTime);
    uint airdropped;

    for(uint8 i = 0; i< _recipient.length; i++)
    {
        if (!airdrops[_recipient[i]]) {
          airdrops[_recipient[i]] = true;
          require(POLY.transfer(_recipient[i], 250 * decimalFactor));
          airdropped = airdropped.add(250 * decimalFactor);
        }
    }
    AVAILABLE_AIRDROP_SUPPLY = AVAILABLE_AIRDROP_SUPPLY.sub(airdropped);
    AVAILABLE_TOTAL_SUPPLY = AVAILABLE_TOTAL_SUPPLY.sub(airdropped);
    grandTotalClaimed = grandTotalClaimed.add(airdropped);
  }





  function transferTokens (address _recipient) public {
    require(allocations[_recipient].amountClaimed < allocations[_recipient].totalAllocated);
    require(now >= allocations[_recipient].endCliff);
    require(now >= startTime);
    uint256 newAmountClaimed;
    if (allocations[_recipient].endVesting > now) {

      newAmountClaimed = allocations[_recipient].totalAllocated.mul(now.sub(startTime)).div(allocations[_recipient].endVesting.sub(startTime));
    } else {

      newAmountClaimed = allocations[_recipient].totalAllocated;
    }
    uint256 tokensToTransfer = newAmountClaimed.sub(allocations[_recipient].amountClaimed);
    allocations[_recipient].amountClaimed = newAmountClaimed;
    POLY.transfer(_recipient, tokensToTransfer);
    grandTotalClaimed = grandTotalClaimed.add(tokensToTransfer);
    LogPolyClaimed(_recipient, allocations[_recipient].AllocationSupply, tokensToTransfer, newAmountClaimed, grandTotalClaimed);
  }


  function grandTotalAllocated() public view returns (uint256) {
    return INITIAL_SUPPLY - AVAILABLE_TOTAL_SUPPLY;
  }


  function refundTokens(address _recipient, address _token) public onlyOwner {
    require(_token != address(POLY));
    IERC20 token = IERC20(_token);
    uint256 balance = token.balanceOf(this);
    token.transfer(_recipient, balance);
  }
}
