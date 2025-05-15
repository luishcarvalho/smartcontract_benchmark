

pragma solidity 0.5.14;

contract SwapProxyInterface {
    function NAME553() public view returns(string memory);
    function GETSWAPQUANTITY3(address src, address dst, uint256 srcQty) public view returns(uint256);
    function GETSWAPRATE341(address src, address dst, uint256 srcQty) public view returns(uint256);
    function EXECUTESWAP17(address srcToken, uint256 srcQty, address dstToken, address dstAddress) public returns(bool);
}

contract ERC20 {
    function BALANCEOF790(address account) external view returns (uint256);
    function TRANSFER443(address recipient, uint256 amount) external returns (bool);
    function DECIMALS628() public view returns(uint);
    function TRANSFERFROM10(address sender, address recipient, uint256 amount) external returns (bool);
    function APPROVE334(address spender, uint256 value) public returns (bool);
    function ALLOWANCE190(address owner, address spender) public view returns (uint256);
}

contract Auction {
    function BIDANDWITHDRAW39(address _rebalancingSetToken, uint256 _quantity, bool _allowPartialFill) external;
}


contract AdminRole {

    mapping (address => bool) adminGroup;
    address payable owner;

    constructor () public {
        adminGroup[msg.sender] = true;
        owner = msg.sender;
    }

    modifier ONLYADMIN702() {
        require(
            ISADMIN40(msg.sender),
            "The caller is not Admin"
        );
        _;
    }

    modifier ONLYOWNER7 {
        require(
            owner == msg.sender,
            "The caller is not Owner"
        );
        _;
    }

    function ADDADMIN285(address addr) external ONLYADMIN702 {
        adminGroup[addr] = true;
    }
    function DELADMIN850(address addr) external ONLYADMIN702 {
        adminGroup[addr] = false;
    }

    function ISADMIN40(address addr) public view returns(bool) {
        return adminGroup[addr];
    }

    function KILL112() external ONLYOWNER7 {
        selfdestruct(owner);
    }
}

contract Withdrawable is AdminRole {

    function WITHDRAWTO222 (address payable dst, uint founds, address token) external ONLYADMIN702 {
        if (token == address(0))
            require (address(this).balance >= founds);
        else {
            ERC20 erc20 = ERC20(token);
            require (erc20.BALANCEOF790(address(this)) >= founds);
        }
        SENDFOUNDS539(dst,founds, token);
    }


    function SENDFOUNDS539(address payable dst, uint amount, address token) internal returns(bool) {
        ERC20 erc20;
        if (token == address(0))
            require(address(dst).send(amount), "Impossible send founds");
        else {
            erc20 = ERC20(token);
            require(erc20.TRANSFER443(dst, amount), "Impossible send founds");
        }
    }
}

contract GasReserve {
    uint256[] g;

    event GASREPORT173(
        uint256 total_gas_consumed,
        uint256 words_used
    );

    function RESERVEGAS352(uint256 quantity) public {
        if (quantity != 0)
            RESERVE323(quantity);
    }

    function GASWORDSQUANTITY848() external view returns(uint256) {
        return g.length;
    }

    function USEGAS557(uint256 start_gas) internal {
        uint256 consumed_gas = start_gas - gasleft();
        uint256 words = consumed_gas/35000;
        RELEASEGAS697(words);
        emit GASREPORT173(consumed_gas,words);
    }

    function RELEASEGAS697(uint256 quantity) internal {
        if (g.length!=0) {
            if (quantity <= g.length)
                RELEASE117(quantity);
            else
                RELEASE117(g.length);
        }
    }

    function GETRESERVEADDR673 () private pure returns(uint256 reserve) {
        uint256 gaddr;
        assembly {
            gaddr := g_slot
        }
        return uint256(keccak256(abi.encode(gaddr)));
    }

    function RESERVE323(uint256 quantity) private {
        uint256 len = g.length;
        uint256 start = GETRESERVEADDR673() + len;
        uint256 end = start + quantity;

        len = len + quantity;

        for (uint256 i = start; i < end; i ++) {
            assembly {
                sstore(i,1)
            }
        }
        assembly {
            sstore(g_slot, len)
        }
    }

    function RELEASE117(uint256 quantity) private {
        uint256 len = g.length;
        uint256 start = GETRESERVEADDR673() + (len - quantity);
        uint256 end = GETRESERVEADDR673() + len;

        len = len - quantity;

        for (uint256 i = start; i < end; i++) {
            assembly {
                sstore(i,0)
            }
        }
        assembly {
            sstore(g_slot, len)
        }
    }
}

