



pragma solidity ^0.6.10;


interface IDelegable {
    function ADDDELEGATE653(address) external;
    function ADDDELEGATEBYSIGNATURE882(address, address, uint, uint8, bytes32, bytes32) external;
}




pragma solidity ^0.6.0;


interface IERC20 {

    function TOTALSUPPLY521() external view returns (uint256);


    function BALANCEOF833(address account) external view returns (uint256);


    function TRANSFER582(address recipient, uint256 amount) external returns (bool);


    function ALLOWANCE506(address owner, address spender) external view returns (uint256);


    function APPROVE147(address spender, uint256 amount) external returns (bool);


    function TRANSFERFROM451(address sender, address recipient, uint256 amount) external returns (bool);


    event TRANSFER75(address indexed from, address indexed to, uint256 value);


    event APPROVAL533(address indexed owner, address indexed spender, uint256 value);
}



pragma solidity ^0.6.10;




interface IVat {

    function HOPE952(address) external;
    function NOPE303(address) external;
    function LIVE610() external view returns (uint);
    function ILKS57(bytes32) external view returns (uint, uint, uint, uint, uint);
    function URNS490(bytes32, address) external view returns (uint, uint);
    function GEM988(bytes32, address) external view returns (uint);

    function FROB42(bytes32, address, address, address, int, int) external;
    function FORK314(bytes32, address, address, int, int) external;
    function MOVE289(address, address, uint) external;
    function FLUX433(bytes32, address, address, uint) external;
}



pragma solidity ^0.6.10;


interface IWeth {
    function DEPOSIT338() external payable;
    function WITHDRAW817(uint) external;
    function APPROVE147(address, uint) external returns (bool) ;
    function TRANSFER582(address, uint) external returns (bool);
    function TRANSFERFROM451(address, address, uint) external returns (bool);
}



pragma solidity ^0.6.10;



interface IGemJoin {
    function RELY66(address usr) external;
    function DENY577(address usr) external;
    function CAGE307() external;
    function JOIN369(address usr, uint WAD) external;
    function EXIT932(address usr, uint WAD) external;
}



pragma solidity ^0.6.10;



interface IDaiJoin {
    function RELY66(address usr) external;
    function DENY577(address usr) external;
    function CAGE307() external;
    function JOIN369(address usr, uint WAD) external;
    function EXIT932(address usr, uint WAD) external;
}



pragma solidity ^0.6.10;




interface IPot {
    function CHI612() external view returns (uint256);
    function PIE445(address) external view returns (uint256);
    function RHO514() external returns (uint256);
    function DRIP65() external returns (uint256);
    function JOIN369(uint256) external;
    function EXIT932(uint256) external;
}



pragma solidity ^0.6.10;




interface IChai {
    function BALANCEOF833(address account) external view returns (uint256);
    function TRANSFER582(address dst, uint wad) external returns (bool);
    function MOVE289(address src, address dst, uint wad) external returns (bool);
    function TRANSFERFROM451(address src, address dst, uint wad) external returns (bool);
    function APPROVE147(address usr, uint wad) external returns (bool);
    function DAI858(address usr) external returns (uint wad);
    function JOIN369(address dst, uint wad) external;
    function EXIT932(address src, uint wad) external;
    function DRAW289(address src, uint wad) external;
    function PERMIT233(address holder, address spender, uint256 nonce, uint256 expiry, bool allowed, uint8 v, bytes32 r, bytes32 s) external;
    function NONCES538(address account) external view returns (uint256);
}



pragma solidity ^0.6.10;








interface ITreasury {
    function DEBT715() external view returns(uint256);
    function SAVINGS903() external view returns(uint256);
    function PUSHDAI613(address user, uint256 dai) external;
    function PULLDAI166(address user, uint256 dai) external;
    function PUSHCHAI91(address user, uint256 chai) external;
    function PULLCHAI479(address user, uint256 chai) external;
    function PUSHWETH634(address to, uint256 weth) external;
    function PULLWETH548(address to, uint256 weth) external;
    function SHUTDOWN178() external;
    function LIVE610() external view returns(bool);

    function VAT519() external view returns (IVat);
    function WETH278() external view returns (IWeth);
    function DAI858() external view returns (IERC20);
    function DAIJOIN173() external view returns (IDaiJoin);
    function WETHJOIN654() external view returns (IGemJoin);
    function POT408() external view returns (IPot);
    function CHAI326() external view returns (IChai);
}




pragma solidity ^0.6.0;


