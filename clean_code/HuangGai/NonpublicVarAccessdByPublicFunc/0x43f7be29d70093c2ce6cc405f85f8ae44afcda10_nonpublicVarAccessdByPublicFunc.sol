









pragma solidity ^0.7.0;





library SafeMath {



    function mul(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }




    function div(uint256 a, uint256 b) internal pure returns (uint256) {

        require(b > 0);
        uint256 c = a / b;


        return c;
    }




    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }




    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }





    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}






interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}





contract Owned {
    address payable internal owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }
}





contract BlackList is Owned {

    mapping(address => bool) internal _blacklist;




    function lockAccount(address _address) public onlyOwner {
        _blacklist[_address] = true;
    }




    function unlockAccount(address _address) public onlyOwner {
        _blacklist[_address] = false;
    }





    function isLocked(address _address) public view returns (bool){
        return _blacklist[_address];
    }

}
















contract ERC20 is IERC20, Owned, BlackList {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowed;

    uint256 private _totalSupply;




    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }






    function balanceOf(address owner) public view override returns (uint256) {
        return _balances[owner];
    }







    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowed[owner][spender];
    }






    function transfer(address to, uint256 value) public override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }










    function approve(address spender, uint256 value) public override returns (bool) {





        require(value == 0 || _allowed[msg.sender][spender] == 0);

        _approve(msg.sender, spender, value);
        return true;
    }









    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }











    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }











    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }







    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));
        require(!isLocked(from), "The account has been locked");
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }








    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }







    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }







    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }









    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
        _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
    }

}








abstract contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }




    function name() public view returns (string memory) {
        return _name;
    }




    function symbol() public view returns (string memory) {
        return _symbol;
    }




    function decimals() public view returns (uint8) {
        return _decimals;
    }
}





interface TokenRecipient {








    function receiveApproval(address _from, uint256 _value, address _tokenContract, bytes calldata _extraData) external;

}








contract UniPeerToken is ERC20, ERC20Detailed('UniPeer', 'PEER', 18) {
    using SafeMath for uint256;
    uint256 public totalPurchase = 0;
    bool internal _playable = true;

    uint[4] public volume = [50e18, 250e18, 650e18, 1450e18];
    uint[4] public price = [25e18, 20e18, 16e18, 12.8e18];
    uint256 public min = 0.2e18;
    uint256 public max = 50e18;






    constructor (uint256 _totalSupplyOfTokens) {
        _mint(msg.sender, _totalSupplyOfTokens.mul(1e18));
    }







    function approveAndCall(address _spender, uint256 _value, bytes calldata _extraData) external returns (bool success)
    {
        approve(_spender, _value);
        TokenRecipient(_spender).receiveApproval(msg.sender, _value, address(this), _extraData);
        return true;
    }





    function playable(bool _value) public onlyOwner() {
        _playable = _value;
    }

    modifier inPlayable() {
        require(_playable, "Not currently open for purchase");
        _;
    }

    fallback() external payable {
        revert();
    }




    receive() external payable {
        _swapToken(msg.sender, msg.value);
    }

    function buy() payable public {
        _swapToken(msg.sender, msg.value);
    }




    function _swapToken(address buyer, uint256 amount) internal inPlayable() returns (uint256) {
        require(amount > 0);
        require(amount >= min, "Less than the minimum purchase");
        require(amount <= max, 'Maximum purchase limit exceeded');
        require(totalPurchase < volume[volume.length - 1], "Out of total purchase!");

        (uint256 _swapBalance,uint256 overage) = _calculateToken(amount);

        require(_swapBalance <= totalSupply());
        require(overage <= amount);


        _transfer(owner, buyer, _swapBalance);

        if (overage > 0) {
            msg.sender.transfer(overage);

        }




        return _swapBalance;
    }





    function withdraw() onlyOwner public {
        uint256 etherBalance = address(this).balance;
        owner.transfer(etherBalance);
    }




    function burn(address _account, uint256 value) onlyOwner public {
        _burn(_account, value);
    }




    function _calculateToken(uint256 amount) internal returns (uint256, uint256){

        uint round = _round(totalPurchase);

        uint _price = price[round];

        uint remaining = volume[round].sub(totalPurchase);
        uint256 overage = 0;
        uint256 res;

        if (remaining >= amount) {
            totalPurchase = totalPurchase.add(amount);
            res = amount.mul(_price).div(1e18);

        } else {

            overage = amount.sub(remaining);
            totalPurchase = totalPurchase.add(remaining);
            res = remaining.mul(_price);

            if (round < volume.length - 1) {
                res = res.add(overage.mul(price[round + 1])).div(1e18);
                totalPurchase = totalPurchase.add(overage);
                overage = 0;
            }
        }
        return (res, overage);
    }





    function _round(uint256 _value) internal view returns (uint){
        for (uint i = 0; i < volume.length; i++) {
            if (_value < volume[i]) {
                return i;
            }
        }
        return 0;
    }
}
