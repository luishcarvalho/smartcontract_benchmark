







pragma solidity ^0.4.7;



contract Fundraiser {



    uint public constant dust = 1 finney;





    address public admin;
    address public treasury;


    uint public beginBlock;
    uint public endBlock;



    uint public atomRate;


    bool public isHalted = false;






    mapping (address => uint) public record;
    mapping (address => address) public returnAddresses;


    uint public totalEther = 0;

    uint public totalAtom = 0;





    function Fundraiser(address _admin, address _treasury, uint _beginBlock, uint _endBlock, uint _atomRate) {
        admin = _admin;
        treasury = _treasury;
        beginBlock = _beginBlock;
        endBlock = _endBlock;
	atomRate = _atomRate;
    }


    modifier only_admin { if (msg.sender != admin) throw; _; }

    modifier only_before_period { if (block.number >= beginBlock) throw; _; }

    modifier only_during_period { if (block.number < beginBlock || block.number >= endBlock || isHalted) throw; _; }

    modifier only_during_halted_period { if (block.number < beginBlock || block.number >= endBlock || !isHalted) throw; _; }

    modifier only_after_period { if (block.number < endBlock) throw; _; }

    modifier is_not_dust { if (msg.value < dust) throw; _; }


    event Received(address indexed recipient, uint amount, uint currentRate);

    event Halted();

    event Unhalted();


    function() {
	throw;
    }



    function donate(address _donor, address _returnAddress, bytes32 checksum) payable only_during_period is_not_dust {

	if (!(sha3(bytes32(_donor)^bytes32(_returnAddress)) == checksum)) throw;



        if (!treasury.call.value(msg.value)()) throw;


	var atoms = msg.value * atomRate;


        record[_donor] += atoms;
        returnAddresses[_donor] = _returnAddress;


        totalEther += msg.value;
	totalAtom += atoms;

        Received(_donor, msg.value, atomRate);
    }



    function adjustRate(uint newRate) only_admin only_during_period {
	atomRate = newRate;
    }


    function halt() only_admin only_during_period {
        isHalted = true;
        Halted();
    }


    function unhalt() only_admin only_during_halted_period {
        isHalted = false;
        Unhalted();
    }


    function kill() only_admin only_after_period {
        suicide(treasury);
    }
}
