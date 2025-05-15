



pragma solidity ^0.5.10;






contract CryptoBoard {
	address private owner;

	string public urlCharity;
	string public nameCharity;
	string public urlBillboard;
	string public lcdMessage;

	address payable public payeeDev;
	address payable public payeeCharity;
	uint256 public minCost;
	uint256 public lastEpoch;
	uint256 public updateCost;
	uint8 public split;
	uint8 public markup;


	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}


	constructor(address payable initDevPayee, string memory initCharityName, address payable initCharityPayee, string memory initCharityUrl) public {

		owner = msg.sender;
		payeeDev = initDevPayee;
		payeeCharity = initCharityPayee;

		nameCharity = initCharityName;
		urlCharity = initCharityUrl;

		urlBillboard = "https:

		lcdMessage = "Cryptoboard - The interwebs Ethereum powered billboard!";

		lastEpoch = now;

		markup = 125;
		split = 5;
		minCost = .01 ether;
		updateCost = minCost;
	}


	function updateBillboard(string memory newBillboardUrl) public payable {
	    require(bytes(newBillboardUrl).length != 0, "Billboard URL cannot be blank");
		require(msg.value > 0, "You need to actually send ETH!");

		updateCost = getCost();

		require(msg.value >= updateCost, "You didn't send enough wei, check getCost()");

		lastEpoch = now;
		urlBillboard = newBillboardUrl;
		updateCost = updateCost * markup / 100;

		performDonation(msg.value);
	}


	function updateLcdMessage(string memory newLcdMessage) public payable {
	    require(bytes(newLcdMessage).length != 0, "LCD message cannot be blank");
		require(msg.value > 0, "You need to actually send ETH!");
		require(msg.value >= minCost/2, "You didn't send enough wei, cost=mincost/2");
		lcdMessage = newLcdMessage;
		performDonation(msg.value);
	}


	function setDevData(address payable newPayeeDev) public onlyOwner {
		require(newPayeeDev != address(0), "Developer payout cannot be burned");
		payeeDev = newPayeeDev;
	}


	function setCharityData(string memory newCharityName, address payable newPayeeCharity, string memory newCharityUrl) public onlyOwner {
		require(bytes(newCharityName).length != 0, "Charity name cannot be blank");
		require(bytes(newCharityUrl).length != 0, "Charity URL cannot be blank");
		require(newPayeeCharity != address(0), "Charity payout cannot be burned! Are you crazy?!");
		nameCharity = newCharityName;
		payeeCharity = newPayeeCharity;
		urlCharity = newCharityUrl;
	}


	function setCostData(uint256 newMinCost, uint8 newMarkup, uint8 newSplit) public onlyOwner {
	    require(newMinCost != 0 && newMarkup != 0 && newSplit != 0, "All cost parameters must be > 0");
		minCost = newMinCost;
		markup = newMarkup;
		split = newSplit;
	}


	function performDonation(uint256 v) private {
		uint256 devSplit ;


		payeeDev.transfer(devSplit);
		payeeCharity.transfer(msg.value-devSplit);
	}


	function getCost() public view returns (uint256) {

		uint256 updateDelta ;



		uint256 tmpCost ;

		for(uint256 i ; i < updateDelta; i++)

		{
			tmpCost -= tmpCost * 10 / 100;
			if(tmpCost < minCost) {
				tmpCost = minCost;
				break;
			}
		}
		return tmpCost;
	}
}
