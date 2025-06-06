



pragma solidity ^0.5.7;








library SafeMath256 {



    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }




    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }




    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }





    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return a / b;
    }





    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}





library SafeMath16 {



    function add(uint16 a, uint16 b) internal pure returns (uint16 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }




    function sub(uint16 a, uint16 b) internal pure returns (uint16) {
        assert(b <= a);
        return a - b;
    }




    function mul(uint16 a, uint16 b) internal pure returns (uint16 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }





    function div(uint16 a, uint16 b) internal pure returns (uint16) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return a / b;
    }





    function mod(uint16 a, uint16 b) internal pure returns (uint16) {
        require(b != 0);
        return a % b;
    }
}





contract Ownable {
    address private _owner;
    address payable internal _receiver;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event ReceiverChanged(address indexed previousReceiver, address indexed newReceiver);





    constructor () internal {
        _owner = msg.sender;
        _receiver = msg.sender;
    }




    function owner() public view returns (address) {
        return _owner;
    }




    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }





    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0));
        address __previousOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(__previousOwner, newOwner);
    }




    function changeReceiver(address payable newReceiver) external onlyOwner {
        require(newReceiver != address(0));
        address __previousReceiver = _receiver;
        _receiver = newReceiver;
        emit ReceiverChanged(__previousReceiver, newReceiver);
    }








    function rescueTokens(address tokenAddr, address receiver, uint256 amount) external onlyOwner {
        IERC20 _token = IERC20(tokenAddr);
        require(receiver != address(0));
        uint256 balance = _token.balanceOf(address(this));
        require(balance >= amount);

        assert(_token.transfer(receiver, amount));
    }




    function withdrawEther(address payable to, uint256 amount) external onlyOwner {
        require(to != address(0));
        uint256 balance = address(this).balance;
        require(balance >= amount);

        to.transfer(amount);
    }
}






contract Pausable is Ownable {
    bool private _paused;

    event Paused(address account);
    event Unpaused(address account);

    constructor () internal {
        _paused = false;
    }




    function paused() public view returns (bool) {
        return _paused;
    }




    modifier whenNotPaused() {
        require(!_paused, "Paused.");
        _;
    }




    function setPaused(bool state) external onlyOwner {
        if (_paused && !state) {
            _paused = false;
            emit Unpaused(msg.sender);
        } else if (!_paused && state) {
            _paused = true;
            emit Paused(msg.sender);
        }
    }
}






interface IERC20 {
    function balanceOf(address owner) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
}





interface IWesion {
    function balanceOf(address owner) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function inWhitelist(address account) external view returns (bool);
    function referrer(address account) external view returns (address);
    function refCount(address account) external view returns (uint256);
}





