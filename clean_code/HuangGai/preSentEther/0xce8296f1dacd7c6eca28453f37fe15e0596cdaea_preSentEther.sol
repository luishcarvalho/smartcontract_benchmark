

pragma solidity ^0.5.0;

library Set {


    struct Data {
        mapping(address => bool) flags;
    }







    function insert(Data storage self, address value)
        public
        returns (bool)
    {
        if (self.flags[value])
            return false;
        self.flags[value] = true;
        return true;
    }

    function remove(Data storage self, address value)
        public
        returns (bool)
    {
        if (!self.flags[value])
            return false;
        self.flags[value] = false;
        return true;
    }

    function contains(Data storage self, address value)
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

    event toVerification (
        address indexed id
    );

    event rejection (
        address indexed rejected
    );

    constructor(address owner, uint total, string memory content, uint money) public payable{
        require(address(this).balance == 0);
        _owner = owner;
        _total = total;
        _amount = money;
        _content = content;

    }

    function getTotal() public view returns (uint) {
        return _total;
    }

    function getAmount() public view returns (uint) {
        return _amount;
    }

    function getContent() public view returns (string memory) {
        return _content;
    }

    function isPaying() public view returns (bool) {
        return _current  < _total;
    }

    function getAnswers(address f) public view returns (string memory) {
        require (msg.sender == _owner);
        return answers[f];
    }

    function addMoney() public payable {
        require(address(this).balance == 0);
        _amount += msg.value;
    }


    function() external payable { }

    function stop() public {
        require (msg.sender == _owner);
        selfdestruct(msg.sender);
    }

    function accept(address payable target) public payable {
        require(msg.sender == _owner);
        require(!paid[target]);
        require(Set.contains(workers, target));
        require(_current  < _total);
        paid[target] = true;
        _current ++;
        target.transfer(_amount / _total);
    }

    function reject(address payable target) public payable {
        require(msg.sender == _owner);
        require(!paid[target]);
        require(Set.contains(workers, target));
        require(_current  < _total);
        emit rejection(target);
        answers[target] = '';
    }

    function answer(string calldata ans) external {
        answers[msg.sender] = ans;
        workersArr.push(msg.sender);
        if (Set.insert(workers, msg.sender))
        {
            workerCount++;
        }
        emit toVerification(msg.sender);
    }

    function getWorkers(uint number) public view returns (address) {
        require(msg.sender == _owner);
        require(number < workerCount);
        return workersArr[number];
    }

    function getNumberOfWorkers() public view returns (uint) {
        require(msg.sender == _owner);
        return workerCount;
    }

    function isPaid(address a) public view returns (bool) {
        return paid[a];
    }

    function myPay() public view returns (bool) {
        return paid[msg.sender];
    }

    function myAnswer() public view returns (string memory) {
        if (address(this).balance == 0) return "";
        return answers[msg.sender];
    }
}



pragma solidity ^0.5.0;


contract CrdSet {
    Crowdsourcing[] public list;
    event newContract(Crowdsourcing indexed c);

    function createCC(uint total, string memory content) public payable returns (Crowdsourcing){
        require(address(this).balance == 0, "Amount of money need to be dividable by the total number of answers");
        Crowdsourcing a = new Crowdsourcing(msg.sender, total, content, msg.value);
        list.push(a);
        address(a).transfer(msg.value);
        emit newContract(a);
        return a;
    }

    function getContracCount() public view returns (uint) {
        return list.length;
    }

}
