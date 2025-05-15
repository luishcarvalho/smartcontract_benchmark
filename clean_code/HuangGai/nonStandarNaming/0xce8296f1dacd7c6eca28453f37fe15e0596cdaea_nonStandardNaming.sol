

pragma solidity ^0.5.0;

library Set {


    struct Data {
        mapping(address => bool) flags;
    }







    function INSERT214(Data storage self, address value)
        public
        returns (bool)
    {
        if (self.flags[value])
            return false;
        self.flags[value] = true;
        return true;
    }

    function REMOVE691(Data storage self, address value)
        public
        returns (bool)
    {
        if (!self.flags[value])
            return false;
        self.flags[value] = false;
        return true;
    }

    function CONTAINS100(Data storage self, address value)
        public
        view
        returns (bool)
    {
        return self.flags[value];
    }
}



pragma solidity ^0.5.0;


contract Crowdsourcing {
    address public _owner;
    string task;
    uint private _total;
    uint private _amount;
    string private _content;
    uint private _current  = 0;
    address[] private workersArr;
    uint private workerCount;
    mapping(address => bool) public paid;
    mapping(address => string) private answers;
    Set.Data workers;

    event TOVERIFICATION491 (
        address indexed id
    );

    event REJECTION224 (
        address indexed rejected
    );

    constructor(address owner, uint total, string memory content, uint money) public payable{
        require(money % total == 0);
        _owner = owner;
        _total = total;
        _amount = money;
        _content = content;

    }

    function GETTOTAL441() public view returns (uint) {
        return _total;
    }

    function GETAMOUNT436() public view returns (uint) {
        return _amount;
    }

    function GETCONTENT713() public view returns (string memory) {
        return _content;
    }

    function ISPAYING412() public view returns (bool) {
        return _current  < _total;
    }

    function GETANSWERS578(address f) public view returns (string memory) {
        require (msg.sender == _owner);
        return answers[f];
    }

    function ADDMONEY81() public payable {
        require((msg.value + _amount) % _total == 0);
        _amount += msg.value;
    }


    function() external payable { }

    function STOP122() public {
        require (msg.sender == _owner);
        selfdestruct(msg.sender);
    }

    function ACCEPT249(address payable target) public payable {
        require(msg.sender == _owner);
        require(!paid[target]);
        require(Set.CONTAINS100(workers, target));
        require(_current  < _total);
        paid[target] = true;
        _current ++;
        target.transfer(_amount / _total);
    }

    function REJECT173(address payable target) public payable {
        require(msg.sender == _owner);
        require(!paid[target]);
        require(Set.CONTAINS100(workers, target));
        require(_current  < _total);
        emit REJECTION224(target);
        answers[target] = '';
    }

    function ANSWER262(string calldata ans) external {
        answers[msg.sender] = ans;
        workersArr.push(msg.sender);
        if (Set.INSERT214(workers, msg.sender))
        {
            workerCount++;
        }
        emit TOVERIFICATION491(msg.sender);
    }

    function GETWORKERS720(uint number) public view returns (address) {
        require(msg.sender == _owner);
        require(number < workerCount);
        return workersArr[number];
    }

    function GETNUMBEROFWORKERS864() public view returns (uint) {
        require(msg.sender == _owner);
        return workerCount;
    }

    function ISPAID186(address a) public view returns (bool) {
        return paid[a];
    }

    function MYPAY5() public view returns (bool) {
        return paid[msg.sender];
    }

    function MYANSWER478() public view returns (string memory) {
        if (bytes(answers[msg.sender]).length == 0) return "";
        return answers[msg.sender];
    }
}



pragma solidity ^0.5.0;


contract CrdSet {
    Crowdsourcing[] public list;
    event NEWCONTRACT472(Crowdsourcing indexed c);

    function CREATECC856(uint total, string memory content) public payable returns (Crowdsourcing){
        require(msg.value % total == 0, "Amount of money need to be dividable by the total number of answers");
        Crowdsourcing a = new Crowdsourcing(msg.sender, total, content, msg.value);
        list.push(a);
        address(a).transfer(msg.value);
        emit NEWCONTRACT472(a);
        return a;
    }

    function GETCONTRACCOUNT419() public view returns (uint) {
        return list.length;
    }

}
