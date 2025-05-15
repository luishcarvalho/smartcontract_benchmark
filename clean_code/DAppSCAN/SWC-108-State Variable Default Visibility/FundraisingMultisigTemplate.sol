pragma solidity 0.4.24;

import "@aragon/os/contracts/common/EtherTokenConstant.sol";
import "@aragon/os/contracts/lib/token/ERC20.sol";
import "@aragon/templates-shared/contracts/BaseTemplate.sol";
import "@aragon/apps-agent/contracts/Agent.sol";
import "@ablack/fundraising-bancor-formula/contracts/BancorFormula.sol";
import {AragonFundraisingController as Controller} from "@ablack/fundraising-aragon-fundraising/contracts/AragonFundraisingController.sol";
import {BatchedBancorMarketMaker as MarketMaker} from "@ablack/fundraising-batched-bancor-market-maker/contracts/BatchedBancorMarketMaker.sol";
import "@ablack/fundraising-presale/contracts/Presale.sol";
import "@ablack/fundraising-tap/contracts/Tap.sol";


contract FundraisingMultisigTemplate is EtherTokenConstant, BaseTemplate {
    string    private constant ERROR_BAD_SETTINGS     = "FM_BAD_SETTINGS";
    string    private constant ERROR_MISSING_CACHE    = "FM_MISSING_CACHE";

    bool      private constant BOARD_TRANSFERABLE     = false;
    uint8     private constant BOARD_TOKEN_DECIMALS   = uint8(0);
    uint256   private constant BOARD_MAX_PER_ACCOUNT  = uint256(1);

    bool      private constant SHARE_TRANSFERABLE     = true;
    uint8     private constant SHARE_TOKEN_DECIMALS   = uint8(18);
    uint256   private constant SHARE_MAX_PER_ACCOUNT  = uint256(0);

    uint64    private constant DEFAULT_FINANCE_PERIOD = uint64(30 days);

    uint256   private constant BUY_FEE_PCT            = 0;
    uint256   private constant SELL_FEE_PCT           = 0;

    uint32    private constant DAI_RESERVE_RATIO      = 100000;
    uint32    private constant ANT_RESERVE_RATIO      = 10000;

    bytes32   private constant BANCOR_FORMULA_ID      = 0xd71dde5e4bea1928026c1779bde7ed27bd7ef3d0ce9802e4117631eb6fa4ed7d;
    bytes32   private constant PRESALE_ID             = 0x5de9bbdeaf6584c220c7b7f1922383bcd8bbcd4b48832080afd9d5ebf9a04df5;
    bytes32   private constant MARKET_MAKER_ID        = 0xc2bb88ab974c474221f15f691ed9da38be2f5d37364180cec05403c656981bf0;
    bytes32   private constant ARAGON_FUNDRAISING_ID  = 0x668ac370eed7e5861234d1c0a1e512686f53594fcb887e5bcecc35675a4becac;
    bytes32   private constant TAP_ID                 = 0x82967efab7144b764bc9bca2f31a721269b6618c0ff4e50545737700a5e9c9dc;

    struct Cache {
        address dao;
        address boardTokenManager;
        address boardVoting;
        address vault;
        address finance;
        address shareVoting;
        address shareTokenManager;
        address reserve;
        address presale;
        address marketMaker;
        address tap;
        address controller;
    }

    address[] public collaterals;
    mapping (address => Cache) private cache;

    constructor(
        DAOFactory              _daoFactory,
        ENS                     _ens,
        MiniMeTokenFactory      _miniMeFactory,
        IFIFSResolvingRegistrar _aragonID,
        address                 _dai,
        address                 _ant
    )
        BaseTemplate(_daoFactory, _ens, _miniMeFactory, _aragonID)
        public
    {
        _ensureAragonIdIsValid(_aragonID);
        _ensureMiniMeFactoryIsValid(_miniMeFactory);
        _ensureTokenIsContractOrETH(_dai);
        _ensureTokenIsContractOrETH(_ant);

        collaterals.push(address(_dai));
        collaterals.push(address(_ant));
    }

















































































































































































































































































































































































































































































    function _vaultCache() internal returns (Vault vault) {
        Cache storage c = cache[msg.sender];

        vault = Vault(c.vault);
    }

    function _shareTMCache() internal returns (TokenManager shareTM) {
        Cache storage c = cache[msg.sender];

        shareTM = TokenManager(c.shareTokenManager);
    }

    function _reserveCache() internal returns (Agent reserve) {
        Cache storage c = cache[msg.sender];

        reserve = Agent(c.reserve);
    }

    function _presaleCache() internal returns (Presale presale) {
        Cache storage c = cache[msg.sender];

        presale = Presale(c.presale);
    }

    function _controllerCache() internal returns (Controller controller) {
        Cache storage c = cache[msg.sender];

        controller = Controller(c.controller);
    }

















































