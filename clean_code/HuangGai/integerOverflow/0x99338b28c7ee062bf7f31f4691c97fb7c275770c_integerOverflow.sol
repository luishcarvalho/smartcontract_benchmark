



pragma solidity 0.5.11;





library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {

        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {

        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;

        return c;
    }
}






contract Ownable {
    address payable public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);






    constructor() public {
        owner = msg.sender;
    }




    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }





    function transferOwnership(address payable newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}




contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}





contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}





contract BasicToken is ERC20Basic, Ownable {

    using SafeMath for uint256;

    mapping(address => uint256) balances;






    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);


        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);
        return true;
    }






    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

}









contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) allowed;







    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(allowed[_from][msg.sender] >= _value);
        require(balances[_from] >= _value);
        require(balances[_to].add(_value) > balances[_to]);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }






    function approve(address _spender, uint256 _value) public returns (bool) {




        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }







    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }







    function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);

        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);

        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}






contract Pausable is StandardToken {
    event Pause();
    event Unpause();

    bool public paused = false;

    address public founder;




    modifier whenNotPaused() {
        require(!paused || msg.sender == founder);
        _;
    }




    modifier whenPaused() {
        require(paused);
        _;
    }




    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }




    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}


contract PausableToken is Pausable {

    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }





    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }
}

contract ForsageToken is PausableToken {

    string public name;
    string public symbol;
    uint8 public decimals;




    constructor() public {
        name = "Forsage Coin";
        symbol = "FFI";
        decimals = 18;
        totalSupply = 100000000*10**18;

        founder = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;

        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function destroy() public onlyOwner{
        selfdestruct(owner);
    }
}




contract ForsageSale is Ownable {

    using SafeMath for uint256;

    address token;




    uint price;

    event TokensBought(address _buyer, uint256 _amount);

    event TokensSold(address _seller, uint256 _amount);

    constructor(address _token, uint256 _price) public {
        setToken(_token);
        setPrice(_price);
    }



    function buyTokens() payable public {
        require(msg.value>=getPrice(),'Tx value cannot be lower than price of 1 token');
        uint256 amount = msg.value.div(getPrice());
        ERC20 erc20 = ERC20(token);
        require(erc20.balanceOf(address(this))>=amount,"Sorry, token vendor does not possess enough tokens for this purchase");
        erc20.transfer(msg.sender,amount);
        emit TokensBought(msg.sender,amount);
    }





    function sellTokens(uint256 _amount) public {
        require(_amount>0,'You cannot sell 0 tokens');
        uint256 ethToSend = _amount.mul(getPrice());
        require(address(this).balance>=ethToSend,'Sorry, vendor does not possess enough Ether to trade for your tokens');
        ERC20 erc20 = ERC20(token);
        require(erc20.balanceOf(msg.sender)>=_amount,"You cannot sell more tokens than you own on your balance");
        require(erc20.allowance(msg.sender,address(this))>=_amount,"You need to allow this contract to transfer enough tokens from your account");
        erc20.transferFrom(msg.sender,address(this),_amount);
        msg.sender.transfer(ethToSend);
        emit TokensSold(msg.sender,_amount);
    }




    function setPrice(uint256 _price) public onlyOwner {
        require(_price>0);
        price = _price;
    }

    function getPrice() public view returns(uint256){
        return price;
    }





    function setToken(address _token) public onlyOwner {
        token = _token;
    }




    function getToken() public view returns(address){
        return token;
    }




    function refillEtherBalance() public payable onlyOwner{

    }

    function getSaleEtherBalance() public view onlyOwner returns(uint256){
        return address(this).balance;
    }




    function withdrawEther() public onlyOwner{
        owner.transfer(address(this).balance);
    }

    function getSaleTokenBalance() public view onlyOwner returns(uint256){
        ERC20 erc20 = ERC20(token);
        return erc20.balanceOf(address(this));
    }




    function withdrawTokens() public onlyOwner{
        ERC20 erc20 = ERC20(token);
        uint256 amount = erc20.balanceOf(address(this));
        erc20.transfer(owner,amount);
    }

    function destroy() public onlyOwner{
        selfdestruct(owner);
    }
}
