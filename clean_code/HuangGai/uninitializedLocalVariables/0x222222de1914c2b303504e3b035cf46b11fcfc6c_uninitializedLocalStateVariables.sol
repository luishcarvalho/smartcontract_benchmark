pragma solidity ^ 0.5.8;

















contract X2Bet_win {

    using SafeMath
    for uint;

    address public owner;
    mapping(address => uint) public deposit;
    mapping(address => uint) public withdrawal;
    bool public status ;

    uint public min_payment ;

    uint public systemPercent ;


    constructor()public {
        owner = msg.sender;
    }

    event ByCoin(
        address indexed from,
        uint indexed block,
        uint value,
        uint user_id,
        uint time
    );

    event ReturnRoyalty(
        address indexed from,
        uint indexed block,
        uint value,
        uint withdrawal_id,
        uint time
    );

    modifier isNotContract(){
        uint size;
        address addr ;

        assembly { size := extcodesize(addr) }
        require(size == 0 && tx.origin == msg.sender);
        _;
    }

    modifier contractIsOn(){
        require(status);
        _;
    }

    modifier minPayment(){
        require(msg.value >= min_payment);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    function byCoin(uint _user_id)contractIsOn isNotContract minPayment public payable{
        deposit[msg.sender]+= msg.value;
        emit ByCoin(msg.sender, block.number, msg.value, _user_id, now);

    }


    function pay_royaltie(address payable[] memory dests, uint256[] memory values, uint256[] memory ident) onlyOwner contractIsOn public returns(uint){
        uint256 i ;

        while (i < dests.length) {
            uint transfer_value ;

            dests[i].transfer(transfer_value);
            withdrawal[dests[i]]+=values[i];
            emit ReturnRoyalty(dests[i], block.number, values[i], ident[i], now);
            systemPercent += values[i].mul(3).div(100);
            i += 1;
        }

        return(i);
    }

    function startProphylaxy()onlyOwner public {
        status = false;
    }

    function stopProphylaxy()onlyOwner public {
        status = true;
    }

    function() external payable {

    }

}

library SafeMath {




    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c ;

        require(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        require(b > 0);
        uint256 c ;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        require(b <= a);
        uint256 c ;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c ;

        require(c >= a);
        return c;
    }
}
