

pragma solidity 0.6.0;


contract Nest_NToken_OfferMain {

    using SafeMath for uint256;
    using address_make_payable for address;
    using SafeERC20 for ERC20;


    struct Nest_NToken_OfferPriceData {

        address owner;
        bool deviate;
        address tokenAddress;

        uint256 ethAmount;
        uint256 tokenAmount;

        uint256 dealEthAmount;
        uint256 dealTokenAmount;

        uint256 blockNum;
        uint256 serviceCharge;

    }

    Nest_NToken_OfferPriceData [] _prices;
    Nest_3_VoteFactory _voteFactory;
    Nest_3_OfferPrice _offerPrice;
    Nest_NToken_TokenMapping _tokenMapping;
    ERC20 _nestToken;
    Nest_3_Abonus _abonus;
    uint256 _miningETH = 10;
    uint256 _tranEth = 1;
    uint256 _tranAddition = 2;
    uint256 _leastEth = 10 ether;
    uint256 _offerSpan = 10 ether;
    uint256 _deviate = 10;
    uint256 _deviationFromScale = 10;
    uint256 _ownerMining = 5;
    uint256 _afterMiningAmount = 0.4 ether;
    uint32 _blockLimit = 25;

    uint256 _blockAttenuation = 2400000;
    mapping(uint256 => mapping(address => uint256)) _blockOfferAmount;
    mapping(uint256 => mapping(address => uint256)) _blockMining;
    uint256[10] _attenuationAmount;


    event OFFERTOKENCONTRACTADDRESS732(address contractAddress);

    event OFFERCONTRACTADDRESS317(address contractAddress, address tokenAddress, uint256 ethAmount, uint256 erc20Amount, uint256 continued,uint256 mining);

    event OFFERTRAN368(address tranSender, address tranToken, uint256 tranAmount,address otherToken, uint256 otherAmount, address tradedContract, address tradedOwner);

    event OREDRAWINGLOG324(uint256 nowBlock, uint256 blockAmount, address tokenAddress);

    event MININGLOG206(uint256 blockNum, address tokenAddress, uint256 offerTimes);


    constructor (address voteFactory) public {
        Nest_3_VoteFactory voteFactoryMap = Nest_3_VoteFactory(address(voteFactory));
        _voteFactory = voteFactoryMap;
        _offerPrice = Nest_3_OfferPrice(address(voteFactoryMap.CHECKADDRESS430("nest.v3.offerPrice")));
        _nestToken = ERC20(voteFactoryMap.CHECKADDRESS430("nest"));
        _abonus = Nest_3_Abonus(voteFactoryMap.CHECKADDRESS430("nest.v3.abonus"));
        _tokenMapping = Nest_NToken_TokenMapping(address(voteFactoryMap.CHECKADDRESS430("nest.nToken.tokenMapping")));

        uint256 blockAmount = 4 ether;
        for (uint256 i = 0; i < 10; i ++) {
            _attenuationAmount[i] = blockAmount;
            blockAmount = blockAmount.MUL982(8).DIV757(10);
        }
    }


    function CHANGEMAPPING259(address voteFactory) public ONLYOWNER202 {
        Nest_3_VoteFactory voteFactoryMap = Nest_3_VoteFactory(address(voteFactory));
        _voteFactory = voteFactoryMap;
        _offerPrice = Nest_3_OfferPrice(address(voteFactoryMap.CHECKADDRESS430("nest.v3.offerPrice")));
        _nestToken = ERC20(voteFactoryMap.CHECKADDRESS430("nest"));
        _abonus = Nest_3_Abonus(voteFactoryMap.CHECKADDRESS430("nest.v3.abonus"));
        _tokenMapping = Nest_NToken_TokenMapping(address(voteFactoryMap.CHECKADDRESS430("nest.nToken.tokenMapping")));
    }


    function OFFER735(uint256 ethAmount, uint256 erc20Amount, address erc20Address) public payable {
        require(address(msg.sender) == address(tx.origin), "It can't be a contract");
        address nTokenAddress = _tokenMapping.CHECKTOKENMAPPING799(erc20Address);
        require(nTokenAddress != address(0x0));

        uint256 ethMining;
        bool isDeviate = COMPARATIVEPRICE616(ethAmount,erc20Amount,erc20Address);
        if (isDeviate) {
            require(ethAmount >= _leastEth.MUL982(_deviationFromScale), "EthAmount needs to be no less than 10 times of the minimum scale");
            ethMining = _leastEth.MUL982(_miningETH).DIV757(1000);
        } else {
            ethMining = ethAmount.MUL982(_miningETH).DIV757(1000);
        }
        require(msg.value >= ethAmount.ADD379(ethMining), "msg.value needs to be equal to the quoted eth quantity plus Mining handling fee");
        uint256 subValue = msg.value.SUB918(ethAmount.ADD379(ethMining));
        if (subValue > 0) {
            REPAYETH964(address(msg.sender), subValue);
        }

        CREATEOFFER725(ethAmount, erc20Amount, erc20Address,isDeviate, ethMining);

        ERC20(erc20Address).SAFETRANSFERFROM181(address(msg.sender), address(this), erc20Amount);
        _abonus.SWITCHTOETHFORNTOKENOFFER869.value(ethMining)(nTokenAddress);

        if (_blockOfferAmount[block.number][erc20Address] == 0) {
            uint256 miningAmount = OREDRAWING657(nTokenAddress);
            Nest_NToken nToken = Nest_NToken(nTokenAddress);
            nToken.TRANSFER16(nToken.CHECKBIDDER306(), miningAmount.MUL982(_ownerMining).DIV757(100));
            _blockMining[block.number][erc20Address] = miningAmount.SUB918(miningAmount.MUL982(_ownerMining).DIV757(100));
        }
        _blockOfferAmount[block.number][erc20Address] = _blockOfferAmount[block.number][erc20Address].ADD379(ethMining);
    }


    function CREATEOFFER725(uint256 ethAmount, uint256 erc20Amount, address erc20Address, bool isDeviate, uint256 mining) private {

        require(ethAmount >= _leastEth, "Eth scale is smaller than the minimum scale");
        require(ethAmount % _offerSpan == 0, "Non compliant asset span");
        require(erc20Amount % (ethAmount.DIV757(_offerSpan)) == 0, "Asset quantity is not divided");
        require(erc20Amount > 0);

        emit OFFERCONTRACTADDRESS317(TOADDRESS719(_prices.length), address(erc20Address), ethAmount, erc20Amount,_blockLimit,mining);
        _prices.push(Nest_NToken_OfferPriceData(
            msg.sender,
            isDeviate,
            erc20Address,

            ethAmount,
            erc20Amount,

            ethAmount,
            erc20Amount,

            block.number,
            mining
        ));

        _offerPrice.ADDPRICE894(ethAmount, erc20Amount, block.number.ADD379(_blockLimit), erc20Address, address(msg.sender));
    }


    function TOINDEX783(address contractAddress) public pure returns(uint256) {
        return uint256(contractAddress);
    }


    function TOADDRESS719(uint256 index) public pure returns(address) {
        return address(index);
    }


    function TURNOUT418(address contractAddress) public {
        require(address(msg.sender) == address(tx.origin), "It can't be a contract");
        uint256 index = TOINDEX783(contractAddress);
        Nest_NToken_OfferPriceData storage offerPriceData = _prices[index];
        require(CHECKCONTRACTSTATE995(offerPriceData.blockNum) == 1, "Offer status error");

        if (offerPriceData.ethAmount > 0) {
            uint256 payEth = offerPriceData.ethAmount;
            offerPriceData.ethAmount = 0;
            REPAYETH964(offerPriceData.owner, payEth);
        }

        if (offerPriceData.tokenAmount > 0) {
            uint256 payErc = offerPriceData.tokenAmount;
            offerPriceData.tokenAmount = 0;
            ERC20(address(offerPriceData.tokenAddress)).TRANSFER16(offerPriceData.owner, payErc);

        }

        if (offerPriceData.serviceCharge > 0) {
            MINING254(offerPriceData.blockNum, offerPriceData.tokenAddress, offerPriceData.serviceCharge, offerPriceData.owner);
            offerPriceData.serviceCharge = 0;
        }
    }


    function SENDETHBUYERC123(uint256 ethAmount, uint256 tokenAmount, address contractAddress, uint256 tranEthAmount, uint256 tranTokenAmount, address tranTokenAddress) public payable {
        require(address(msg.sender) == address(tx.origin), "It can't be a contract");
        uint256 serviceCharge = tranEthAmount.MUL982(_tranEth).DIV757(1000);
        require(msg.value == ethAmount.ADD379(tranEthAmount).ADD379(serviceCharge), "msg.value needs to be equal to the quotation eth quantity plus transaction eth plus");
        require(tranEthAmount % _offerSpan == 0, "Transaction size does not meet asset span");


        uint256 index = TOINDEX783(contractAddress);
        Nest_NToken_OfferPriceData memory offerPriceData = _prices[index];

        bool thisDeviate = COMPARATIVEPRICE616(ethAmount,tokenAmount,tranTokenAddress);
        bool isDeviate;
        if (offerPriceData.deviate == true) {
            isDeviate = true;
        } else {
            isDeviate = thisDeviate;
        }

        if (offerPriceData.deviate) {

            require(ethAmount >= tranEthAmount.MUL982(_tranAddition), "EthAmount needs to be no less than 2 times of transaction scale");
        } else {
            if (isDeviate) {

                require(ethAmount >= tranEthAmount.MUL982(_deviationFromScale), "EthAmount needs to be no less than 10 times of transaction scale");
            } else {

                require(ethAmount >= tranEthAmount.MUL982(_tranAddition), "EthAmount needs to be no less than 2 times of transaction scale");
            }
        }


        require(CHECKCONTRACTSTATE995(offerPriceData.blockNum) == 0, "Offer status error");
        require(offerPriceData.dealEthAmount >= tranEthAmount, "Insufficient trading eth");
        require(offerPriceData.dealTokenAmount >= tranTokenAmount, "Insufficient trading token");
        require(offerPriceData.tokenAddress == tranTokenAddress, "Wrong token address");
        require(tranTokenAmount == offerPriceData.dealTokenAmount * tranEthAmount / offerPriceData.dealEthAmount, "Wrong token amount");


        offerPriceData.ethAmount = offerPriceData.ethAmount.ADD379(tranEthAmount);
        offerPriceData.tokenAmount = offerPriceData.tokenAmount.SUB918(tranTokenAmount);
        offerPriceData.dealEthAmount = offerPriceData.dealEthAmount.SUB918(tranEthAmount);
        offerPriceData.dealTokenAmount = offerPriceData.dealTokenAmount.SUB918(tranTokenAmount);
        _prices[index] = offerPriceData;

        CREATEOFFER725(ethAmount, tokenAmount, tranTokenAddress, isDeviate, 0);

        if (tokenAmount > tranTokenAmount) {
            ERC20(tranTokenAddress).SAFETRANSFERFROM181(address(msg.sender), address(this), tokenAmount.SUB918(tranTokenAmount));
        } else {
            ERC20(tranTokenAddress).SAFETRANSFER797(address(msg.sender), tranTokenAmount.SUB918(tokenAmount));
        }


        _offerPrice.CHANGEPRICE820(tranEthAmount, tranTokenAmount, tranTokenAddress, offerPriceData.blockNum.ADD379(_blockLimit));
        emit OFFERTRAN368(address(msg.sender), address(0x0), tranEthAmount, address(tranTokenAddress), tranTokenAmount, contractAddress, offerPriceData.owner);


        if (serviceCharge > 0) {
            address nTokenAddress = _tokenMapping.CHECKTOKENMAPPING799(tranTokenAddress);
            _abonus.SWITCHTOETH95.value(serviceCharge)(nTokenAddress);
        }
    }


    function SENDERCBUYETH398(uint256 ethAmount, uint256 tokenAmount, address contractAddress, uint256 tranEthAmount, uint256 tranTokenAmount, address tranTokenAddress) public payable {
        require(address(msg.sender) == address(tx.origin), "It can't be a contract");
        uint256 serviceCharge = tranEthAmount.MUL982(_tranEth).DIV757(1000);
        require(msg.value == ethAmount.SUB918(tranEthAmount).ADD379(serviceCharge), "msg.value needs to be equal to the quoted eth quantity plus transaction handling fee");
        require(tranEthAmount % _offerSpan == 0, "Transaction size does not meet asset span");

        uint256 index = TOINDEX783(contractAddress);
        Nest_NToken_OfferPriceData memory offerPriceData = _prices[index];

        bool thisDeviate = COMPARATIVEPRICE616(ethAmount,tokenAmount,tranTokenAddress);
        bool isDeviate;
        if (offerPriceData.deviate == true) {
            isDeviate = true;
        } else {
            isDeviate = thisDeviate;
        }

        if (offerPriceData.deviate) {

            require(ethAmount >= tranEthAmount.MUL982(_tranAddition), "EthAmount needs to be no less than 2 times of transaction scale");
        } else {
            if (isDeviate) {

                require(ethAmount >= tranEthAmount.MUL982(_deviationFromScale), "EthAmount needs to be no less than 10 times of transaction scale");
            } else {

                require(ethAmount >= tranEthAmount.MUL982(_tranAddition), "EthAmount needs to be no less than 2 times of transaction scale");
            }
        }

        require(CHECKCONTRACTSTATE995(offerPriceData.blockNum) == 0, "Offer status error");
        require(offerPriceData.dealEthAmount >= tranEthAmount, "Insufficient trading eth");
        require(offerPriceData.dealTokenAmount >= tranTokenAmount, "Insufficient trading token");
        require(offerPriceData.tokenAddress == tranTokenAddress, "Wrong token address");
        require(tranTokenAmount == offerPriceData.dealTokenAmount * tranEthAmount / offerPriceData.dealEthAmount, "Wrong token amount");

        offerPriceData.ethAmount = offerPriceData.ethAmount.SUB918(tranEthAmount);
        offerPriceData.tokenAmount = offerPriceData.tokenAmount.ADD379(tranTokenAmount);
        offerPriceData.dealEthAmount = offerPriceData.dealEthAmount.SUB918(tranEthAmount);
        offerPriceData.dealTokenAmount = offerPriceData.dealTokenAmount.SUB918(tranTokenAmount);
        _prices[index] = offerPriceData;

        CREATEOFFER725(ethAmount, tokenAmount, tranTokenAddress, isDeviate, 0);

        ERC20(tranTokenAddress).SAFETRANSFERFROM181(address(msg.sender), address(this), tranTokenAmount.ADD379(tokenAmount));

        _offerPrice.CHANGEPRICE820(tranEthAmount, tranTokenAmount, tranTokenAddress, offerPriceData.blockNum.ADD379(_blockLimit));
        emit OFFERTRAN368(address(msg.sender), address(tranTokenAddress), tranTokenAmount, address(0x0), tranEthAmount, contractAddress, offerPriceData.owner);

        if (serviceCharge > 0) {
            address nTokenAddress = _tokenMapping.CHECKTOKENMAPPING799(tranTokenAddress);
            _abonus.SWITCHTOETH95.value(serviceCharge)(nTokenAddress);
        }
    }


    function OREDRAWING657(address ntoken) private returns(uint256) {
        Nest_NToken miningToken = Nest_NToken(ntoken);
        (uint256 createBlock, uint256 recentlyUsedBlock) = miningToken.CHECKBLOCKINFO350();
        uint256 attenuationPointNow = block.number.SUB918(createBlock).DIV757(_blockAttenuation);
        uint256 miningAmount = 0;
        uint256 attenuation;
        if (attenuationPointNow > 9) {
            attenuation = _afterMiningAmount;
        } else {
            attenuation = _attenuationAmount[attenuationPointNow];
        }
        miningAmount = attenuation.MUL982(block.number.SUB918(recentlyUsedBlock));
        miningToken.INCREASETOTAL78(miningAmount);
        emit OREDRAWINGLOG324(block.number, miningAmount, ntoken);
        return miningAmount;
    }


    function MINING254(uint256 blockNum, address token, uint256 serviceCharge, address owner) private returns(uint256) {

        uint256 miningAmount = _blockMining[blockNum][token].MUL982(serviceCharge).DIV757(_blockOfferAmount[blockNum][token]);

        Nest_NToken nToken = Nest_NToken(address(_tokenMapping.CHECKTOKENMAPPING799(token)));
        require(nToken.TRANSFER16(address(owner), miningAmount), "Transfer failure");

        emit MININGLOG206(blockNum, token,_blockOfferAmount[blockNum][token]);
        return miningAmount;
    }


    function COMPARATIVEPRICE616(uint256 myEthValue, uint256 myTokenValue, address token) private view returns(bool) {
        (uint256 frontEthValue, uint256 frontTokenValue) = _offerPrice.UPDATEANDCHECKPRICEPRIVATE349(token);
        if (frontEthValue == 0 || frontTokenValue == 0) {
            return false;
        }
        uint256 maxTokenAmount = myEthValue.MUL982(frontTokenValue).MUL982(uint256(100).ADD379(_deviate)).DIV757(frontEthValue.MUL982(100));
        if (myTokenValue <= maxTokenAmount) {
            uint256 minTokenAmount = myEthValue.MUL982(frontTokenValue).MUL982(uint256(100).SUB918(_deviate)).DIV757(frontEthValue.MUL982(100));
            if (myTokenValue >= minTokenAmount) {
                return false;
            }
        }
        return true;
    }


    function CHECKCONTRACTSTATE995(uint256 createBlock) public view returns (uint256) {
        if (block.number.SUB918(createBlock) > _blockLimit) {
            return 1;
        }
        return 0;
    }


    function REPAYETH964(address accountAddress, uint256 asset) private {
        address payable addr = accountAddress.MAKE_PAYABLE861();
        addr.transfer(asset);
    }


    function CHECKBLOCKLIMIT652() public view returns(uint256) {
        return _blockLimit;
    }


    function CHECKTRANETH271() public view returns (uint256) {
        return _tranEth;
    }


    function CHECKTRANADDITION123() public view returns(uint256) {
        return _tranAddition;
    }


    function CHECKLEASTETH415() public view returns(uint256) {
        return _leastEth;
    }


    function CHECKOFFERSPAN954() public view returns(uint256) {
        return _offerSpan;
    }


    function CHECKBLOCKOFFERAMOUNT357(uint256 blockNum, address token) public view returns (uint256) {
        return _blockOfferAmount[blockNum][token];
    }


    function CHECKBLOCKMINING594(uint256 blockNum, address token) public view returns (uint256) {
        return _blockMining[blockNum][token];
    }


    function CHECKOFFERMINING245(uint256 blockNum, address token, uint256 serviceCharge) public view returns (uint256) {
        if (serviceCharge == 0) {
            return 0;
        } else {
            return _blockMining[blockNum][token].MUL982(serviceCharge).DIV757(_blockOfferAmount[blockNum][token]);
        }
    }


    function CHECKOWNERMINING462() public view returns(uint256) {
        return _ownerMining;
    }


    function CHECKATTENUATIONAMOUNT848(uint256 num) public view returns(uint256) {
        return _attenuationAmount[num];
    }


    function CHANGETRANETH866(uint256 num) public ONLYOWNER202 {
        _tranEth = num;
    }


    function CHANGEBLOCKLIMIT22(uint32 num) public ONLYOWNER202 {
        _blockLimit = num;
    }


    function CHANGETRANADDITION884(uint256 num) public ONLYOWNER202 {
        require(num > 0, "Parameter needs to be greater than 0");
        _tranAddition = num;
    }


    function CHANGELEASTETH405(uint256 num) public ONLYOWNER202 {
        require(num > 0, "Parameter needs to be greater than 0");
        _leastEth = num;
    }


    function CHANGEOFFERSPAN492(uint256 num) public ONLYOWNER202 {
        require(num > 0, "Parameter needs to be greater than 0");
        _offerSpan = num;
    }


    function CHANGEKDEVIATE724(uint256 num) public ONLYOWNER202 {
        _deviate = num;
    }


    function CHANGEDEVIATIONFROMSCALE300(uint256 num) public ONLYOWNER202 {
        _deviationFromScale = num;
    }


    function CHANGEOWNERMINING351(uint256 num) public ONLYOWNER202 {
        _ownerMining = num;
    }


    function CHANGEATTENUATIONAMOUNT1(uint256 firstAmount, uint256 top, uint256 bottom) public ONLYOWNER202 {
        uint256 blockAmount = firstAmount;
        for (uint256 i = 0; i < 10; i ++) {
            _attenuationAmount[i] = blockAmount;
            blockAmount = blockAmount.MUL982(top).DIV757(bottom);
        }
    }


    modifier ONLYOWNER202(){
        require(_voteFactory.CHECKOWNERS558(msg.sender), "No authority");
        _;
    }


    function GETPRICECOUNT52() view public returns (uint256) {
        return _prices.length;
    }


    function GETPRICE258(uint256 priceIndex) view public returns (string memory) {

        bytes memory buf = new bytes(500000);
        uint256 index = 0;
        index = WRITEOFFERPRICEDATA490(priceIndex, _prices[priceIndex], buf, index);

        bytes memory str = new bytes(index);
        while(index-- > 0) {
            str[index] = buf[index];
        }
        return string(str);
    }


    function FIND608(address start, uint256 count, uint256 maxFindCount, address owner) view public returns (string memory) {

        bytes memory buf = new bytes(500000);
        uint256 index = 0;

        uint256 i = _prices.length;
        uint256 end = 0;
        if (start != address(0)) {
            i = TOINDEX783(start);
        }
        if (i > maxFindCount) {
            end = i - maxFindCount;
        }

        while (count > 0 && i-- > end) {
            Nest_NToken_OfferPriceData memory price = _prices[i];
            if (price.owner == owner) {
                --count;
                index = WRITEOFFERPRICEDATA490(i, price, buf, index);
            }
        }

        bytes memory str = new bytes(index);
        while(index-- > 0) {
            str[index] = buf[index];
        }
        return string(str);
    }


    function LIST901(uint256 offset, uint256 count, uint256 order) view public returns (string memory) {


        bytes memory buf = new bytes(500000);
        uint256 index = 0;


        uint256 i = 0;
        uint256 end = 0;

        if (order == 0) {


            if (offset < _prices.length) {
                i = _prices.length - offset;
            }
            if (count < i) {
                end = i - count;
            }


            while (i-- > end) {
                index = WRITEOFFERPRICEDATA490(i, _prices[i], buf, index);
            }
        } else {


            if (offset < _prices.length) {
                i = offset;
            } else {
                i = _prices.length;
            }
            end = i + count;
            if(end > _prices.length) {
                end = _prices.length;
            }


            while (i < end) {
                index = WRITEOFFERPRICEDATA490(i, _prices[i], buf, index);
                ++i;
            }
        }


        bytes memory str = new bytes(index);
        while(index-- > 0) {
            str[index] = buf[index];
        }
        return string(str);
    }


    function WRITEOFFERPRICEDATA490(uint256 priceIndex, Nest_NToken_OfferPriceData memory price, bytes memory buf, uint256 index) pure private returns (uint256) {

        index = WRITEADDRESS338(TOADDRESS719(priceIndex), buf, index);
        buf[index++] = byte(uint8(44));

        index = WRITEADDRESS338(price.owner, buf, index);
        buf[index++] = byte(uint8(44));

        index = WRITEADDRESS338(price.tokenAddress, buf, index);
        buf[index++] = byte(uint8(44));

        index = WRITEUINT859(price.ethAmount, buf, index);
        buf[index++] = byte(uint8(44));

        index = WRITEUINT859(price.tokenAmount, buf, index);
        buf[index++] = byte(uint8(44));

        index = WRITEUINT859(price.dealEthAmount, buf, index);
        buf[index++] = byte(uint8(44));

        index = WRITEUINT859(price.dealTokenAmount, buf, index);
        buf[index++] = byte(uint8(44));

        index = WRITEUINT859(price.blockNum, buf, index);
        buf[index++] = byte(uint8(44));

        index = WRITEUINT859(price.serviceCharge, buf, index);
        buf[index++] = byte(uint8(44));

        return index;
    }


    function WRITEUINT859(uint256 iv, bytes memory buf, uint256 index) pure public returns (uint256) {
        uint256 i = index;
        do {
            buf[index++] = byte(uint8(iv % 10 +48));
            iv /= 10;
        } while (iv > 0);

        for (uint256 j = index; j > i; ++i) {
            byte t = buf[i];
            buf[i] = buf[--j];
            buf[j] = t;
        }

        return index;
    }


    function WRITEADDRESS338(address addr, bytes memory buf, uint256 index) pure private returns (uint256) {

        uint256 iv = uint256(addr);
        uint256 i = index + 40;
        do {
            uint256 w = iv % 16;
            if(w < 10) {
                buf[index++] = byte(uint8(w +48));
            } else {
                buf[index++] = byte(uint8(w +87));
            }

            iv /= 16;
        } while (index < i);

        i -= 40;
        for (uint256 j = index; j > i; ++i) {
            byte t = buf[i];
            buf[i] = buf[--j];
            buf[j] = t;
        }

        return index;
    }
}