interface IERC2612 {

    function PERMIT233(address owner, address spender, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;


    function NONCES538(address owner) external view returns (uint256);
}



pragma solidity ^0.6.10;



interface IFYDai is IERC20, IERC2612 {
    function ISMATURE431() external view returns(bool);
    function MATURITY388() external view returns(uint);
    function CHI0242() external view returns(uint);
    function RATE0398() external view returns(uint);
    function CHIGROWTH747() external view returns(uint);
    function RATEGROWTH408() external view returns(uint);
    function MATURE589() external;
    function UNLOCKED182() external view returns (uint);
    function MINT176(address, uint) external;
    function BURN250(address, uint) external;
    function FLASHMINT22(uint, bytes calldata) external;
    function REDEEM906(address, address, uint256) external returns (uint256);



}



pragma solidity ^0.6.10;





interface IController is IDelegable {
    function TREASURY445() external view returns (ITreasury);
    function SERIES14(uint256) external view returns (IFYDai);
    function SERIESITERATOR268(uint256) external view returns (uint256);
    function TOTALSERIES702() external view returns (uint256);
    function CONTAINSSERIES982(uint256) external view returns (bool);
    function POSTED950(bytes32, address) external view returns (uint256);
    function DEBTFYDAI447(bytes32, uint256, address) external view returns (uint256);
    function DEBTDAI877(bytes32, uint256, address) external view returns (uint256);
    function TOTALDEBTDAI51(bytes32, address) external view returns (uint256);
    function ISCOLLATERALIZED839(bytes32, address) external view returns (bool);
    function INDAI269(bytes32, uint256, uint256) external view returns (uint256);
    function INFYDAI474(bytes32, uint256, uint256) external view returns (uint256);
    function ERASE227(bytes32, address) external returns (uint256, uint256);
    function SHUTDOWN178() external;
    function POST95(bytes32, address, address, uint256) external;
    function WITHDRAW817(bytes32, address, address, uint256) external;
    function BORROW691(bytes32, uint256, address, address, uint256) external;
    function REPAYFYDAI426(bytes32, uint256, address, address, uint256) external returns (uint256);
    function REPAYDAI460(bytes32, uint256, address, address, uint256) external returns (uint256);
}



pragma solidity ^0.6.10;


interface IDai is IERC20 {
    function NONCES538(address user) external view returns (uint256);
    function PERMIT233(address holder, address spender, uint256 nonce, uint256 expiry,
                    bool allowed, uint8 v, bytes32 r, bytes32 s) external;
}



pragma solidity ^0.6.10;





interface IPool is IDelegable, IERC20, IERC2612 {
    function DAI858() external view returns(IERC20);
    function FYDAI600() external view returns(IFYDai);
    function GETDAIRESERVES173() external view returns(uint128);
    function GETFYDAIRESERVES833() external view returns(uint128);
    function SELLDAI400(address from, address to, uint128 daiIn) external returns(uint128);
    function BUYDAI253(address from, address to, uint128 daiOut) external returns(uint128);
    function SELLFYDAI226(address from, address to, uint128 fyDaiIn) external returns(uint128);
    function BUYFYDAI675(address from, address to, uint128 fyDaiOut) external returns(uint128);
    function SELLDAIPREVIEW300(uint128 daiIn) external view returns(uint128);
    function BUYDAIPREVIEW913(uint128 daiOut) external view returns(uint128);
    function SELLFYDAIPREVIEW69(uint128 fyDaiIn) external view returns(uint128);
    function BUYFYDAIPREVIEW685(uint128 fyDaiOut) external view returns(uint128);
    function MINT176(address from, address to, uint256 daiOffered) external returns (uint256);
    function BURN250(address from, address to, uint256 tokensBurned) external returns (uint256, uint256);
}




pragma solidity ^0.6.0;


library SafeMath {

    function ADD958(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function SUB494(uint256 a, uint256 b) internal pure returns (uint256) {
        return SUB494(a, b, "SafeMath: subtraction overflow");
    }


    function SUB494(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }


    function MUL434(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function DIV16(uint256 a, uint256 b) internal pure returns (uint256) {
        return DIV16(a, b, "SafeMath: division by zero");
    }


    function DIV16(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;


        return c;
    }


    function MOD331(uint256 a, uint256 b) internal pure returns (uint256) {
        return MOD331(a, b, "SafeMath: modulo by zero");
    }


    function MOD331(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}



pragma solidity ^0.6.10;




contract DecimalMath {
    using SafeMath for uint256;

    uint256 constant public unit17 = 1e27;


    function MULD379(uint256 x, uint256 y) internal pure returns (uint256) {
        return x.MUL434(y).DIV16(unit17);
    }


    function DIVD836(uint256 x, uint256 y) internal pure returns (uint256) {
        return x.MUL434(unit17).DIV16(y);
    }



    function MULDRUP300(uint256 x, uint256 y) internal pure returns (uint256)
    {
        uint256 z = x.MUL434(y);
        return z.MOD331(unit17) == 0 ? z.DIV16(unit17) : z.DIV16(unit17).ADD958(1);
    }



    function DIVDRUP370(uint256 x, uint256 y) internal pure returns (uint256)
    {
        uint256 z = x.MUL434(unit17);
        return z.MOD331(y) == 0 ? z.DIV16(y) : z.DIV16(y).ADD958(1);
    }
}



pragma solidity ^0.6.10;













library SafeCast {

    function TOUINT128897(uint256 x) internal pure returns(uint128) {
        require(
            x <= type(uint128).max,
            "YieldProxy: Cast overflow"
        );
        return uint128(x);
    }


    function TOINT256710(uint256 x) internal pure returns(int256) {
        require(
            x <= uint256(type(int256).max),
            "YieldProxy: Cast overflow"
        );
        return int256(x);
    }
}

contract YieldProxy is DecimalMath {
    using SafeCast for uint256;

    IVat public vat;
    IWeth public weth;
    IDai public dai;
    IGemJoin public wethJoin;
    IDaiJoin public daiJoin;
    IChai public chai;
    IController public controller;
    ITreasury public treasury;

    IPool[] public pools;
    mapping (address => bool) public poolsMap;

    bytes32 public constant chai69 = "CHAI";
    bytes32 public constant weth148 = "ETH-A";
    bool constant public mty307 = true;
    bool constant public ytm282 = false;


    constructor(address controller_, IPool[] memory _pools) public {
        controller = IController(controller_);
        treasury = controller.TREASURY445();

        weth = treasury.WETH278();
        dai = IDai(address(treasury.DAI858()));
        chai = treasury.CHAI326();
        daiJoin = treasury.DAIJOIN173();
        wethJoin = treasury.WETHJOIN654();
        vat = treasury.VAT519();


        dai.APPROVE147(address(treasury), uint(-1));


        chai.APPROVE147(address(treasury), uint(-1));
        weth.APPROVE147(address(treasury), uint(-1));


        dai.APPROVE147(address(chai), uint(-1));

        vat.HOPE952(address(daiJoin));
        vat.HOPE952(address(wethJoin));

        dai.APPROVE147(address(daiJoin), uint(-1));
        weth.APPROVE147(address(wethJoin), uint(-1));
        weth.APPROVE147(address(treasury), uint(-1));


        for (uint i = 0 ; i < _pools.length; i++) {
            dai.APPROVE147(address(_pools[i]), uint(-1));
            _pools[i].FYDAI600().APPROVE147(address(_pools[i]), uint(-1));
            poolsMap[address(_pools[i])]= true;
        }

        pools = _pools;
    }


    function UNPACK384(bytes memory signature) private pure returns (bytes32 r, bytes32 s, uint8 v) {
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }
    }


    function ONBOARD51(address from, bytes memory daiSignature, bytes memory controllerSig) external {
        bytes32 r;
        bytes32 s;
        uint8 v;

        (r, s, v) = UNPACK384(daiSignature);
        dai.PERMIT233(from, address(this), dai.NONCES538(from), uint(-1), true, v, r, s);

        (r, s, v) = UNPACK384(controllerSig);
        controller.ADDDELEGATEBYSIGNATURE882(from, address(this), uint(-1), v, r, s);
    }


    function AUTHORIZEPOOL621(IPool pool, address from, bytes memory daiSig, bytes memory fyDaiSig, bytes memory poolSig) public {
        ONLYKNOWNPOOL167(pool);
        bytes32 r;
        bytes32 s;
        uint8 v;

        (r, s, v) = UNPACK384(daiSig);
        dai.PERMIT233(from, address(pool), dai.NONCES538(from), uint(-1), true, v, r, s);

        (r, s, v) = UNPACK384(fyDaiSig);
        pool.FYDAI600().PERMIT233(from, address(this), uint(-1), uint(-1), v, r, s);

        (r, s, v) = UNPACK384(poolSig);
        pool.ADDDELEGATEBYSIGNATURE882(from, address(this), uint(-1), v, r, s);
    }


    receive() external payable { }



    function POST95(address to)
        public payable {
        weth.DEPOSIT338{ value: msg.value }();
        controller.POST95(weth148, address(this), to, msg.value);
    }





    function WITHDRAW817(address payable to, uint256 amount)
        public {
        controller.WITHDRAW817(weth148, msg.sender, address(this), amount);
        weth.WITHDRAW817(amount);
        to.transfer(amount);
    }







    function ADDLIQUIDITY157(IPool pool, uint256 daiUsed, uint256 maxFYDai) external returns (uint256) {
        ONLYKNOWNPOOL167(pool);
        IFYDai fyDai = pool.FYDAI600();
        require(fyDai.ISMATURE431() != true, "YieldProxy: Only before maturity");
        require(dai.TRANSFERFROM451(msg.sender, address(this), daiUsed), "YieldProxy: Transfer Failed");


        uint256 daiReserves = dai.BALANCEOF833(address(pool));
        uint256 fyDaiReserves = fyDai.BALANCEOF833(address(pool));
        uint256 daiToAdd = daiUsed.MUL434(daiReserves).DIV16(fyDaiReserves.ADD958(daiReserves));
        uint256 daiToConvert = daiUsed.SUB494(daiToAdd);
        require(
            daiToConvert <= maxFYDai,
            "YieldProxy: maxFYDai exceeded"
        );


        chai.JOIN369(address(this), daiToConvert);

        uint256 toBorrow = chai.DAI858(address(this));
        controller.POST95(chai69, address(this), msg.sender, chai.BALANCEOF833(address(this)));
        controller.BORROW691(chai69, fyDai.MATURITY388(), msg.sender, address(this), toBorrow);


        return pool.MINT176(address(this), msg.sender, daiToAdd);
    }







    function REMOVELIQUIDITYEARLYDAIPOOL932(IPool pool, uint256 poolTokens, uint256 minimumDaiPrice, uint256 minimumFYDaiPrice) external {
        ONLYKNOWNPOOL167(pool);
        IFYDai fyDai = pool.FYDAI600();
        uint256 maturity = fyDai.MATURITY388();
        (uint256 daiObtained, uint256 fyDaiObtained) = pool.BURN250(msg.sender, address(this), poolTokens);


        uint256 fyDaiBought = pool.SELLDAI400(address(this), address(this), daiObtained.TOUINT128897());
        require(
            fyDaiBought >= MULD379(daiObtained, minimumDaiPrice),
            "YieldProxy: minimumDaiPrice not reached"
        );
        fyDaiObtained = fyDaiObtained.ADD958(fyDaiBought);

        uint256 fyDaiUsed;
        if (fyDaiObtained > 0 && controller.DEBTFYDAI447(chai69, maturity, msg.sender) > 0) {
            fyDaiUsed = controller.REPAYFYDAI426(chai69, maturity, address(this), msg.sender, fyDaiObtained);
        }
        uint256 fyDaiRemaining = fyDaiObtained.SUB494(fyDaiUsed);

        if (fyDaiRemaining > 0) {
            require(
                pool.SELLFYDAI226(address(this), address(this), uint128(fyDaiRemaining)) >= MULD379(fyDaiRemaining, minimumFYDaiPrice),
                "YieldProxy: minimumFYDaiPrice not reached"
            );
        }
        WITHDRAWASSETS926(fyDai);
    }






    function REMOVELIQUIDITYEARLYDAIFIXED8(IPool pool, uint256 poolTokens, uint256 minimumFYDaiPrice) external {
        ONLYKNOWNPOOL167(pool);
        IFYDai fyDai = pool.FYDAI600();
        uint256 maturity = fyDai.MATURITY388();
        (uint256 daiObtained, uint256 fyDaiObtained) = pool.BURN250(msg.sender, address(this), poolTokens);

        uint256 fyDaiUsed;
        if (fyDaiObtained > 0 && controller.DEBTFYDAI447(chai69, maturity, msg.sender) > 0) {
            fyDaiUsed = controller.REPAYFYDAI426(chai69, maturity, address(this), msg.sender, fyDaiObtained);
        }

        uint256 fyDaiRemaining = fyDaiObtained.SUB494(fyDaiUsed);
        if (fyDaiRemaining == 0) {
            if (daiObtained > 0 && controller.DEBTFYDAI447(chai69, maturity, msg.sender) > 0) {
                controller.REPAYDAI460(chai69, maturity, address(this), msg.sender, daiObtained);
            }
        } else {
            require(
                pool.SELLFYDAI226(address(this), address(this), uint128(fyDaiRemaining)) >= MULD379(fyDaiRemaining, minimumFYDaiPrice),
                "YieldProxy: minimumFYDaiPrice not reached"
            );
        }
        WITHDRAWASSETS926(fyDai);
    }





    function REMOVELIQUIDITYMATURE267(IPool pool, uint256 poolTokens) external {
        ONLYKNOWNPOOL167(pool);
        IFYDai fyDai = pool.FYDAI600();
        uint256 maturity = fyDai.MATURITY388();
        (uint256 daiObtained, uint256 fyDaiObtained) = pool.BURN250(msg.sender, address(this), poolTokens);
        if (fyDaiObtained > 0) {
            daiObtained = daiObtained.ADD958(fyDai.REDEEM906(address(this), address(this), fyDaiObtained));
        }


        if (daiObtained > 0 && controller.DEBTFYDAI447(chai69, maturity, msg.sender) > 0) {
            controller.REPAYDAI460(chai69, maturity, address(this), msg.sender, daiObtained);
        }
        WITHDRAWASSETS926(fyDai);
    }


    function WITHDRAWASSETS926(IFYDai fyDai) internal {
        if (controller.DEBTFYDAI447(chai69, fyDai.MATURITY388(), msg.sender) == 0) {
            controller.WITHDRAW817(chai69, msg.sender, address(this), controller.POSTED950(chai69, msg.sender));
            chai.EXIT932(address(this), chai.BALANCEOF833(address(this)));
        }
        require(dai.TRANSFER582(msg.sender, dai.BALANCEOF833(address(this))), "YieldProxy: Dai Transfer Failed");
    }








    function BORROWDAIFORMAXIMUMFYDAI736(
        IPool pool,
        bytes32 collateral,
        uint256 maturity,
        address to,
        uint256 maximumFYDai,
        uint256 daiToBorrow
    )
        public
        returns (uint256)
    {
        ONLYKNOWNPOOL167(pool);
        uint256 fyDaiToBorrow = pool.BUYDAIPREVIEW913(daiToBorrow.TOUINT128897());
        require (fyDaiToBorrow <= maximumFYDai, "YieldProxy: Too much fyDai required");


        controller.BORROW691(collateral, maturity, msg.sender, address(this), fyDaiToBorrow);
        pool.BUYDAI253(address(this), to, daiToBorrow.TOUINT128897());

        return fyDaiToBorrow;
    }








    function BORROWMINIMUMDAIFORFYDAI776(
        IPool pool,
        bytes32 collateral,
        uint256 maturity,
        address to,
        uint256 fyDaiToBorrow,
        uint256 minimumDaiToBorrow
    )
        public
        returns (uint256)
    {
        ONLYKNOWNPOOL167(pool);

        controller.BORROW691(collateral, maturity, msg.sender, address(this), fyDaiToBorrow);
        uint256 boughtDai = pool.SELLFYDAI226(address(this), to, fyDaiToBorrow.TOUINT128897());
        require (boughtDai >= minimumDaiToBorrow, "YieldProxy: Not enough Dai obtained");

        return boughtDai;
    }









    function REPAYFYDAIDEBTFORMAXIMUMDAI955(
        IPool pool,
        bytes32 collateral,
        uint256 maturity,
        address to,
        uint256 fyDaiRepayment,
        uint256 maximumRepaymentInDai
    )
        public
        returns (uint256)
    {
        ONLYKNOWNPOOL167(pool);
        uint256 fyDaiDebt = controller.DEBTFYDAI447(collateral, maturity, to);
        uint256 fyDaiToUse = fyDaiDebt < fyDaiRepayment ? fyDaiDebt : fyDaiRepayment;
        uint256 repaymentInDai = pool.BUYFYDAI675(msg.sender, address(this), fyDaiToUse.TOUINT128897());
        require (repaymentInDai <= maximumRepaymentInDai, "YieldProxy: Too much Dai required");
        controller.REPAYFYDAI426(collateral, maturity, address(this), to, fyDaiToUse);

        return repaymentInDai;
    }









    function REPAYMINIMUMFYDAIDEBTFORDAI862(
        IPool pool,
        bytes32 collateral,
        uint256 maturity,
        address to,
        uint256 minimumFYDaiRepayment,
        uint256 repaymentInDai
    )
        public
        returns (uint256)
    {
        ONLYKNOWNPOOL167(pool);
        uint256 fyDaiRepayment = pool.SELLDAIPREVIEW300(repaymentInDai.TOUINT128897());
        uint256 fyDaiDebt = controller.DEBTFYDAI447(collateral, maturity, to);
        if(fyDaiRepayment <= fyDaiDebt) {
            pool.SELLDAI400(msg.sender, address(this), repaymentInDai.TOUINT128897());
        } else {
            pool.BUYFYDAI675(msg.sender, address(this), fyDaiDebt.TOUINT128897());
            fyDaiRepayment = fyDaiDebt;
        }
        require (fyDaiRepayment >= minimumFYDaiRepayment, "YieldProxy: Not enough fyDai debt repaid");
        controller.REPAYFYDAI426(collateral, maturity, address(this), to, fyDaiRepayment);

        return fyDaiRepayment;
    }





    function SELLDAI400(IPool pool, address to, uint128 daiIn, uint128 minFYDaiOut)
        external
        returns(uint256)
    {
        ONLYKNOWNPOOL167(pool);
        uint256 fyDaiOut = pool.SELLDAI400(msg.sender, to, daiIn);
        require(
            fyDaiOut >= minFYDaiOut,
            "YieldProxy: Limit not reached"
        );
        return fyDaiOut;
    }





    function BUYDAI253(IPool pool, address to, uint128 daiOut, uint128 maxFYDaiIn)
        public
        returns(uint256)
    {
        ONLYKNOWNPOOL167(pool);
        uint256 fyDaiIn = pool.BUYDAI253(msg.sender, to, daiOut);
        require(
            maxFYDaiIn >= fyDaiIn,
            "YieldProxy: Limit exceeded"
        );
        return fyDaiIn;
    }






    function BUYDAIWITHSIGNATURE110(IPool pool, address to, uint128 daiOut, uint128 maxFYDaiIn, bytes memory signature)
        external
        returns(uint256)
    {
        ONLYKNOWNPOOL167(pool);
        (bytes32 r, bytes32 s, uint8 v) = UNPACK384(signature);
        pool.FYDAI600().PERMIT233(msg.sender, address(pool), uint(-1), uint(-1), v, r, s);

        return BUYDAI253(pool, to, daiOut, maxFYDaiIn);
    }





    function SELLFYDAI226(IPool pool, address to, uint128 fyDaiIn, uint128 minDaiOut)
        public
        returns(uint256)
    {
        ONLYKNOWNPOOL167(pool);
        uint256 daiOut = pool.SELLFYDAI226(msg.sender, to, fyDaiIn);
        require(
            daiOut >= minDaiOut,
            "YieldProxy: Limit not reached"
        );
        return daiOut;
    }






    function SELLFYDAIWITHSIGNATURE545(IPool pool, address to, uint128 fyDaiIn, uint128 minDaiOut, bytes memory signature)
        external
        returns(uint256)
    {
        ONLYKNOWNPOOL167(pool);
        (bytes32 r, bytes32 s, uint8 v) = UNPACK384(signature);
        pool.FYDAI600().PERMIT233(msg.sender, address(pool), uint(-1), uint(-1), v, r, s);

        return SELLFYDAI226(pool, to, fyDaiIn, minDaiOut);
    }





    function BUYFYDAI675(IPool pool, address to, uint128 fyDaiOut, uint128 maxDaiIn)
        external
        returns(uint256)
    {
        ONLYKNOWNPOOL167(pool);
        uint256 daiIn = pool.BUYFYDAI675(msg.sender, to, fyDaiOut);
        require(
            maxDaiIn >= daiIn,
            "YieldProxy: Limit exceeded"
        );
        return daiIn;
    }










    function REPAYDAIWITHSIGNATURE818(bytes32 collateral, uint256 maturity, address to, uint256 daiAmount, bytes memory signature)
        external
        returns(uint256)
    {
        (bytes32 r, bytes32 s, uint8 v) = UNPACK384(signature);
        dai.PERMIT233(msg.sender, address(treasury), dai.NONCES538(msg.sender), uint(-1), true, v, r, s);
        controller.REPAYDAI460(collateral, maturity, msg.sender, to, daiAmount);
    }

    function ONLYKNOWNPOOL167(IPool pool) private view {
        require(poolsMap[address(pool)], "YieldProxy: Unknown pool");
    }
}