contract Swapper is Withdrawable, GasReserve {

    event TOKENSWAPPED315(address indexed srcToken, address indexed dstToken, string swapProxy);

    address[10] swapProxy;
    uint256 swapProxySize = 0;

    function ADDSWAPPROXY494 (address addr) external ONLYADMIN702 {
        require(swapProxySize < 10, "Max SwapProxy has reatched");

        for (uint256 i; i < 10; i++ ) {
            if (swapProxy[i] == address(0)) {
                swapProxy[i] = addr;
                swapProxySize = swapProxySize + 1;
                return;
            }
        }
        revert("Unable to found free slot");
    }

    function DELSWAPPROXY40(address addr) external ONLYADMIN702 {
        for (uint256 i; i < 10; i++ ) {
            if (swapProxy[i] == addr) {
                swapProxy[i] = address(0);
                swapProxySize = swapProxySize - 1;
                return;
            }
        }
        revert("Unable to found a proxy");
    }

    function GETBESTSWAPRATE862(address src, address dst, uint256 srcQty) external view
        returns (string memory name, uint256 rate, uint256 index)
    {
        SwapProxyInterface spi;


        if (swapProxySize == 0)
            return (name,rate,index);

        (index, rate) = GETBESTRATE469(src,dst,srcQty);

        if (rate != 0) {
            spi = SwapProxyInterface(swapProxy[index]);
            name = spi.NAME553();
        }
    }

    function TOKENSWAPONBEST97(address srcToken, uint256 srcQty, address dstToken, address dstAddress, bool useReserveOfGas) external {
        uint256 start_gas = gasleft();

        ERC20 token = ERC20(srcToken);
        require(token.TRANSFERFROM10(msg.sender, address(this), srcQty), "Unable to transferFrom()");

        SWAPONBEST849(srcToken, srcQty, dstToken, dstAddress);

        if (useReserveOfGas) {
            if (ISADMIN40(msg.sender)) {
                USEGAS557(start_gas);
            }
        }
    }

    function TOKENSWAPON145(uint256 dex, address srcToken, uint256 srcQty, address dstToken, address dstAddress, bool useReserveOfGas) external {
        uint256 start_gas = gasleft();

        ERC20 token = ERC20(srcToken);
        require(token.TRANSFERFROM10(msg.sender, address(this), srcQty), "Unable to transferFrom()");

        SWAPON236(dex,srcToken, srcQty, dstToken, dstAddress);

        if (useReserveOfGas) {
            if (ISADMIN40(msg.sender)) {
                USEGAS557(start_gas);
            }
        }
    }

    function GETBESTRATE469(address src, address dst, uint256 srcQty)
        internal view returns(uint256 index, uint256 rate )
    {
        SwapProxyInterface spi;
        uint256 tmp;
        uint256 i;


        for (i = 0; i < 10; i++) {
            if (swapProxy[i] != address(0)) {
                spi = SwapProxyInterface(swapProxy[i]);
                tmp = spi.GETSWAPRATE341(src,dst,srcQty);
                if (tmp > rate) {
                    rate = tmp;
                    index = i;
                }
            }
        }
    }

    function SWAPONBEST849(address srcToken, uint256 srcQty, address dstToken, address dstAddress)
        internal returns(bool)
    {
        SwapProxyInterface spi;
        ERC20 token = ERC20(srcToken);
        uint256 index;
        uint256 rate;

        require(swapProxySize != 0, "Unable to found a configured swap");

        (index,rate) = GETBESTRATE469(srcToken,dstToken,srcQty);

        require(rate != 0, "Unable to found a valid rate");


        require(token.APPROVE334(swapProxy[index], srcQty), "Unable to appove()");

        spi = SwapProxyInterface(swapProxy[index]);

        require(spi.EXECUTESWAP17(srcToken,srcQty,dstToken,dstAddress), "Unable to executeSwap");

        emit TOKENSWAPPED315(srcToken,dstToken,spi.NAME553());

        return true;
    }

    function SWAPON236(uint256 dex, address srcToken, uint256 srcQty, address dstToken, address dstAddress)
        internal returns(bool)
    {
        SwapProxyInterface spi;
        ERC20 token = ERC20(srcToken);

        require(swapProxySize != 0 && swapProxy[dex] != address(0), "Unable to found a swap identified by dex");


        require(token.APPROVE334(swapProxy[dex], srcQty), "Unable to appove()");

        spi = SwapProxyInterface(swapProxy[dex]);

        require(spi.EXECUTESWAP17(srcToken,srcQty,dstToken,dstAddress), "Unable to executeSwap");

        emit TOKENSWAPPED315(srcToken,dstToken,spi.NAME553());

        return true;
    }
}