interface Nest_3_OfferPrice {

    function ADDPRICE894(uint256 ethAmount, uint256 tokenAmount, uint256 endBlock, address tokenAddress, address offerOwner) external;

    function CHANGEPRICE820(uint256 ethAmount, uint256 tokenAmount, address tokenAddress, uint256 endBlock) external;
    function UPDATEANDCHECKPRICEPRIVATE349(address tokenAddress) external view returns(uint256 ethAmount, uint256 erc20Amount);
}


interface Nest_3_VoteFactory {

	function CHECKADDRESS430(string calldata name) external view returns (address contractAddress);

	function CHECKOWNERS558(address man) external view returns (bool);
}


interface Nest_NToken {

    function INCREASETOTAL78(uint256 value) external;

    function CHECKBLOCKINFO350() external view returns(uint256 createBlock, uint256 recentlyUsedBlock);

    function CHECKBIDDER306() external view returns(address);
    function TOTALSUPPLY249() external view returns (uint256);
    function BALANCEOF133(address account) external view returns (uint256);
    function TRANSFER16(address recipient, uint256 amount) external returns (bool);
    function ALLOWANCE798(address owner, address spender) external view returns (uint256);
    function APPROVE147(address spender, uint256 amount) external returns (bool);
    function TRANSFERFROM462(address sender, address recipient, uint256 amount) external returns (bool);
    event TRANSFER56(address indexed from, address indexed to, uint256 value);
    event APPROVAL26(address indexed owner, address indexed spender, uint256 value);
}


