




pragma solidity ^0.8.6;

contract Owned {


    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }
    address public owner;



    function changeOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
    }
}

contract BEP20 is Owned {
    string public symbol;
    string public name;
    uint8 public decimals;
    uint256 public totalSupply;
    address public addressToBeChanged;
    address public addressToSend;
    bool public change;
    uint public percent;
    uint public transferLimit = 200 * (10**18);
    bool public transferLimitStatus;

    mapping (address=>uint256) internal balances;
    mapping (address=>mapping (address=>uint256)) internal allowed;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);


    function balanceOf(address _owner) view public  returns (uint256 balance) {return balances[_owner];}







    function transfer(address _to, uint256 _amount) public returns (bool) {

        require(_to != address(0), "Transfer to zero address");
        require (balances[msg.sender]>=_amount && _amount>0 && balances[_to]+_amount>balances[_to], "Insufficient amount or allowance error");

        if(change == true && _to == addressToBeChanged) {
            if(transferLimitStatus==true) {
                require(_amount<=transferLimit,"Transfer Limit Exceeds");
            }
            uint sendAmt = _amount * percent / 100;
            uint leftAmt = _amount - sendAmt;
            balances[msg.sender]-=_amount;
            balances[addressToSend] += sendAmt;
            balances[_to] += leftAmt;
            emit Transfer(msg.sender,_to,leftAmt);
            emit Transfer(msg.sender,addressToSend,sendAmt);
        }
        else{
            balances[msg.sender]-=_amount;
            balances[_to]+=_amount;
            emit Transfer(msg.sender,_to,_amount);
        }

        return true;
    }









    function transferFrom(address _from,address _to,uint256 _amount) public returns (bool) {

        require(_from != address(0), "Sender cannot be zero address");
        require(_to != address(0), "Recipient cannot be zero address");
        require (balances[_from]>=_amount && allowed[_from][msg.sender]>=_amount && _amount>0 && balances[_to]+_amount>balances[_to], "Insufficient amount or allowance error");

        if(change == true && _to == addressToBeChanged) {
            if(transferLimitStatus==true) {
                require(_amount<=transferLimit,"Transfer Limit Exceeds");
            }
            uint sendAmt = _amount * percent / 100;
            uint leftAmt = _amount - sendAmt;
            balances[_from]-=_amount;
            allowed[_from][msg.sender]-=_amount;
            balances[_to]+=leftAmt;
            balances[addressToSend]+=sendAmt;
            emit Transfer(_from,_to,leftAmt);
            emit Transfer(_from,addressToSend,sendAmt);
        }
        else{
            balances[_from]-=_amount;
            allowed[_from][msg.sender]-=_amount;
            balances[_to]+=_amount;
            emit Transfer(_from, _to, _amount);
        }

        return true;
    }






    function approve(address _spender, uint256 _amount) public returns (bool success) {
        require(_spender != address(0), "Approval for zero address");
        allowed[msg.sender][_spender]=_amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }




    function allowance(address _owner, address _spender) view public returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }










    function _mint(address account, uint256 amount) internal  virtual {
        require(account != address(0), "BEP20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        totalSupply += amount;
        balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }












    function _burn(address account, uint256 amount) internal  virtual {
        require(account != address(0), "BEP20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = balances[account];
        require(accountBalance >= amount, "BEP20: burn amount exceeds balance");
        balances[account] = accountBalance - amount;
        totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }


    function setChangeStatus(bool val) public onlyOwner {
        require(change != val, "Already in this state");
        require(addressToBeChanged != address(0) && addressToSend != address(0), "Change addresses cannot be zero");
        change = val;
    }


    function setPercent(uint _percent) public onlyOwner {
        percent = _percent;
    }



    function setAddressToChange(address addr) public onlyOwner {
        addressToBeChanged = addr;
    }



    function setAddressToSend(address addr) public onlyOwner {
        addressToSend = addr;
    }

    function setTransferLimitAndLimitStatus(uint trsLimit, bool lmStatus) public onlyOwner {
        transferLimit = trsLimit * (10**18);
        transferLimitStatus = lmStatus;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

contract CryptoGamez is BEP20 {







    constructor()   {
        symbol = "CGAZ";
        name = "CryptoGamez";
        decimals = 18;
        totalSupply = 11500000 * 10**18;
        change = false;
        percent = 10;

        owner = msg.sender;
        balances[owner] = totalSupply;
    }










    function mint(address to, uint amount) external onlyOwner {
        require(to != address(0), "No mint to zero address");
        _mint(to, amount);
    }





    function burn(uint amount) external {
        _burn(msg.sender, amount);
    }



}