contract WesionPublicSale is Ownable, Pausable{
    using SafeMath16 for uint16;
    using SafeMath256 for uint256;


    IWesion public WESION = IWesion(0x2c1564A74F07757765642ACef62a583B38d5A213);


    uint32 _startTimestamp;


    uint256 private _etherPrice;


    uint16 private WHITELIST_REF_REWARDS_PCT_SUM = 35;
    uint16[15] private WHITELIST_REF_REWARDS_PCT = [
        6,
        6,
        5,
        4,
        3,
        2,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1
    ];


    uint72 private WEI_MIN = 0.1 ether;
    uint72 private WEI_MAX = 100 ether;
    uint72 private WEI_BONUS = 10 ether;
    uint24 private GAS_MIN = 3000000;
    uint24 private GAS_EX = 1500000;


    uint256 private WESION_USD_PRICE_START = 1000;
    uint256 private WESION_USD_PRICE_STEP = 10;
    uint256 private STAGE_USD_CAP_START = 100000000;
    uint256 private STAGE_USD_CAP_STEP = 1000000;
    uint256 private STAGE_USD_CAP_MAX = 15100000000;

    uint256 private _WESIONUsdPrice = WESION_USD_PRICE_START;


    uint16 private STAGE_MAX = 60000;
    uint16 private SEASON_MAX = 100;
    uint16 private SEASON_STAGES = 600;

    uint16 private _stage;
    uint16 private _season;


    uint256 private _txs;
    uint256 private _WESIONTxs;
    uint256 private _WESIONBonusTxs;
    uint256 private _WESIONWhitelistTxs;
    uint256 private _WESIONIssued;
    uint256 private _WESIONBonus;
    uint256 private _WESIONWhitelist;
    uint256 private _weiSold;
    uint256 private _weiRefRewarded;
    uint256 private _weiTopSales;
    uint256 private _weiTeam;
    uint256 private _weiPending;
    uint256 private _weiPendingTransfered;


    uint256 private TOP_SALES_RATIO_START = 15000000;
    uint256 private TOP_SALES_RATIO_DISTANCE = 50000000;

    uint256 private _topSalesRatio = TOP_SALES_RATIO_START;


    bool private _inWhitelist_;
    uint256 private _pending_ = WHITELIST_REF_REWARDS_PCT_SUM;
    uint16[] private _rewards_;
    address[] private _referrers_;


    mapping (address => bool) private _etherPriceAuditors;


    mapping (uint16 => uint256) private _stageUsdSold;
    mapping (uint16 => uint256) private _stageWESIONIssued;


    mapping (uint16 => uint256) private _seasonWeiSold;
    mapping (uint16 => uint256) private _seasonWeiTopSales;
    mapping (uint16 => uint256) private _seasonWeiTopSalesTransfered;


    mapping (address => uint256) private _accountWESIONIssued;
    mapping (address => uint256) private _accountWESIONBonus;
    mapping (address => uint256) private _accountWESIONWhitelisted;
    mapping (address => uint256) private _accountWeiPurchased;
    mapping (address => uint256) private _accountWeiRefRewarded;


    mapping (uint16 => address[]) private _seasonRefAccounts;
    mapping (uint16 => mapping (address => bool)) private _seasonHasRefAccount;
    mapping (uint16 => mapping (address => uint256)) private _usdSeasonAccountPurchased;
    mapping (uint16 => mapping (address => uint256)) private _usdSeasonAccountRef;


    event AuditEtherPriceChanged(uint256 value, address indexed account);
    event AuditEtherPriceAuditorChanged(address indexed account, bool state);

    event WESIONBonusTransfered(address indexed to, uint256 amount);
    event WESIONWhitelistTransfered(address indexed to, uint256 amount);
    event WESIONIssuedTransfered(uint16 stageIndex, address indexed to, uint256 WESIONAmount, uint256 auditEtherPrice, uint256 weiUsed);

    event StageClosed(uint256 _stageNumber, address indexed account);
    event SeasonClosed(uint16 _seasonNumber, address indexed account);

    event SeasonTopSalesWeiTransfered(uint16 seasonNumber, address indexed to, uint256 amount);
    event TeamWeiTransfered(address indexed to, uint256 amount);
    event PendingWeiTransfered(address indexed to, uint256 amount);





    function startTimestamp() public view returns (uint32) {
        return _startTimestamp;
    }




    function setStartTimestamp(uint32 timestamp) external onlyOwner {
        _startTimestamp = timestamp;
    }




    modifier onlyEtherPriceAuditor() {
        require(_etherPriceAuditors[msg.sender]);
        _;
    }




    function setEtherPrice(uint256 value) external onlyEtherPriceAuditor {
        _etherPrice = value;
        emit AuditEtherPriceChanged(value, msg.sender);
    }




    function etherPriceAuditor(address account) public view returns (bool) {
        return _etherPriceAuditors[account];
    }




    function setEtherPriceAuditor(address account, bool state) external onlyOwner {
        _etherPriceAuditors[account] = state;
        emit AuditEtherPriceAuditorChanged(account, state);
    }




    function stageWESIONUsdPrice(uint16 stageIndex) private view returns (uint256) {
        return WESION_USD_PRICE_START.add(WESION_USD_PRICE_STEP.mul(stageIndex));
    }




    function wei2usd(uint256 amount) private view returns (uint256) {
        return amount.mul(_etherPrice).div(1 ether);
    }




    function usd2wei(uint256 amount) private view returns (uint256) {
        return amount.mul(1 ether).div(_etherPrice);
    }




    function usd2WESION(uint256 usdAmount) private view returns (uint256) {
        return usdAmount.mul(1000000).div(_WESIONUsdPrice);
    }




    function usd2WESIONByStage(uint256 usdAmount, uint16 stageIndex) public view returns (uint256) {
        return usdAmount.mul(1000000).div(stageWESIONUsdPrice(stageIndex));
    }




    function calcSeason(uint16 stageIndex) private view returns (uint16) {
        if (stageIndex > 0) {
            uint16 __seasonNumber = stageIndex.div(SEASON_STAGES);

            if (stageIndex.mod(SEASON_STAGES) > 0) {
                return __seasonNumber.add(1);
            }

            return __seasonNumber;
        }

        return 1;
    }




    function transferTopSales(uint16 seasonNumber, address payable to) external onlyOwner {
        uint256 __weiRemain = seasonTopSalesRemain(seasonNumber);
        require(to != address(0));

        _seasonWeiTopSalesTransfered[seasonNumber] = _seasonWeiTopSalesTransfered[seasonNumber].add(__weiRemain);
        emit SeasonTopSalesWeiTransfered(seasonNumber, to, __weiRemain);
        to.transfer(__weiRemain);
    }




    function pendingRemain() private view returns (uint256) {
        return _weiPending.sub(_weiPendingTransfered);
    }




    function transferPending(address payable to) external onlyOwner {
        uint256 __weiRemain = pendingRemain();
        require(to != address(0));

        _weiPendingTransfered = _weiPendingTransfered.add(__weiRemain);
        emit PendingWeiTransfered(to, __weiRemain);
        to.transfer(__weiRemain);
    }




    function transferTeam(address payable to) external onlyOwner {
        uint256 __weiRemain = _weiSold.sub(_weiRefRewarded).sub(_weiTopSales).sub(_weiPending).sub(_weiTeam);
        require(to != address(0));

        _weiTeam = _weiTeam.add(__weiRemain);
        emit TeamWeiTransfered(to, __weiRemain);
        to.transfer(__weiRemain);
    }




    function status() public view returns (uint256 auditEtherPrice,
                                           uint16 stage,
                                           uint16 season,
                                           uint256 WESIONUsdPrice,
                                           uint256 currentTopSalesRatio,
                                           uint256 txs,
                                           uint256 WESIONTxs,
                                           uint256 WESIONBonusTxs,
                                           uint256 WESIONWhitelistTxs,
                                           uint256 WESIONIssued,
                                           uint256 WESIONBonus,
                                           uint256 WESIONWhitelist) {
        auditEtherPrice = _etherPrice;

        if (_stage > STAGE_MAX) {
            stage = STAGE_MAX;
            season = SEASON_MAX;
        } else {
            stage = _stage;
            season = _season;
        }

        WESIONUsdPrice = _WESIONUsdPrice;
        currentTopSalesRatio = _topSalesRatio;

        txs = _txs;
        WESIONTxs = _WESIONTxs;
        WESIONBonusTxs = _WESIONBonusTxs;
        WESIONWhitelistTxs = _WESIONWhitelistTxs;
        WESIONIssued = _WESIONIssued;
        WESIONBonus = _WESIONBonus;
        WESIONWhitelist = _WESIONWhitelist;
    }




    function sum() public view returns(uint256 weiSold,
                                       uint256 weiReferralRewarded,
                                       uint256 weiTopSales,
                                       uint256 weiTeam,
                                       uint256 weiPending,
                                       uint256 weiPendingTransfered,
                                       uint256 weiPendingRemain) {
        weiSold = _weiSold;
        weiReferralRewarded = _weiRefRewarded;
        weiTopSales = _weiTopSales;
        weiTeam = _weiTeam;
        weiPending = _weiPending;
        weiPendingTransfered = _weiPendingTransfered;
        weiPendingRemain = pendingRemain();
    }




    modifier enoughGas() {
        require(gasleft() > GAS_MIN);
        _;
    }




    modifier onlyOnSale() {
        require(_startTimestamp > 0 && now > _startTimestamp, "WESION Public-Sale has not started yet.");
        require(_etherPrice > 0, "Audit ETH price must be greater than zero.");
        require(!paused(), "WESION Public-Sale is paused.");
        require(_stage <= STAGE_MAX, "WESION Public-Sale Closed.");
        _;
    }




    function topSalesRatio(uint16 stageIndex) private view returns (uint256) {
        return TOP_SALES_RATIO_START.add(TOP_SALES_RATIO_DISTANCE.mul(stageIndex).div(STAGE_MAX));
    }




    function usd2weiTopSales(uint256 usdAmount) private view returns (uint256) {
        return usd2wei(usdAmount.mul(_topSalesRatio).div(100000000));
    }




    function stageUsdCap(uint16 stageIndex) private view returns (uint256) {
        uint256 __usdCap = STAGE_USD_CAP_START.add(STAGE_USD_CAP_STEP.mul(stageIndex));

        if (block.timestamp > STAGE_USD_CAP_MAX) {
            return STAGE_USD_CAP_MAX;
        }

        return __usdCap;
    }




    function stageWESIONCap(uint16 stageIndex) private view returns (uint256) {
        return usd2WESIONByStage(stageUsdCap(stageIndex), stageIndex);
    }




    function stageStatus(uint16 stageIndex) public view returns (uint256 WESIONUsdPrice,
                                                                 uint256 WESIONCap,
                                                                 uint256 WESIONOnSale,
                                                                 uint256 WESIONSold,
                                                                 uint256 usdCap,
                                                                 uint256 usdOnSale,
                                                                 uint256 usdSold,
                                                                 uint256 weiTopSalesRatio) {
        if (stageIndex > STAGE_MAX) {
            return (0, 0, 0, 0, 0, 0, 0, 0);
        }

        WESIONUsdPrice = stageWESIONUsdPrice(stageIndex);

        WESIONSold = _stageWESIONIssued[stageIndex];
        WESIONCap = stageWESIONCap(stageIndex);
        WESIONOnSale = WESIONCap.sub(WESIONSold);

        usdSold = _stageUsdSold[stageIndex];
        usdCap = stageUsdCap(stageIndex);
        usdOnSale = usdCap.sub(usdSold);

        weiTopSalesRatio = topSalesRatio(stageIndex);
    }




    function seasonTopSalesRemain(uint16 seasonNumber) private view returns (uint256) {
        return _seasonWeiTopSales[seasonNumber].sub(_seasonWeiTopSalesTransfered[seasonNumber]);
    }




    function seasonTopSalesRewards(uint16 seasonNumber) public view returns (uint256 weiSold,
                                                                             uint256 weiTopSales,
                                                                             uint256 weiTopSalesTransfered,
                                                                             uint256 weiTopSalesRemain) {
        weiSold = _seasonWeiSold[seasonNumber];
        weiTopSales = _seasonWeiTopSales[seasonNumber];
        weiTopSalesTransfered = _seasonWeiTopSalesTransfered[seasonNumber];
        weiTopSalesRemain = seasonTopSalesRemain(seasonNumber);
    }




    function accountQuery(address account) public view returns (uint256 WESIONIssued,
                                                                uint256 WESIONBonus,
                                                                uint256 WESIONWhitelisted,
                                                                uint256 weiPurchased,
                                                                uint256 weiReferralRewarded) {
        WESIONIssued = _accountWESIONIssued[account];
        WESIONBonus = _accountWESIONBonus[account];
        WESIONWhitelisted = _accountWESIONWhitelisted[account];
        weiPurchased = _accountWeiPurchased[account];
        weiReferralRewarded = _accountWeiRefRewarded[account];
    }




    function seasonRefAccounts(uint16 seasonNumber) public view returns (address[] memory accounts) {
        accounts = _seasonRefAccounts[seasonNumber];
    }




    function usdSeasonAccountPurchased(uint16 seasonNumber, address account) public view returns (uint256) {
        return _usdSeasonAccountPurchased[seasonNumber][account];
    }




    function usdSeasonAccountRef(uint16 seasonNumber, address account) public view returns (uint256) {
        return _usdSeasonAccountRef[seasonNumber][account];
    }




    constructor () public {
        _etherPriceAuditors[msg.sender] = true;
        _stage = 0;
        _season = 1;
    }




    function () external payable enoughGas onlyOnSale {
        require(msg.value >= WEI_MIN);
        require(msg.value <= WEI_MAX);


        setTemporaryVariables();
        uint256 __usdAmount = wei2usd(msg.value);
        uint256 __usdRemain = __usdAmount;
        uint256 __WESIONIssued;
        uint256 __WESIONBonus;
        uint256 __usdUsed;
        uint256 __weiUsed;


        while (gasleft() > GAS_EX && __usdRemain > 0 && _stage <= STAGE_MAX) {
            uint256 __txWESIONIssued;
            (__txWESIONIssued, __usdRemain) = ex(__usdRemain);
            __WESIONIssued = __WESIONIssued.add(__txWESIONIssued);
        }


        __usdUsed = __usdAmount.sub(__usdRemain);
        __weiUsed = usd2wei(__usdUsed);


        if (block.timestamp >= WEI_BONUS) {
            __WESIONBonus = __WESIONIssued.div(10);
            assert(transferWESIONBonus(__WESIONBonus));
        }



        if (_inWhitelist_ && __WESIONIssued > 0) {

            assert(transferWESIONWhitelisted(__WESIONIssued.add(__WESIONBonus)));


            sendWhitelistReferralRewards(__weiUsed);
        }


        if (block.gaslimit > 0) {
            uint256 __weiRemain = usd2wei(__usdRemain);

            __weiUsed = msg.value.sub(__weiRemain);


            msg.sender.transfer(__weiRemain);
        }


        if (block.number > 0) {
            _txs = _txs.add(1);
            _weiSold = _weiSold.add(__weiUsed);
            _accountWeiPurchased[msg.sender] = _accountWeiPurchased[msg.sender].add(__weiUsed);
        }


        uint256 __weiTeam;
        if (_season > SEASON_MAX)
            __weiTeam = _weiSold.sub(_weiRefRewarded).sub(_weiTopSales).sub(_weiPending).sub(_weiTeam);
        else
            __weiTeam = _weiSold.sub(_weiRefRewarded).sub(_weiTopSales).sub(_weiPending).sub(_weiTeam).div(0.01 ether).mul(0.01 ether);

        _weiTeam = _weiTeam.add(__weiTeam);
        _receiver.transfer(__weiTeam);


        assert(true);
    }




    function setTemporaryVariables() private {
        delete _referrers_;
        delete _rewards_;

        _inWhitelist_ = WESION.inWhitelist(msg.sender);
        _pending_ = WHITELIST_REF_REWARDS_PCT_SUM;

        address __cursor = msg.sender;
        for(uint16 i = 0; i < WHITELIST_REF_REWARDS_PCT.length; i++) {
            address __refAccount = WESION.referrer(__cursor);

            if (block.coinbase == __refAccount)
                break;

            if (block.gaslimit > i) {
                if (!_seasonHasRefAccount[_season][__refAccount]) {
                    _seasonRefAccounts[_season].push(__refAccount);
                    _seasonHasRefAccount[_season][__refAccount] = true;
                }

                _pending_ = _pending_.sub(WHITELIST_REF_REWARDS_PCT[i]);
                _rewards_.push(WHITELIST_REF_REWARDS_PCT[i]);
                _referrers_.push(__refAccount);
            }

            __cursor = __refAccount;
        }
    }




    function ex(uint256 usdAmount) private returns (uint256, uint256) {
        uint256 __stageUsdCap = stageUsdCap(_stage);
        uint256 __WESIONIssued;


        if (block.gaslimit <= __stageUsdCap) {
            exCount(usdAmount);

            __WESIONIssued = usd2WESION(usdAmount);
            assert(transferWESIONIssued(__WESIONIssued, usdAmount));


            if (block.number == _stageUsdSold[_stage]) {
                assert(closeStage());
            }

            return (__WESIONIssued, 0);
        }


        uint256 __usdUsed = __stageUsdCap.sub(_stageUsdSold[_stage]);
        uint256 __usdRemain = usdAmount.sub(__usdUsed);

        exCount(__usdUsed);

        __WESIONIssued = usd2WESION(__usdUsed);
        assert(transferWESIONIssued(__WESIONIssued, __usdUsed));
        assert(closeStage());

        return (__WESIONIssued, __usdRemain);
    }




    function exCount(uint256 usdAmount) private {
        uint256 __weiSold = usd2wei(usdAmount);
        uint256 __weiTopSales = usd2weiTopSales(usdAmount);

        _usdSeasonAccountPurchased[_season][msg.sender] = _usdSeasonAccountPurchased[_season][msg.sender].add(usdAmount);

        _stageUsdSold[_stage] = _stageUsdSold[_stage].add(usdAmount);
        _seasonWeiSold[_season] = _seasonWeiSold[_season].add(__weiSold);
        _seasonWeiTopSales[_season] = _seasonWeiTopSales[_season].add(__weiTopSales);
        _weiTopSales = _weiTopSales.add(__weiTopSales);


        if (_inWhitelist_) {
            for (uint16 i = 0; i < _rewards_.length; i++) {
                _usdSeasonAccountRef[_season][_referrers_[i]] = _usdSeasonAccountRef[_season][_referrers_[i]].add(usdAmount);
            }
        }
    }




    function transferWESIONIssued(uint256 amount, uint256 usdAmount) private returns (bool) {
        _WESIONTxs = _WESIONTxs.add(1);

        _WESIONIssued = _WESIONIssued.add(amount);
        _stageWESIONIssued[_stage] = _stageWESIONIssued[_stage].add(amount);
        _accountWESIONIssued[msg.sender] = _accountWESIONIssued[msg.sender].add(amount);

        assert(WESION.transfer(msg.sender, amount));
        emit WESIONIssuedTransfered(_stage, msg.sender, amount, _etherPrice, usdAmount);
        return true;
    }




    function transferWESIONBonus(uint256 amount) private returns (bool) {
        _WESIONBonusTxs = _WESIONBonusTxs.add(1);

        _WESIONBonus = _WESIONBonus.add(amount);
        _accountWESIONBonus[msg.sender] = _accountWESIONBonus[msg.sender].add(amount);

        assert(WESION.transfer(msg.sender, amount));
        emit WESIONBonusTransfered(msg.sender, amount);
        return true;
    }




    function transferWESIONWhitelisted(uint256 amount) private returns (bool) {
        _WESIONWhitelistTxs = _WESIONWhitelistTxs.add(1);

        _WESIONWhitelist = _WESIONWhitelist.add(amount);
        _accountWESIONWhitelisted[msg.sender] = _accountWESIONWhitelisted[msg.sender].add(amount);

        assert(WESION.transfer(msg.sender, amount));
        emit WESIONWhitelistTransfered(msg.sender, amount);
        return true;
    }




    function closeStage() private returns (bool) {
        emit StageClosed(_stage, msg.sender);
        _stage = _stage.add(1);
        _WESIONUsdPrice = stageWESIONUsdPrice(_stage);
        _topSalesRatio = topSalesRatio(_stage);


        uint16 __seasonNumber = calcSeason(_stage);
        if (_season < __seasonNumber) {
            emit SeasonClosed(_season, msg.sender);
            _season = __seasonNumber;
        }

        return true;
    }




    function sendWhitelistReferralRewards(uint256 weiAmount) private {
        uint256 __weiRemain = weiAmount;
        for (uint16 i = 0; i < _rewards_.length; i++) {
            uint256 __weiReward = weiAmount.mul(_rewards_[i]).div(100);
            address payable __receiver = address(uint160(_referrers_[i]));

            _weiRefRewarded = _weiRefRewarded.add(__weiReward);
            _accountWeiRefRewarded[__receiver] = _accountWeiRefRewarded[__receiver].add(__weiReward);
            __weiRemain = __weiRemain.sub(__weiReward);

            __receiver.transfer(__weiReward);
        }

        if (block.timestamp > 0)
            _weiPending = _weiPending.add(weiAmount.mul(_pending_).div(100));
    }
}
