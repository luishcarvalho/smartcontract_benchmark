
pragma solidity ^0.7.6;
pragma abicoder v2;

import "hardhat/console.sol";





import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./lib/math/MathUtils.sol";

import "./Governed.sol";
import "./IController.sol";
import "./oracle/IYieldOraclelizable.sol";
import "./ISmartYield.sol";

import "./IProvider.sol";

import "./model/IBondModel.sol";
import "./oracle/IYieldOracle.sol";
import "./IBond.sol";
import "./JuniorToken.sol";

contract SmartYield is
    JuniorToken,
    ISmartYield
{
    using SafeMath for uint256;


    address public controller;


    address public pool;


    address public seniorBond;


    address public juniorBond;


    uint256 public underlyingLiquidatedJuniors;


    uint256 public tokensInJuniorBonds;


    uint256 public seniorBondId;


    uint256 public juniorBondId;


    uint256 public juniorBondsMaturitiesPrev;

    uint256[] public juniorBondsMaturities;



    mapping(uint256 => JuniorBondsAt) public juniorBondsMaturingAt;



    mapping(uint256 => SeniorBond) public seniorBonds;



    mapping(uint256 => JuniorBond) public juniorBonds;



    SeniorBond public abond;

    bool public _setup;

    constructor(
      string memory name_,
      string memory symbol_
    )
      JuniorToken(name_, symbol_)
    {}

    function setup(
      address controller_,
      address pool_,
      address seniorBond_,
      address juniorBond_
    )
      external
    {
        require(
          false == _setup,
          "SY: already setup"
        );

        controller = controller_;
        pool = pool_;
        seniorBond = seniorBond_;
        juniorBond = juniorBond_;

        _setup = true;
    }




    function buyTokens(
      uint256 underlyingAmount_,
      uint256 minTokens_,
      uint256 deadline_
    )
      external override
    {
        _beforeProviderOp();

        require(
          false == IController(controller).PAUSED_BUY_JUNIOR_TOKEN(),
          "SY: buyTokens paused"
        );

        require(
          this.currentTime() <= deadline_,
          "SY: buyTokens deadline"
        );

        uint256 fee = MathUtils.fractionOf(underlyingAmount_, IController(controller).FEE_BUY_JUNIOR_TOKEN());
        uint256 getsTokens = (underlyingAmount_ - fee) * 1e18 / this.price();

        require(
          getsTokens >= minTokens_,
          "SY: buyTokens minTokens"
        );



        IProvider(pool)._takeUnderlying(msg.sender, underlyingAmount_);
        IProvider(pool)._depositProvider(underlyingAmount_, fee);
        _mint(msg.sender, getsTokens);
    }


    function sellTokens(
      uint256 tokenAmount_,
      uint256 minUnderlying_,
      uint256 deadline_
    )
      external override
    {
        _beforeProviderOp();

        require(
          this.currentTime() <= deadline_,
          "SY: sellTokens deadline"
        );


        uint256 debtShare = tokenAmount_ * 1e18 / totalSupply();

        uint256 toPay = (tokenAmount_ * this.price() - this.abondDebt() * debtShare) / 1e18;

        require(
          toPay >= minUnderlying_,
          "SY: sellTokens minUnderlying"
        );



        _burn(msg.sender, tokenAmount_);
        IProvider(pool)._withdrawProvider(toPay, 0);
        IProvider(pool)._sendUnderlying(msg.sender, toPay);
    }


    function buyBond(
        uint256 principalAmount_,
        uint256 minGain_,
        uint256 deadline_,
        uint16 forDays_
    )
      external override
    {
        _beforeProviderOp();

        require(
          false == IController(controller).PAUSED_BUY_SENIOR_BOND(),
          "SY: buyBond paused"
        );

        require(
          this.currentTime() <= deadline_,
          "SY: buyBond deadline"
        );

        require(
            0 < forDays_ && forDays_ <= IController(controller).BOND_LIFE_MAX(),
            "SY: buyBond forDays"
        );

        uint256 gain = this.bondGain(principalAmount_, forDays_);

        require(
          gain >= minGain_,
          "SY: buyBond minGain"
        );

        require(
          gain > 0,
          "SY: buyBond gain 0"
        );

        require(
          gain < this.underlyingLoanable(),
          "SY: buyBond underlyingLoanable"
        );

        uint256 issuedAt = this.currentTime();



        IProvider(pool)._takeUnderlying(msg.sender, principalAmount_);
        IProvider(pool)._depositProvider(principalAmount_, 0);

        SeniorBond memory b =
            SeniorBond(
                principalAmount_,
                gain,
                issuedAt,
                uint256(1 days) * uint256(forDays_) + issuedAt,
                false
            );

        _mintBond(msg.sender, b);
    }


    function buyJuniorBond(
      uint256 tokenAmount_,
      uint256 maxMaturesAt_,
      uint256 deadline_
    )
      external override
    {
        uint256 maturesAt = 1 + abond.maturesAt / 1e18;

        require(
          this.currentTime() <= deadline_,
          "SY: buyJuniorBond deadline"
        );

        require(
          maturesAt <= maxMaturesAt_,
          "SY: buyJuniorBond maxMaturesAt"
        );

        JuniorBond memory jb = JuniorBond(
          tokenAmount_,
          maturesAt
        );



        _takeTokens(msg.sender, tokenAmount_);
        _mintJuniorBond(msg.sender, jb);


        if (this.currentTime() >= maturesAt) {
            JuniorBondsAt memory jBondsAt = juniorBondsMaturingAt[jb.maturesAt];

            if (jBondsAt.price == 0) {
                _liquidateJuniorsAt(jb.maturesAt);
            } else {

                _burn(address(this), jb.tokens);
                underlyingLiquidatedJuniors += jb.tokens * jBondsAt.price / 1e18;
                _unaccountJuniorBond(jb);
            }
            return this.redeemJuniorBond(juniorBondId);
        }
    }


    function redeemBond(
      uint256 bondId_
    )
      external override
    {
        _beforeProviderOp();

        require(
            this.currentTime() >= seniorBonds[bondId_].maturesAt,
            "SY: redeemBond not matured"
        );


        address payTo = IBond(seniorBond).ownerOf(bondId_);
        uint256 payAmnt = seniorBonds[bondId_].gain + seniorBonds[bondId_].principal;
        uint256 fee = MathUtils.fractionOf(seniorBonds[bondId_].gain, IController(controller).FEE_REDEEM_SENIOR_BOND());
        payAmnt -= fee;



        if (seniorBonds[bondId_].liquidated == false) {
            seniorBonds[bondId_].liquidated = true;
            _unaccountBond(seniorBonds[bondId_]);
        }


        IBond(seniorBond).burn(bondId_);
        delete seniorBonds[bondId_];

        IProvider(pool)._withdrawProvider(payAmnt, fee);
        IProvider(pool)._sendUnderlying(payTo, payAmnt);
    }


    function redeemJuniorBond(uint256 jBondId_)
        external override
    {
        _beforeProviderOp();

        JuniorBond memory jb = juniorBonds[jBondId_];
        require(
            jb.maturesAt <= this.currentTime(),
            "SY: redeemJuniorBond maturesAt"
        );

        JuniorBondsAt memory jBondsAt = juniorBondsMaturingAt[jb.maturesAt];


        address payTo = IBond(juniorBond).ownerOf(jBondId_);
        uint256 payAmnt = jBondsAt.price * jb.tokens / 1e18;



        _burnJuniorBond(jBondId_);
        IProvider(pool)._withdrawProvider(payAmnt, 0);
        IProvider(pool)._sendUnderlying(payTo, payAmnt);
        underlyingLiquidatedJuniors -= payAmnt;
    }


    function providerRatePerDay()
      external view virtual override
    returns (uint256)
    {
        return MathUtils.min(
          IController(controller).BOND_MAX_RATE_PER_DAY(),
          IYieldOracle(IController(controller).oracle()).consult(1 days)
        );
    }


    function bondGain(uint256 principalAmount_, uint16 forDays_)
      external view override
    returns (uint256)
    {
        return IBondModel(IController(controller).bondModel()).gain(address(this), principalAmount_, forDays_);
    }





    function currentTime()
      public view virtual override
    returns (uint256)
    {

        return block.timestamp;
    }


    function price()
      public view override
    returns (uint256)
    {
        uint256 ts = totalSupply();
        return (ts == 0) ? 1e18 : (this.underlyingJuniors() * 1e18) / ts;
    }

    function underlyingTotal()
      public view virtual override
    returns(uint256)
    {
      return IProvider(pool).underlyingBalance() - IProvider(pool).underlyingFees() - underlyingLiquidatedJuniors;
    }

    function underlyingJuniors()
      public view virtual override
    returns (uint256)
    {
        return this.underlyingTotal() - abond.principal - this.abondPaid();
    }

    function underlyingLoanable()
      public view virtual override
    returns (uint256)
    {

        return this.underlyingTotal() - abond.principal - abond.gain - (tokensInJuniorBonds * this.price() / 1e18);
    }

    function abondGain()
      public view override
    returns (uint256)
    {
        return abond.gain;
    }

    function abondPaid()
      public view override
    returns (uint256)
    {
        uint256 ts = this.currentTime() * 1e18;
        if (ts <= abond.issuedAt || (abond.maturesAt <= abond.issuedAt)) {
          return 0;
        }

        uint256 d = abond.maturesAt - abond.issuedAt;
        return (this.abondGain() * MathUtils.min(ts - abond.issuedAt, d)) / d;
    }

    function abondDebt()
      public view override
    returns (uint256)
    {
        return this.abondGain() - this.abondPaid();
    }





    function _beforeProviderOp() internal {



      for (uint256 i = juniorBondsMaturitiesPrev; i < juniorBondsMaturities.length; i++) {
          if (this.currentTime() >= juniorBondsMaturities[i]) {
              _liquidateJuniorsAt(juniorBondsMaturities[i]);
              juniorBondsMaturitiesPrev = i + 1;
          } else {
              break;
          }
      }
    }

    function _liquidateJuniorsAt(uint256 timestamp_)
      internal
    {
        JuniorBondsAt storage jBondsAt = juniorBondsMaturingAt[timestamp_];

        require(
          jBondsAt.tokens > 0,
          "SY: nothing to liquidate"
        );

        require(
          jBondsAt.price == 0,
          "SY: already liquidated"
        );

        jBondsAt.price = this.price();



        underlyingLiquidatedJuniors += jBondsAt.tokens * jBondsAt.price / 1e18;
        _burn(address(this), jBondsAt.tokens);
        tokensInJuniorBonds -= jBondsAt.tokens;
    }


    function unaccountBonds(uint256[] memory bondIds_) public override {
      for (uint256 f = 0; f < bondIds_.length; f++) {
        if (
            this.currentTime() > seniorBonds[bondIds_[f]].maturesAt &&
            seniorBonds[bondIds_[f]].liquidated == false
        ) {
            seniorBonds[bondIds_[f]].liquidated = true;
            _unaccountBond(seniorBonds[bondIds_[f]]);
        }
      }
    }

    function _mintBond(address to_, SeniorBond memory bond_)
      internal
    {
        require(
          seniorBondId < uint256(-1),
          "SY: _mintBond"
        );

        seniorBondId++;
        seniorBonds[seniorBondId] = bond_;
        _accountBond(bond_);
        IBond(seniorBond).mint(to_, seniorBondId);
    }




    function _accountBond(SeniorBond memory b_)
      internal
    {
        uint256 _now = this.currentTime() * 1e18;

        uint256 newDebt = this.abondDebt() + b_.gain;

        uint256 newMaturesAt = (abond.maturesAt * this.abondDebt() + b_.maturesAt * 1e18 * b_.gain) / newDebt;


        uint256 newIssuedAt = newMaturesAt.sub(uint256(1) + ((abond.gain + b_.gain) * (newMaturesAt - _now)) / newDebt, "SY: liquidate some seniorBonds");

        abond = SeniorBond(
          abond.principal + b_.principal,
          abond.gain + b_.gain,
          newIssuedAt,
          newMaturesAt,
          false
        );
    }




    function _unaccountBond(SeniorBond memory b_)
      internal
    {
        uint256 now_ = this.currentTime() * 1e18;

        if ((now_ >= abond.maturesAt)) {


          abond = SeniorBond(
            abond.principal - b_.principal,
            abond.gain - b_.gain,
            now_ - (abond.maturesAt - abond.issuedAt),
            now_,
            false
          );

          return;
        }


        uint256 newIssuedAt = abond.maturesAt.sub(uint256(1) + (abond.gain - b_.gain) * (abond.maturesAt - now_) / this.abondDebt(), "SY: liquidate some seniorBonds");

        abond = SeniorBond(
          abond.principal - b_.principal,
          abond.gain - b_.gain,
          newIssuedAt,
          abond.maturesAt,
          false
        );
    }

    function _mintJuniorBond(address to_, JuniorBond memory jb_)
      internal
    {
        require(
          juniorBondId < uint256(-1),
          "SY: _mintJuniorBond"
        );

        juniorBondId++;
        juniorBonds[juniorBondId] = jb_;

        _accountJuniorBond(jb_);
        IBond(juniorBond).mint(to_, juniorBondId);
    }

    function _accountJuniorBond(JuniorBond memory jb_)
      internal
    {
        tokensInJuniorBonds += jb_.tokens;

        JuniorBondsAt storage jBondsAt = juniorBondsMaturingAt[jb_.maturesAt];
        uint256 tmp;

        if (jBondsAt.tokens == 0 && this.currentTime() < jb_.maturesAt) {
          juniorBondsMaturities.push(jb_.maturesAt);
          for (uint256 i = juniorBondsMaturities.length - 1; i >= MathUtils.max(1, juniorBondsMaturitiesPrev); i--) {
            if (juniorBondsMaturities[i] > juniorBondsMaturities[i - 1]) {
              break;
            }
            tmp = juniorBondsMaturities[i - 1];
            juniorBondsMaturities[i - 1] = juniorBondsMaturities[i];
            juniorBondsMaturities[i] = tmp;
          }
        }

        jBondsAt.tokens += jb_.tokens;
    }

    function _burnJuniorBond(uint256 bondId_) internal {




        IBond(juniorBond).burn(bondId_);
    }

    function _unaccountJuniorBond(JuniorBond memory jb_) internal {
        tokensInJuniorBonds -= jb_.tokens;
        JuniorBondsAt storage jBondsAt = juniorBondsMaturingAt[jb_.maturesAt];
        jBondsAt.tokens -= jb_.tokens;
    }

    function _takeTokens(address _from, uint256 _amount) internal {

        require(
            transferFrom(_from, address(this), _amount),
            "SY: _takeTokens transferFrom"
        );
    }



}
