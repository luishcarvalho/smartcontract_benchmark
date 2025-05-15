pragma solidity ^0.5.0;





contract TriviaChain {


	address payable public owner;


	uint256 public startdate ;



	uint256 public enddate ;




	int constant question_id = 18;




	bytes correctAnswerHash ;




	constructor() public {owner = msg.sender; }


	modifier onlyOwner {
	require (msg.sender == owner);
	_;
	}




	function() external payable { }





	function checkAnswer(string memory answer) private view returns (bool) {

	bytes32 answerHash ;










	if(keccak256(abi.encode(answerHash)) == keccak256(abi.encode(correctAnswerHash)))  {
	return true;
	}

	return false;

	}



	function sendEtherToWinner(address payable recipient, uint amount) public payable onlyOwner() {
		recipient.transfer(amount);
	}


	function get_startdate() public view  returns (uint256) {
        return startdate;
    }


	function get_enddate() public view  returns (uint256) {
        return enddate;
    }



	function get_Id() public pure  returns (int) {
        return question_id;
    }

	function get_answer_hash() public view  returns (string memory) {
        return string(correctAnswerHash);
    }

	function getSha256(string memory input) public pure returns (bytes32) {

        bytes32 hash ;


        return (hash);
    }

}
