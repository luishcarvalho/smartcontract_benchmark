pragma solidity ^0.5.1;





contract ERC20 {
	function totalSupply() public view returns (uint);
	function balanceOf(address tokenOwner) public view returns (uint balance);
	function allowance(address tokenOwner, address spender) public view returns (uint remaining);
	function transfer(address to, uint tokens) public returns (bool success);
	function approve(address spender, uint tokens) public returns (bool success);
	function transferFrom(address from, address to, uint tokens) public returns (bool success);

	event Transfer(address indexed from, address indexed to, uint tokens);
	event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract ERC20TokenLatch {

    uint64 trade_increment = 1;

	uint public fee;

	address payable public owner;

    address payable public latched_contract;

    mapping(uint32 => address payable) public buy_order_owners;
    mapping(uint32 => uint256)   public  buy_order_qty;
    mapping(uint32 => uint64)   public  buy_order_price;
    uint32 public num_buy_orders = 0;
    uint32 public max_buy_price_idx;

    mapping(uint32 => address payable) public sell_order_owners;
    mapping(uint32 => uint256)   public  sell_order_qty;
    mapping(uint32 => uint64)   public  sell_order_price;
    uint32 public num_sell_orders = 0;
    uint32 public min_sell_price_idx;

    function rmBuyOrder(uint32 idx) private {
        buy_order_owners[idx]=buy_order_owners[num_buy_orders];
        buy_order_qty[idx]=buy_order_qty[num_buy_orders];
        buy_order_price[idx]=buy_order_price[num_buy_orders];
        num_buy_orders--;
        if(max_buy_price_idx==idx){
            max_buy_price_idx=0;
            for(uint32 i=1;i<num_buy_orders;i++){
                if(buy_order_price[max_buy_price_idx]<buy_order_price[i])max_buy_price_idx=i;
            }
        }
    }

    function rmSellOrder(uint32 idx) private {
        sell_order_owners[idx]=sell_order_owners[num_sell_orders];
        sell_order_qty[idx]=sell_order_qty[num_sell_orders];
        sell_order_price[idx]=sell_order_price[num_sell_orders];
        num_sell_orders--;
        if(min_sell_price_idx==idx){
            min_sell_price_idx=0;
            for(uint32 i=1;i<num_sell_orders;i++){
                if(sell_order_price[min_sell_price_idx]>sell_order_price[i])min_sell_price_idx=i;
            }
        }
    }

    function addBuyOrder(address payable adr, uint256 qty, uint64 price) private {
        buy_order_owners[num_buy_orders] = adr;
        buy_order_qty[num_buy_orders] = qty;
        buy_order_price[num_buy_orders] = price;
        if(price>buy_order_price[max_buy_price_idx])max_buy_price_idx = num_buy_orders;
        if(num_buy_orders==0)max_buy_price_idx = 0;
        num_buy_orders++;
    }

    function addSellOrder(address payable adr, uint256 qty, uint64 price) private {
        sell_order_owners[num_sell_orders] = adr;
        sell_order_qty[num_sell_orders] = qty;
        sell_order_price[num_sell_orders] = price;
        if(price<sell_order_price[min_sell_price_idx])min_sell_price_idx = num_sell_orders;
        if(num_sell_orders==0)min_sell_price_idx = 0;
        num_sell_orders++;
    }

    function maxBuyPrice() public view returns (uint64 price){
        return buy_order_price[max_buy_price_idx];
    }

    function minSellPrice() public view returns (uint64 price){
        return sell_order_price[min_sell_price_idx];
    }

    function getPrice() public view returns (uint64){
        if(num_sell_orders==0){
            if(num_buy_orders==0)return 1000;
            else return maxBuyPrice();
        }else if(num_buy_orders==0) return minSellPrice();
        return (minSellPrice()+maxBuyPrice())/2;
    }

    constructor(address payable latch) public {
        latched_contract=latch;
        owner = msg.sender;
		fee = .0001 ether;
    }

    function balanceOf(address tokenOwner) public view returns (uint balance){
        return ERC20(latched_contract).balanceOf(tokenOwner);
    }

    function totalSupply() public view returns (uint){
        return ERC20(latched_contract).totalSupply();
    }

    function transfer(address target, uint qty) private{
        ERC20(latched_contract).transfer(target, qty);
    }

	function getFee() public view returns (uint){
		return fee;
	}

	function getBuyPrice() public view returns (uint64){
	    if(num_buy_orders>0)return maxBuyPrice()+trade_increment;
	    else return getPrice();
	}

	function getSellPrice() public view returns (uint64){
	    if(num_sell_orders>0)return minSellPrice()-trade_increment;
	    else return getPrice();
	}

	function getSellReturn(uint amount) public view returns (uint){

		return (getSellPrice()*amount)/10000;
	}

	function getBuyCost(uint amount) public view returns (uint){
	    return ((amount*getBuyPrice())/10000) + fee;
	}

	function buy(uint tokens)public payable{
		placeBuyOrder(tokens, getBuyPrice());
	}

	function placeBuyOrder(uint tokens, uint64 price10000) public payable{
	    uint cost = fee + ((tokens*price10000)/10000);
	    require(msg.value>=cost);


		msg.sender.transfer(msg.value-cost);
		owner.transfer(fee);

	    uint left = tokens;


		for(uint32 i=0;i<num_sell_orders;i++){
		    if(price10000<minSellPrice())
		        break;

		    if(sell_order_price[i]<=price10000){

		        if(sell_order_qty[i]>left){

		            sell_order_qty[i]-=left;
		            sell_order_owners[i].transfer((sell_order_price[i]*left)/10000);
		            transfer(msg.sender, left);


		            owner.transfer(((price10000-sell_order_price[i])*left)/10000);


		            return;
		        }else{

    		        uint qty = sell_order_qty[i];
    		        left-=qty;
    	            sell_order_owners[i].transfer((sell_order_price[i]*qty)/10000);
    	            transfer(msg.sender, qty);


    	            owner.transfer(((price10000-sell_order_price[i])*qty)/10000);


    	            rmSellOrder(i);
    		    }
		    }
		}


		addBuyOrder(msg.sender, left, price10000);

	}

	function sell(uint tokens)public{
	    placeSellOrder(tokens, getSellPrice());
	}

	function placeSellOrder(uint tokens, uint64 price10000) public payable{
	    require(ERC20(latched_contract).allowance(msg.sender, address(this))>=tokens);


		ERC20(latched_contract).transferFrom(msg.sender,address(this),tokens);


	    uint64 sell_price = price10000;
	    uint left = tokens;


		for(uint32 i=0;i<num_buy_orders;i++){
		    if(sell_price>maxBuyPrice())
		        break;

		    if(buy_order_price[i]>=sell_price){

		        if(buy_order_qty[i]>left){

		            buy_order_qty[i]-=left;
		            transfer(buy_order_owners[i],left);
		            msg.sender.transfer((sell_price*left)/10000);


		            owner.transfer(((buy_order_price[i]-sell_price)*left)/10000);


		            return;
		        }else{

    		        uint qty = buy_order_qty[i];
    		        left-=qty;

		            transfer(buy_order_owners[i],qty);
    	            msg.sender.transfer((sell_price*qty)/10000);


    	            owner.transfer(((buy_order_price[i]-sell_price)*qty)/10000);


    	            rmBuyOrder(i);
    		    }
		    }
		}


		addSellOrder(msg.sender, left, sell_price);
	}

    function canBuy(uint amount) public pure returns (bool possible){
        return true;
    }

    function canSell(uint amount) public pure returns (bool possible){
	    return true;
    }

	function get_tradable() public view returns (uint){
        return ERC20(latched_contract).totalSupply();
    }

	function setFee(uint new_fee) public{
	    require(msg.sender==owner);
	    fee=new_fee;
	}

	function destroy() public {
	    require(msg.sender==owner);
	    require(address(this).balance<0.1 ether);
	    require(address(this).balance==0);
	    selfdestruct(msg.sender);
	}
}
