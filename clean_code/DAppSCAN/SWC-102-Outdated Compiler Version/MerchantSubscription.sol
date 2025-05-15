
pragma solidity ^0.4.11;


library SafeMath {
	function add(uint256 a, uint256 b) internal constant returns (uint256) {
		uint256 c = a + b;
		assert(c >= a && c >= b);
		return c;
	}

	function sub(uint256 a, uint256 b) internal constant returns (uint256) {
		assert(b <= a);
		return a - b;
	}
}


contract MerchantSubscription {
	struct Status {
	bool isActive;
	bool isClosed;
	bool isPaused;
	}































































































































