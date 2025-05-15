



pragma solidity ^0.4.19;

import "./open_zeppelin/StandardToken.sol";






contract Gate {
    ERC20Basic private TOKEN;
    address private PROXY;


    function Gate(ERC20Basic _token, address _proxy) public {
        TOKEN = _token;
        PROXY = _proxy;
    }




    function transferToProxy(uint256 _value) public {
        require(msg.sender == PROXY);

        require(TOKEN.transfer(PROXY, _value));
    }
}





















contract TokenProxy is StandardToken {

    ERC20Basic public TOKEN;

    mapping(address => address) private gates;


    event GateOpened(address indexed gate, address indexed user);

    event Minted(address indexed to, uint256 amount);

    event Burned(address indexed from, uint256 amount);

    function TokenProxy(ERC20Basic _token) public {
        TOKEN = _token;
    }

    function getGateAddress(address _user) external view returns (address) {
        return gates[_user];
    }


    function openGate() external {
        address user = msg.sender;


        require(gates[user] == 0);


        address gate = new Gate(TOKEN, this);


        gates[user] = gate;

        GateOpened(gate, user);
    }

    function transferFromGate() external {
        address user = msg.sender;

        address gate = gates[user];


        require(gate != 0);

        uint256 value = TOKEN.balanceOf(gate);

        Gate(gate).transferToProxy(value);



        totalSupply_ += value;
        balances[user] += value;

        Minted(user, value);
    }

    function withdraw(uint256 _value) external {
      withdrawTo(_value, msg.sender);
    }

    function withdrawTo(uint256 _value, address _destination) public {
        address user = msg.sender;
        uint256 balance = balances[user];
        require(_value <= balance);

        balances[user] = (balance - _value);
        totalSupply_ -= _value;

        TOKEN.transfer(_destination, _value);

        Burned(user, _value);
    }
}
