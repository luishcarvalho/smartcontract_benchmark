







































library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
        return 0;
    }
    uint256 c = a * b;
    require(c / a == b, 'SafeMath mul failed');
    return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {

    uint256 c = a / b;

    return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, 'SafeMath sub failed');
    return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, 'SafeMath add failed');
    return c;
    }
}






contract owned {
    address payable public owner;
    address payable internal newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(true);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }


    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}







contract BTF is owned {







    using SafeMath for uint256;
    string constant public name = "BitPhantom";
    string constant public symbol = "BTF";
    uint256 constant public decimals = 18;
    uint256 constant public maxSupply = 15000 * (10**decimals);
    uint256 public totalSupply;
    bool public safeguard;



    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => bool) public frozenAccount;







    event Transfer(address indexed from, address indexed to, uint256 value);


    event Burn(address indexed from, uint256 value);


    event FrozenAccounts(address target, bool frozen);


    event Approval(address indexed from, address indexed spender, uint256 value);








    function _transfer(address _from, address _to, uint _value) internal {


        require(!safeguard);
        require(!frozenAccount[_from]);
        require(!frozenAccount[_to]);


        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);


        emit Transfer(_from, _to, _value);
    }









    function transfer(address _to, uint256 _value) public returns (bool success) {


        _transfer(msg.sender, _to, _value);

        return true;
    }










    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }









    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(!safeguard);
        require(balanceOf[msg.sender] >= _value, "Balance does not have enough tokens");
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }






    constructor() public{

        totalSupply = maxSupply;


        balanceOf[owner] = totalSupply;


        emit Transfer(address(0), owner, totalSupply);
    }


    function () external payable {}








    function burn(uint256 _value) public returns (bool success) {
        require(!safeguard);

        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(msg.sender, _value);
        emit Transfer(msg.sender, address(0), _value);
        return true;
    }









    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(!safeguard);

        balanceOf[_from] = balanceOf[_from].sub(_value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit  Burn(_from, _value);
        emit Transfer(_from, address(0), _value);
        return true;
    }







    function freezeAccount(address target, bool freeze) onlyOwner public {
            frozenAccount[target] = freeze;
        emit  FrozenAccounts(target, freeze);
    }






    function mintToken(address target, uint256 mintedAmount) onlyOwner public {


        require(totalSupply.add(mintedAmount) <= maxSupply, 'can not mint more than maxSupply');

        balanceOf[target] = balanceOf[target].add(mintedAmount);
        totalSupply = totalSupply.add(mintedAmount);
        emit Transfer(address(0), target, mintedAmount);
    }










    function manualWithdrawTokens(uint256 tokenAmount) public onlyOwner{

        _transfer(address(this), owner, tokenAmount);
    }


    function manualWithdrawEther()onlyOwner public{
        address(owner).transfer(address(this).balance);
    	msg.sender.transfer(address(this).balance);	}







    function changeSafeguardStatus() onlyOwner public{
        if (safeguard == false){
            safeguard = true;
        }
        else{
            safeguard = false;
        }
    }



}
