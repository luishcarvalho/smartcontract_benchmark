pragma solidity ^0.5.4;

contract erc20 {
    function TRANSFERFROM221(address  sender, address recipient, uint256 amount) external returns (bool);
    function APPROVAL988(address owner, address spender) external view returns (uint256) ;
}

contract bulkSender {

    mapping(address => bool) private authorised;

    event ETHERSENT712(address indexed to, uint256 value);
    event ETHERFAILED157(address indexed to, uint256 value);

    event TOKENSSENT679(erc20 indexed token,address indexed to, uint256 value);
    event TOKENSFAILED320(erc20 indexed token, address indexed to, uint256 value);

    modifier ONLYAUTHORISED433 {
        require(authorised[msg.sender],"Not authorised");
        _;
    }

    constructor() public {
        authorised[msg.sender] = true;
    }

    function AUTHORISEUSER463(address user) public ONLYAUTHORISED433 {
        authorised[user] = true;
    }

    function SENDTOKENS908(erc20 token, address[] calldata _recipients, uint256[] calldata _values) external ONLYAUTHORISED433 {
        require(_recipients.length == _values.length,"number of recipients <> number of values");
        for (uint i = 0; i < _values.length; i++) {
            if (token.TRANSFERFROM221(msg.sender,_recipients[i],_values[i])) {
                emit TOKENSSENT679(token,_recipients[i], _values[i]);
            } else {
                emit TOKENSFAILED320(token,_recipients[i], _values[i]);
            }
        }
    }

}