contract Bidder is Swapper {
    address public auctionAddress = 0xe23FB31dD2edacEbF7d92720358bB92445F47fDB;
    address public transferProxy = 0x882d80D3a191859d64477eb78Cca46599307ec1C;

    function BIDANDSWAPON850(uint256 dex, address tokenset, uint256 inflow, uint256 minimumBid, uint256 srcQty, address src, address dst, bool useReserveOfGas) external {
        uint256 start_gas = gasleft();
        uint256 quantity;
        Auction auction = Auction(auctionAddress);
        ERC20 srcToken = ERC20(src);
        ERC20 dstToken = ERC20(dst);
        uint256 dst_startBalance = dstToken.BALANCEOF790(address(this));


        require(srcToken.TRANSFERFROM10(msg.sender,address(this),srcQty), "Unable to transferFrom()");


        require(srcToken.APPROVE334(transferProxy,srcQty), "Unable to approve");


        quantity = (srcQty / inflow) * minimumBid;


        auction.BIDANDWITHDRAW39(tokenset,quantity,true);


        SWAPON236(dex,dst,dstToken.BALANCEOF790(address(this))-dst_startBalance,src,msg.sender);

        if (useReserveOfGas) {
            if (ISADMIN40(msg.sender)) {
                USEGAS557(start_gas);
            }
        }
    }

    function BIDANDSWAPONBEST154(address tokenset, uint256 inflow, uint256 minimumBid, uint256 srcQty, address src, address dst, bool useReserveOfGas)
        external
    {
        uint256 start_gas = gasleft();
        uint256 quantity;
        Auction auction = Auction(auctionAddress);
        ERC20 srcToken = ERC20(src);
        ERC20 dstToken = ERC20(dst);
        uint256 dst_startBalance = dstToken.BALANCEOF790(address(this));


        require(srcToken.TRANSFERFROM10(msg.sender,address(this),srcQty), "Unable to transferFrom()");


        require(srcToken.APPROVE334(transferProxy,srcQty), "Unable to approve");



        quantity = (srcQty / inflow) * minimumBid;

        auction.BIDANDWITHDRAW39(tokenset,quantity,true);


        SWAPONBEST849(dst,dstToken.BALANCEOF790(address(this))-dst_startBalance,src,msg.sender);

        if (useReserveOfGas) {
            if (ISADMIN40(msg.sender)) {
                USEGAS557(start_gas);
            }
        }
    }
}