interface Nest_NToken_TokenMapping {

    function CHECKTOKENMAPPING799(address token) external view returns (address);
}


interface Nest_3_Abonus {
    function SWITCHTOETH95(address token) external payable;
    function SWITCHTOETHFORNTOKENOFFER869(address token) external payable;
}

library SafeMath {
    function ADD379(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function SUB918(uint256 a, uint256 b) internal pure returns (uint256) {
        return SUB918(a, b, "SafeMath: subtraction overflow");
    }
    function SUB918(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function MUL982(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function DIV757(uint256 a, uint256 b) internal pure returns (uint256) {
        return DIV757(a, b, "SafeMath: division by zero");
    }
    function DIV757(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    function MOD863(uint256 a, uint256 b) internal pure returns (uint256) {
        return MOD863(a, b, "SafeMath: modulo by zero");
    }
    function MOD863(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library address_make_payable {
   function MAKE_PAYABLE861(address x) internal pure returns (address payable) {
      return address(uint160(x));
   }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function SAFETRANSFER797(ERC20 token, address to, uint256 value) internal {
        CALLOPTIONALRETURN10(token, abi.encodeWithSelector(token.TRANSFER16.selector, to, value));
    }

    function SAFETRANSFERFROM181(ERC20 token, address from, address to, uint256 value) internal {
        CALLOPTIONALRETURN10(token, abi.encodeWithSelector(token.TRANSFERFROM462.selector, from, to, value));
    }

    function SAFEAPPROVE632(ERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.ALLOWANCE798(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        CALLOPTIONALRETURN10(token, abi.encodeWithSelector(token.APPROVE147.selector, spender, value));
    }

    function SAFEINCREASEALLOWANCE243(ERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.ALLOWANCE798(address(this), spender).ADD379(value);
        CALLOPTIONALRETURN10(token, abi.encodeWithSelector(token.APPROVE147.selector, spender, newAllowance));
    }

    function SAFEDECREASEALLOWANCE715(ERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.ALLOWANCE798(address(this), spender).SUB918(value, "SafeERC20: decreased allowance below zero");
        CALLOPTIONALRETURN10(token, abi.encodeWithSelector(token.APPROVE147.selector, spender, newAllowance));
    }
    function CALLOPTIONALRETURN10(ERC20 token, bytes memory data) private {
        require(address(token).ISCONTRACT477(), "SafeERC20: call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface ERC20 {
    function TOTALSUPPLY249() external view returns (uint256);
    function BALANCEOF133(address account) external view returns (uint256);
    function TRANSFER16(address recipient, uint256 amount) external returns (bool);
    function ALLOWANCE798(address owner, address spender) external view returns (uint256);
    function APPROVE147(address spender, uint256 amount) external returns (bool);
    function TRANSFERFROM462(address sender, address recipient, uint256 amount) external returns (bool);
    event TRANSFER56(address indexed from, address indexed to, uint256 value);
    event APPROVAL26(address indexed owner, address indexed spender, uint256 value);
}

library Address {
    function ISCONTRACT477(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
    function SENDVALUE528(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}
