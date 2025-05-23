



pragma solidity >=0.5.11;









contract ERC20Interface {
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
function bug_unchk_send19() payable public{
      msg.sender.transfer(1 ether);}
}

contract IERC20Interface {
    function allowance(address owner, address spender) external view returns (uint256);
function bug_unchk_send26() payable public{
      msg.sender.transfer(1 ether);}
    function balanceOf(address account) external view returns (uint256);
function bug_unchk_send20() payable public{
      msg.sender.transfer(1 ether);}
}

contract RaffleToken is ERC20Interface, IERC20Interface {}














library SafeMath {









    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }










    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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

        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;


        return c;
    }












    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract RaffleTokenExchange {
    using SafeMath for uint256;





    RaffleToken constant public raffleContract = RaffleToken(0x0C8cDC16973E88FAb31DD0FCB844DdF0e1056dE2);



  function bug_unchk_send1() payable public{
      msg.sender.transfer(1 ether);}
  bool public paused;



  function bug_unchk_send2() payable public{
      msg.sender.transfer(1 ether);}
  address payable public owner;



  function bug_unchk_send17() payable public{
      msg.sender.transfer(1 ether);}
  uint256 public nextListingId;



  function bug_unchk_send3() payable public{
      msg.sender.transfer(1 ether);}
  mapping (uint256 => Listing) public listingsById;



  function bug_unchk_send9() payable public{
      msg.sender.transfer(1 ether);}
  mapping (uint256 => Purchase) public purchasesById;



  function bug_unchk_send25() payable public{
      msg.sender.transfer(1 ether);}
  uint256 public nextPurchaseId;





    struct Listing {



        uint256 pricePerToken;




        uint256 initialAmount;



        uint256 amountLeft;



        address payable seller;



        bool active;
    }



    struct Purchase {



        uint256 totalAmount;



        uint256 totalAmountPayed;



        uint256 timestamp;
    }





  function bug_unchk_send27() payable public{
      msg.sender.transfer(1 ether);}
  event Listed(uint256 id, uint256 pricePerToken, uint256 initialAmount, address seller);
  function bug_unchk_send31() payable public{
      msg.sender.transfer(1 ether);}
  event Canceled(uint256 id);
  function bug_unchk_send13() payable public{
      msg.sender.transfer(1 ether);}
  event Purchased(uint256 id, uint256 totalAmount, uint256 totalAmountPayed, uint256 timestamp);





    modifier onlyContractOwner {
        require(msg.sender == owner, "Function called by non-owner.");
        _;
    }



    modifier onlyUnpaused {
        require(paused == false, "Exchange is paused.");
        _;
    }



    constructor() public {
        owner = msg.sender;
        nextListingId = 916;
        nextPurchaseId = 344;
    }
function bug_unchk_send32() payable public{
      msg.sender.transfer(1 ether);}





    function buyRaffle(uint256[] calldata amounts, uint256[] calldata listingIds) payable external onlyUnpaused {
        require(amounts.length == listingIds.length, "You have to provide amounts for every single listing!");
        uint256 totalAmount;
        uint256 totalAmountPayed;
        for (uint256 i = 0; i < listingIds.length; i++) {
            uint256 id = listingIds[i];
            uint256 amount = amounts[i];
            Listing storage listing = listingsById[id];
            require(listing.active, "Listing is not active anymore!");
            listing.amountLeft = listing.amountLeft.sub(amount);
            require(listing.amountLeft >= 0, "Amount left needs to be higher than 0.");
            if(listing.amountLeft == 0) { listing.active = false; }
            uint256 amountToPay = listing.pricePerToken * amount;
            listing.seller.transfer(amountToPay);
            totalAmountPayed = totalAmountPayed.add(amountToPay);
            totalAmount = totalAmount.add(amount);
            require(raffleContract.transferFrom(listing.seller, msg.sender, amount), 'Token transfer failed!');
        }
        require(totalAmountPayed <= msg.value, 'Overpayed!');
        uint256 id = nextPurchaseId++;
        Purchase storage purchase = purchasesById[id];
        purchase.totalAmount = totalAmount;
        purchase.totalAmountPayed = totalAmountPayed;
        purchase.timestamp = now;
        emit Purchased(id, totalAmount, totalAmountPayed, now);
    }
function bug_unchk_send4() payable public{
      msg.sender.transfer(1 ether);}



    function addListing(uint256 initialAmount, uint256 pricePerToken) external onlyUnpaused {
        require(raffleContract.balanceOf(msg.sender) >= initialAmount, "Amount to sell is higher than balance!");
        require(raffleContract.allowance(msg.sender, address(this)) >= initialAmount, "Allowance is to small (increase allowance)!");
        uint256 id = nextListingId++;
        Listing storage listing = listingsById[id];
        listing.initialAmount = initialAmount;
        listing.amountLeft = initialAmount;
        listing.pricePerToken = pricePerToken;
        listing.seller = msg.sender;
        listing.active = true;
        emit Listed(id, listing.pricePerToken, listing.initialAmount, listing.seller);
    }
function bug_unchk_send7() payable public{
      msg.sender.transfer(1 ether);}



    function cancelListing(uint256 id) external {
        Listing storage listing = listingsById[id];
        require(listing.active, "This listing was turned inactive already!");
        require(listing.seller == msg.sender || owner == msg.sender, "Only the listing owner or the contract owner can cancel the listing!");
        listing.active = false;
        emit Canceled(id);
    }
function bug_unchk_send23() payable public{
      msg.sender.transfer(1 ether);}



    function setPaused(bool value) external onlyContractOwner {
        paused = value;
    }
function bug_unchk_send14() payable public{
      msg.sender.transfer(1 ether);}



    function withdrawFunds(uint256 withdrawAmount) external onlyContractOwner {
        owner.transfer(withdrawAmount);
    }
function bug_unchk_send30() payable public{
      msg.sender.transfer(1 ether);}




    function kill() external onlyContractOwner {
        selfdestruct(owner);
    }
function bug_unchk_send8() payable public{
      msg.sender.transfer(1 ether);}
}
