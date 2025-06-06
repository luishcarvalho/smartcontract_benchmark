




pragma solidity ^0.6.12;

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
        uint256 c ;

        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c ;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c ;

        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c ;

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
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
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


library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance ;

        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance ;

        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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
        address msgSender ;

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

interface IERC20Token is IERC20 {
    function maxSupply() external view returns (uint256);
    function issue(address account, uint256 amount) external returns (bool);
    function burn(uint256 amount) external returns (bool);
}

contract DevAward {

    address public dev;
    uint256 public devStartBlock;
    uint256 public devAccAwards;
    uint256 public devPerBlock;
    uint256 public MaxAvailAwards;
    uint256 public claimedIncentives;
}

contract AwardInfo {
    struct TaxInfo {
        uint256 epoch;
        uint256 amount;
    }

    struct UserInfo {
        uint256 freeAmount;
        uint256 taxHead;
        uint256 taxTail;
        bool notEmpty;
        TaxInfo[] taxList;
    }


    uint256 public taxEpoch ;

    uint256 public epUnit ;



    mapping(address => UserInfo) internal userInfo;


    address public treasury;
}

contract AwardContract is DevAward, AwardInfo, Ownable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20Token;


    IERC20Token public platformToken;
    mapping(address => bool) public governors;
    modifier onlyGovernor{
        require(governors[_msgSender()], "AwardContract: caller is not the governor");
        _;
    }

    event AddFreeAward(address user, uint256 amount);
    event AddAward(address user, uint256 amount);
    event Withdraw(address user, uint256 amount, uint256 tax);

    constructor(
        IERC20Token _platformToken,
        uint256 _taxEpoch,
        address _treasury,
        address _dev,
        uint256 _devStartBlock,
        uint256 _devPerBlock
    ) public {
        require(_taxEpoch > 0, "AwardContract: taxEpoch invalid");
        require(_dev != address(0), "AwardContract: dev invalid");
        require(address(_platformToken) != address(0), "AwardContract: platform token invalid");
        require(_devStartBlock != 0, "AwardContract: dev start block invalid");

        platformToken = _platformToken;
        taxEpoch = _taxEpoch;
        governors[_msgSender()] = true;


        treasury = _treasury;

        dev = _dev;

        MaxAvailAwards = platformToken.maxSupply().mul(10).div(100);
        devPerBlock = _devPerBlock;
        devStartBlock = _devStartBlock;
    }


    function getUserTotalAwards(address user) view public returns (uint256){
        UserInfo memory info = userInfo[user];
        uint256 amount ;

        if (info.notEmpty) {
            uint256 cursor ;

            while (true) {
                amount = amount.add(info.taxList[cursor].amount);
                cursor = cursor.add(1).mod(taxEpoch);
                if (cursor == info.taxTail) {
                    break;
                }
            }
        }
        return amount;
    }


    function getCurrentFreeAwards(address user) view public returns (uint256){
        uint256 rebaseEp ;

        UserInfo memory info = userInfo[user];
        uint256 amount ;

        if (info.notEmpty) {
            uint256 cursor ;

            while (info.taxList[cursor].epoch <= rebaseEp) {
                amount = amount.add(info.taxList[cursor].amount);
                cursor = cursor.add(1).mod(taxEpoch);
                if (cursor == info.taxTail) {
                    break;
                }
            }
        }
        return amount;
    }


    function getUserAvailAwards(address user) view public returns (uint256){
        uint256 current ;

        uint256 rebaseEp ;

        UserInfo memory info = userInfo[user];
        uint256 amount ;

        if (info.notEmpty) {
            uint256 _ep ;

            uint256 cursor ;

            while (true) {
                if (info.taxList[cursor].epoch > rebaseEp) {
                    uint rate ;

                    uint256 available ;

                    amount = amount.add(available);
                } else {
                    amount = amount.add(info.taxList[cursor].amount);
                }
                cursor = cursor.add(1).mod(taxEpoch);
                if (cursor == info.taxTail) {
                    break;
                }
            }
        }
        return amount;
    }


    function estimateTax(uint256 _amount) view external returns (uint256){
        uint256 _current ;

        uint256 tax ;

        UserInfo memory user = userInfo[msg.sender];
        if (user.freeAmount >= _amount) {
            return 0;
        }
        else {
            uint256 current ;

            uint256 arrears ;

            uint256 _head ;

            uint256 _ep ;

            while (user.notEmpty) {

                TaxInfo memory taxInfo = user.taxList[_head];
                uint rate ;

                if (rate > 1e12) {
                    rate = 1e12;
                }
                uint256 available ;

                if (available >= arrears) {
                    uint256 newAmount ;

                    tax = tax.add(newAmount.sub(arrears));
                    arrears = 0;
                    break;
                }
                else {
                    arrears = arrears.sub(available);
                    tax = tax.add(taxInfo.amount.sub(available));
                    _head = _head.add(1).mod(taxEpoch);
                    if (_head == user.taxTail) {
                        break;
                    }
                }
            }
            require(arrears == 0, "AwardContract: Insufficient Balance");
            return tax;
        }
    }


    function addGovernor(address governor) onlyOwner external {
        governors[governor] = true;
    }


    function removeGovernor(address governor) onlyOwner external {
        governors[governor] = false;
    }


    function claimDevAwards() external {
        require(msg.sender == dev, "AwardContract: only dev can receive awards");
        require(devAccAwards < MaxAvailAwards, "AwardContract: dev awards exceed permitted amount");
        uint256 amount ;

        uint256 rewards ;

        if (amount > MaxAvailAwards) {
            rewards = MaxAvailAwards.sub(devAccAwards);
        }
        safeIssue(dev, rewards, "AwardContract: dev claim awards failed");
        devAccAwards = devAccAwards.add(rewards);
    }


    function addFreeAward(address _user, uint256 _amount) onlyGovernor external {
        UserInfo storage user = userInfo[_user];
        user.freeAmount = user.freeAmount.add(_amount);
        emit AddFreeAward(_user, _amount);
    }


    function addAward(address _user, uint256 _amount) onlyGovernor public {
        uint256 current ;


        UserInfo storage user = userInfo[_user];

        if (user.taxList.length == 0) {
            user.taxList.push(TaxInfo({
            epoch : current,
            amount : _amount
            }));
            user.taxHead = 0;
            user.taxTail = 1;
            user.notEmpty = true;
        }
        else {

            if (user.notEmpty) {
                uint256 end;
                if (user.taxTail == 0) {
                    end = user.taxList.length - 1;
                } else {
                    end = user.taxTail.sub(1);
                }
                if (user.taxList[end].epoch >= current) {
                    user.taxList[end].amount = user.taxList[end].amount.add(_amount);
                } else {
                    if (user.taxList.length < taxEpoch) {
                        user.taxList.push(TaxInfo({
                        epoch : current,
                        amount : _amount
                        }));
                    } else {
                        if (user.taxHead == user.taxTail) {
                            rebase(user, current);
                        }
                        user.taxList[user.taxTail].epoch = current;
                        user.taxList[user.taxTail].amount = _amount;
                    }
                    user.taxTail = user.taxTail.add(1).mod(taxEpoch);
                }
            } else {
                if (user.taxList.length < taxEpoch) {
                    user.taxList.push(TaxInfo({
                    epoch : current,
                    amount : _amount
                    }));
                } else {
                    user.taxList[user.taxTail].epoch = current;
                    user.taxList[user.taxTail].amount = _amount;
                }
                user.taxTail = user.taxTail.add(1).mod(taxEpoch);
                user.notEmpty = true;
            }
        }
        emit AddAward(_user, _amount);
    }


    function batchAddAwards(address[] memory _users, uint256[] memory _amounts) onlyGovernor external {
        require(_users.length == _amounts.length, "AwardContract: params invalid");
        for (uint i ; i < _users.length; i++) {

            addAward(_users[i], _amounts[i]);
        }
    }

    function withdraw(uint256 _amount) external {
        uint256 current ;

        uint256 _destroy ;


        UserInfo storage user = userInfo[msg.sender];

        rebase(user, current);

        if (user.freeAmount >= _amount) {
            user.freeAmount = user.freeAmount.sub(_amount);
        }
        else {
            uint256 arrears ;

            user.freeAmount = 0;
            uint256 _head ;

            uint256 _ep ;

            while (user.notEmpty) {

                uint rate ;


                uint256 available ;


                if (available >= arrears) {
                    uint256 newAmount ;

                    user.taxList[_head].amount = user.taxList[_head].amount.sub(newAmount);
                    _destroy = _destroy.add(newAmount.sub(arrears));
                    arrears = 0;
                    break;
                }
                else {
                    arrears = arrears.sub(available);
                    _destroy = _destroy.add(user.taxList[_head].amount.sub(available));
                    _head = _head.add(1).mod(taxEpoch);
                    if (_head == user.taxTail) {
                        user.notEmpty = false;
                    }
                }
            }
            user.taxHead = _head;
            require(arrears == 0, "AwardContract: Insufficient Balance");
            safeIssue(treasury, _destroy, "AwardContract: levy tax failed");
        }
        safeIssue(msg.sender, _amount, "AwardContract: claim awards failed");
        emit Withdraw(msg.sender, _amount, _destroy);
    }

    function pendingIncentives() view public returns (uint256){
        uint256 startBlock ;

        if (block.number <= startBlock) return 0;

        uint256 maxIncent ;

        uint256 incents ;

        if (incents > maxIncent) {
            return maxIncent.sub(claimedIncentives);
        } else {
            return incents.sub(claimedIncentives);
        }
    }

    function claimIncentives(address to, uint256 amount) external {
        require(msg.sender == dev, "AwardContract: unauthorized");
        require(to != dev, "AwardContract: dev so greedy");
        uint256 pending ;

        require(amount <= pending, "AwardContract: incentives exceed");
        safeIssue(to, amount, "AwardContract: claim incentives err");
        claimedIncentives = claimedIncentives.add(amount);
    }

    function destroy(uint256 amount) onlyGovernor external {
        safeIssue(treasury, amount, "AwardContract: levy tax failed");
    }

    function getCurrEpoch() internal view returns (uint256) {
        return now.div(epUnit);
    }

    function safeIssue(address user, uint256 amount, string memory err) internal {
        if (amount > 0) {
            require(amount.add(platformToken.totalSupply()) <= platformToken.maxSupply(), "AwardContract: awards exceeds maxSupply");
            require(platformToken.issue(user, amount), err);
        }
    }

    function rebase(UserInfo storage _user, uint256 _current) internal {
        uint256 rebaseEp ;

        uint256 head ;

        while (_user.notEmpty && _user.taxList[head].epoch <= rebaseEp) {
            _user.freeAmount = _user.freeAmount.add(_user.taxList[head].amount);
            head = head.add(1).mod(taxEpoch);
            if (head == _user.taxTail) {
                _user.notEmpty = false;
            }
        }
        _user.taxHead = head;
    }
}
