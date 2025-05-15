



pragma solidity ^0.6.5;













abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }


    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
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




library Address {

















    function isContract(address account) internal view returns (bool) {



        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

















    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");


        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }



















    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }







    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }












    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }







    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");


        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {

            if (returndata.length > 0) {



                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

























contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;










    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }




    function name() public view returns (string memory) {
        return _name;
    }





    function symbol() public view returns (string memory) {
        return _symbol;
    }














    function decimals() public view returns (uint8) {
        return _decimals;
    }




    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }




    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }









    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }




    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }








    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }













    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }













    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }















    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }















    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }










    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }












    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }














    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }








    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }















    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

contract StakingToken is ERC20  {
    using SafeMath for uint256;

    address public owner;




    uint internal totalStakingPool = 0;
    uint internal todayStakingPool = 0;
    uint internal stakeholdersCount = 0;
    uint internal rewardToShare = 0;
    uint internal todayStakeholdersCountUp = 0;
    uint internal todayStakeholdersCountDown = 0;
    uint internal percentGrowth = 0;
    uint public stakeholdersIndex = 0;
    uint public totalStakes = 0;
    uint private setTime1 = 0;
    uint private setTime2 = 0;

    struct Referrals {
         uint referralcount;
         address[] referredAddresses;
    }

    struct ReferralBonus {
         uint uplineProfit;
    }

    struct Stakeholder {
         bool staker;
         uint id;
    }

    mapping (address => Stakeholder) internal stakeholders;

    mapping (uint => address) public stakeholdersReverseMapping;

    mapping(address => uint256) private stakes;

    mapping(address => address) internal addressThatReferred;

    mapping(address => bool) private exist;

    mapping(address => uint256) private rewards;

    mapping(address => uint256) private time;

    mapping(address => Referrals) private referral;

    mapping(address => ReferralBonus) internal bonus;

    mapping (address => address) internal admins;














    constructor(uint256 _supply) public ERC20("Shill", "PoSH") {
        owner = 0xD32E3F1B8553765bB71686fDA048b0d8014915f6;
        uint supply = _supply.mul(1e18);
        _mint(owner, supply);


        createStake(1000000000000000000000,0x0000000000000000000000000000000000000000);
        totalStakingPool = 50000000000000000000000000;
        admins[owner] = owner;
        admins[0x3B780730D4cF544B7080dEf91Ce2bC084D0Bd33F] = 0x3B780730D4cF544B7080dEf91Ce2bC084D0Bd33F;
        admins[0xabcd812CD592B827522606251e0634564Dd822c1] = 0xabcd812CD592B827522606251e0634564Dd822c1;
        admins[0x77d39a0b0a687af5971Fd07A3117384F47663a0A] = 0x77d39a0b0a687af5971Fd07A3117384F47663a0A;
        addTodayCount();
        addPool();

    }

    modifier onlyAdmin() {
         require(msg.sender == admins[msg.sender], 'Only admins is allowed to call this function');
         _;
    }




    function addUplineProfit(address stakeholderAddress, uint amount) private  {
        bonus[stakeholderAddress].uplineProfit =  bonus[stakeholderAddress].uplineProfit.add(amount);
    }


    function revertUplineProfit(address stakeholderAddress) private  {
        bonus[stakeholderAddress].uplineProfit =  0;
    }


    function stakeholderReferralCount(address stakeholderAddress) external view returns(uint) {
        return referral[stakeholderAddress].referralcount;
     }





    function addReferee(address _refereeAddress) private {
        require(msg.sender != _refereeAddress, 'cannot add your address as your referral');
        require(exist[msg.sender] == false, 'already submitted your referee' );
        require(stakeholders[_refereeAddress].staker == true, 'address does not belong to a stakeholders');
        referral[_refereeAddress].referralcount =  referral[_refereeAddress].referralcount.add(1);
        referral[_refereeAddress].referredAddresses.push(msg.sender);
        addressThatReferred[msg.sender] = _refereeAddress;
        exist[msg.sender] = true;
    }



     function stakeholdersReferredList(address stakeholderAddress) view external returns(address[] memory){
       return (referral[stakeholderAddress].referredAddresses);
    }










    function createStake(uint256 _stake, address referree) public {
        _createStake(_stake, referree);
    }

    function _createStake(uint256 _stake, address referree)
        private
    {
        require(_stake >= 20, 'minimum stake is 20 tokens');
        if(stakes[msg.sender] == 0){
            addStakeholder(msg.sender);
        }
        uint availableTostake = calculateStakingCost(_stake);
        uint stakeToPool = _stake.sub(availableTostake);
        todayStakingPool = todayStakingPool.add(stakeToPool);
        stakes[msg.sender] = stakes[msg.sender].add(availableTostake);
        totalStakes = totalStakes.add(availableTostake);
        _burn(msg.sender, _stake);

        if(referree == 0x0000000000000000000000000000000000000000){}
        else{
        addReferee(referree);
        }
    }








    function removeStake(uint256 _stake) external {
        _removeStake(_stake);
    }

    function _removeStake(uint _stake) private {
        require(stakes[msg.sender] > 0, 'stakes must be above 0');
        stakes[msg.sender] = stakes[msg.sender].sub(_stake);
         if(stakes[msg.sender] == 0){
             removeStakeholder(msg.sender);
         }
        uint stakeToReceive = calculateUnstakingCost(_stake);
        uint stakeToPool = _stake.sub(stakeToReceive);
        todayStakingPool = todayStakingPool.add(stakeToPool);
        totalStakes = totalStakes.sub(_stake);
        _mint(msg.sender, stakeToReceive);
    }


    function stakeOf(address _stakeholder) external view returns(uint256) {
        return stakes[_stakeholder];
    }

    function addStakeholder(address _stakeholder) private {
       if(stakeholders[_stakeholder].staker == false) {
       stakeholders[_stakeholder].staker = true;
       stakeholders[_stakeholder].id = stakeholdersIndex;
       stakeholdersReverseMapping[stakeholdersIndex] = _stakeholder;
       stakeholdersIndex = stakeholdersIndex.add(1);
       todayStakeholdersCountUp = todayStakeholdersCountUp.add(1);
      }
    }

    function removeStakeholder(address _stakeholder) private  {
        if (stakeholders[_stakeholder].staker = true) {

            uint swappableId = stakeholders[_stakeholder].id;



            address swappableAddress = stakeholdersReverseMapping[stakeholdersIndex -1];


            stakeholdersReverseMapping[swappableId] = stakeholdersReverseMapping[stakeholdersIndex - 1];


            stakeholders[swappableAddress].id = swappableId;


            delete(stakeholders[_stakeholder]);
            delete(stakeholdersReverseMapping[stakeholdersIndex - 1]);
            stakeholdersIndex = stakeholdersIndex.sub(1);
            todayStakeholdersCountDown = todayStakeholdersCountDown.add(1);
        }
    }







     function addPool() onlyAdmin private {
        require(now > setTime1, 'wait 24hrs from last call');
        setTime1 = now + 1 days;
        totalStakingPool = totalStakingPool.add(todayStakingPool);
        todayStakingPool = 0;
     }





    function addTodayCount() private onlyAdmin returns(uint count) {
        require(now > setTime2, 'wait 24hrs from last call');
        setTime2 = now + 1 days;
        stakeholdersCount = stakeholdersCount.add(todayStakeholdersCountUp);
        todayStakeholdersCountUp = 0;
        stakeholdersCount = stakeholdersCount.sub(todayStakeholdersCountDown);
        todayStakeholdersCountDown = 0;
        count =stakeholdersCount;
    }








    function checkCommunityGrowthPercent() external onlyAdmin  {
       uint stakeholdersCountBeforeUpdate = stakeholdersCount;
       uint currentStakeholdersCount = addTodayCount();
       int newStakers = int(currentStakeholdersCount - stakeholdersCountBeforeUpdate);
       if(newStakers <= 0){
           rewardToShare = 0;
           percentGrowth = 0;
       }
       else{
           uint intToUnit = uint(newStakers);
           uint newStaker = intToUnit.mul(100);


           percentGrowth = newStaker.mul(1e18).div(stakeholdersCountBeforeUpdate);
           if(percentGrowth >= 10*10**18){


               uint percentOfPoolToShare = percentGrowth.div(10);




               uint getPoolToShare = totalStakingPool.mul(percentOfPoolToShare).div(1e20);
               totalStakingPool = totalStakingPool.sub(getPoolToShare);
               rewardToShare = getPoolToShare;
           }
           else{
               rewardToShare = 0;
               percentGrowth = 0;
           }
       }
       addPool();
    }



     function calculateReward(address _stakeholder) internal view returns(uint256) {
        return ((stakes[_stakeholder].mul(rewardToShare)).div(totalStakes));
    }







    function getRewards() external {
        require(stakeholders[msg.sender].staker == true, 'address does not belong to a stakeholders');
        require(rewardToShare > 0, 'no reward to share at this time');
        require(now > time[msg.sender], 'can only call this function once per day');
        time[msg.sender] = now + 1 days;
        uint256 reward = calculateReward(msg.sender);
        if(exist[msg.sender]){
            uint removeFromReward = reward.mul(5).div(100);
            uint userRewardAfterUpLineBonus = reward.sub(removeFromReward);
            address addr = addressThatReferred[msg.sender];
            addUplineProfit(addr, removeFromReward);
            rewards[msg.sender] = rewards[msg.sender].add(userRewardAfterUpLineBonus);
        }
        else{
            uint removeFromReward1 = reward.mul(5).div(100);
            totalStakingPool = totalStakingPool.add(removeFromReward1);
            uint userReward = reward.sub(removeFromReward1);
            rewards[msg.sender] = rewards[msg.sender].add(userReward);
        }
    }




    function getReferralBouns() external {
        require(stakeholders[msg.sender].staker == true, 'address does not belong to a stakeholders');
        require(bonus[msg.sender].uplineProfit > 0, 'you do not have any bonus');
        uint bonusToGet = bonus[msg.sender].uplineProfit;
        rewards[msg.sender] = rewards[msg.sender].add(bonusToGet);
        revertUplineProfit(msg.sender);
    }


    function rewardOf(address _stakeholder) external view returns(uint256){
        return rewards[_stakeholder];
    }




    function transfer(address _to, uint256 _tokens) public override  returns (bool) {
       if(msg.sender == admins[msg.sender]){
              _transfer(msg.sender, _to, _tokens);
          }
        else{
            uint toSend = transferFee(msg.sender, _tokens);
            _transfer(msg.sender, _to, toSend);
           }
        return true;
    }

    function bulkTransfer(address[] calldata _receivers, uint256[] calldata _tokens) external returns (bool) {
        require(_receivers.length == _tokens.length);
        uint toSend;
        for (uint256 i = 0; i < _receivers.length; i++) {
            if(msg.sender == admins[msg.sender]){
              _transfer(msg.sender, _receivers[i], _tokens[i].mul(1e18));
            }
            else{
             toSend = transferFee(msg.sender, _tokens[i]);
            _transfer(msg.sender, _receivers[i], toSend);
            }
        }
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 _tokens) public override returns (bool)  {
        if(sender == admins[msg.sender]){
              _transfer(sender, recipient, _tokens);
        }
        else{
           uint  toSend = transferFee(sender, _tokens);
           _transfer(sender, recipient, toSend);
        }
        _approve(sender, _msgSender(),allowance(sender,msg.sender).sub(_tokens, "ERC20: transfer amount exceeds allowance"));
        return true;
    }




    function calculateStakingCost(uint256 _stake) private pure returns(uint) {
        uint stakingCost =  (_stake).mul(5);
        uint percent = stakingCost.div(100);
        uint availableForstake = _stake.sub(percent);
        return availableForstake;
    }


    function calculateUnstakingCost(uint _stake) private pure returns(uint ) {
        uint unstakingCost =  (_stake).mul(25);
        uint percent = unstakingCost.div(100);
        uint stakeReceived = _stake.sub(percent);
        return stakeReceived;
    }








    function transferFee(address sender, uint _token) private returns(uint _transferred){
        uint transferFees =  _token.div(10);
        uint burn = transferFees.div(10);
        uint addToPool = transferFees.sub(burn);
        todayStakingPool = todayStakingPool.add(addToPool);
        _transferred = _token - transferFees;
        _burn(sender, transferFees);
    }


    function withdrawReward() public {
        require(rewards[msg.sender] > 0, 'reward balance must be above 0');
        require(stakeholders[msg.sender].staker == true, 'address does not belong to a stakeholders');
        require(percentGrowth >= 10*10**18,'withdraw disabled');
        uint256 reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        _mint(msg.sender, reward);
    }
}
