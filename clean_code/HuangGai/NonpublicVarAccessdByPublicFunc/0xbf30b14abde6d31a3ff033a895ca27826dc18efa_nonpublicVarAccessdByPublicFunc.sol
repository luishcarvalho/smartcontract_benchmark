



pragma solidity ^0.5.12;

interface PASTA {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function setFoodbank(address _foodbank) external;
    function setGovernance(address _governance) external;
}

contract ChefsTable {


    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }


    PASTA spaghetti;

    mapping(address=>uint) internal balances;

    struct Proposal {
        uint id;
        address proposer;
        mapping(address => uint) forVotes;
        mapping(address => uint) againstVotes;
        uint totalForVotes;
        uint totalAgainstVotes;
        uint start;
        uint end;
        address newFood;
        address newGov;
    }

    mapping(address => uint) internal voteLock;
    mapping (uint => Proposal) internal proposals;
    uint internal proposalCount;
    uint internal period = 3 days;
    uint internal lock = 3 days;
    uint internal minimum = 1e18;
    uint internal govLock;


    constructor(address _spaghetti) public {
        spaghetti = PASTA(_spaghetti);
        govLock = block.timestamp + 14 days;
    }

    function join(uint amount) public {
        uint bal = spaghetti.balanceOf(address(this));
        require(spaghetti.transferFrom(msg.sender, address(this), amount), "join/transferFrom-fail");
        balances[msg.sender] += spaghetti.balanceOf(address(this)) - bal;
    }

    function free(uint amount) public {
        require(voteLock[msg.sender] < block.timestamp, "still votelocked");
        require(balances[msg.sender] <= amount, "amount too high");
        balances[msg.sender] = sub(balances[msg.sender], amount);
        require(spaghetti.transfer(msg.sender, amount), "free/transfer-failed");
    }

    function propose(address _newFood, address _newGov) public {
        require(block.timestamp >= govLock, "No governance for 2 weeks");
        require(balances[msg.sender] > minimum, "<minimum");
        proposals[proposalCount++] = Proposal({
            id: proposalCount,
            proposer: msg.sender,
            totalForVotes: 0,
            totalAgainstVotes: 0,
            start: block.timestamp,
            end: add(block.timestamp, period),
            newFood: _newFood,
            newGov: _newGov
        });

        voteLock[msg.sender] = add(block.timestamp, lock);
    }

    function voteFor(uint id) public {
        require(proposals[id].start < block.timestamp , "<start");
        require(proposals[id].end > block.timestamp , ">end");
        uint votes = sub(balances[msg.sender], proposals[id].forVotes[msg.sender]);
        proposals[id].totalForVotes = add(votes, proposals[id].totalForVotes);
        proposals[id].forVotes[msg.sender] = balances[msg.sender];

        voteLock[msg.sender] = add(block.timestamp, lock);
    }

    function voteAgainst(uint id) public {
        require(proposals[id].start < block.timestamp , "<start");
        require(proposals[id].end > block.timestamp , ">end");
        uint votes = sub(balances[msg.sender], proposals[id].againstVotes[msg.sender]);
        proposals[id].totalAgainstVotes = add(votes, proposals[id].totalAgainstVotes);
        proposals[id].againstVotes[msg.sender] = balances[msg.sender];

        voteLock[msg.sender] = add(block.timestamp, lock);
    }

    function execute(uint id) public {

        if ((proposals[id].end + lock) < block.timestamp && proposals[id].totalForVotes > proposals[id].totalAgainstVotes) {
            if (proposals[id].newFood != address(0)) {
                spaghetti.setFoodbank(proposals[id].newFood);
            }
            if (proposals[id].newGov != address(0)) {
                spaghetti.setGovernance(proposals[id].newGov);
            }
        }
    }

}
