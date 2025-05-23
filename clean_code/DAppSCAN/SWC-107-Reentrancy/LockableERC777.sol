pragma solidity ^0.5.3;

import "@openzeppelin/contracts/token/ERC777/IERC777.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Sender.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/introspection/IERC1820Registry.sol";






contract LockableERC777 is IERC777, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    IERC1820Registry private _erc1820 = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    mapping(address => uint256) private _balances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;





    bytes32 constant private TOKENS_SENDER_INTERFACE_HASH = 0x29ddb589b1fb5fc7cf394961c1adf5f8c6454761adf795e67fe149f658abe895;


    bytes32 constant private TOKENS_RECIPIENT_INTERFACE_HASH = 0xb281fc8c12954d22544db45de3159a39272895b169a852b314f9cc762e44c53b;


    address[] private _defaultOperatorsArray;


    mapping(address => bool) private _defaultOperators;


    mapping(address => mapping(address => bool)) private _operators;
    mapping(address => mapping(address => bool)) private _revokedDefaultOperators;


    mapping (address => mapping (address => uint256)) private _allowances;




    constructor(
        string memory name,
        string memory symbol,
        address[] memory defaultOperators
    ) public {
        _name = name;
        _symbol = symbol;

        _defaultOperatorsArray = defaultOperators;
        for (uint256 i = 0; i < _defaultOperatorsArray.length; i++) {
            _defaultOperators[_defaultOperatorsArray[i]] = true;
        }


        _erc1820.setInterfaceImplementer(address(this), keccak256("ERC777Token"), address(this));
        _erc1820.setInterfaceImplementer(address(this), keccak256("ERC20Token"), address(this));
    }






    function send(address recipient, uint256 amount, bytes calldata data) external {
        _send(
            msg.sender, msg.sender, recipient, amount, data, "", true
        );
    }









    function transfer(address recipient, uint256 amount) external returns (bool) {
        require(recipient != address(0), "ERC777: transfer to the zero address");

        address from = msg.sender;

        _callTokensToSend(
            from, from, recipient, amount, "", ""
        );

        _move(
            from, from, recipient, amount, "", ""
        );

        _callTokensReceived(
            from, from, recipient, amount, "", "", false
        );

        return true;
    }






    function burn(uint256 amount, bytes calldata data) external {
        _burn(
            msg.sender, msg.sender, amount, data, ""
        );
    }




    function authorizeOperator(address operator) external {
        require(msg.sender != operator, "ERC777: authorizing self as operator");

        if (_defaultOperators[operator]) {
            delete _revokedDefaultOperators[msg.sender][operator];
        } else {
            _operators[msg.sender][operator] = true;
        }

        emit AuthorizedOperator(operator, msg.sender);
    }




    function revokeOperator(address operator) external {
        require(operator != msg.sender, "ERC777: revoking self as operator");

        if (_defaultOperators[operator]) {
            _revokedDefaultOperators[msg.sender][operator] = true;
        } else {
            delete _operators[msg.sender][operator];
        }

        emit RevokedOperator(operator, msg.sender);
    }






    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    )
    external
    {
        require(isOperatorFor(msg.sender, sender), "ERC777: caller is not an operator for holder");
        _send(
            msg.sender, sender, recipient, amount, data, operatorData, true
        );
    }






    function operatorBurn(
        address account, uint256 amount, bytes calldata data, bytes calldata operatorData
    ) external
    {
        require(isOperatorFor(msg.sender, account), "ERC777: caller is not an operator for holder");
        _burn(
            msg.sender, account, amount, data, operatorData
        );
    }






    function approve(address spender, uint256 value) external returns (bool) {
        address holder = msg.sender;
        _approve(holder, spender, value);
        return true;
    }










    function transferFrom(address holder, address recipient, uint256 amount) external returns (bool) {
        require(recipient != address(0), "ERC777: transfer to the zero address");
        require(holder != address(0), "ERC777: transfer from the zero address");

        address spender = msg.sender;

        _callTokensToSend(
            spender, holder, recipient, amount, "", ""
        );

        _move(
            spender, holder, recipient, amount, "", ""
        );
        _approve(holder, spender, _allowances[holder][spender].sub(amount));

        _callTokensReceived(
            spender, holder, recipient, amount, "", "", false
        );

        return true;
    }




    function name() public view returns (string memory) {
        return _name;
    }




    function symbol() public view returns (string memory) {
        return _symbol;
    }







    function decimals() public pure returns (uint8) {
        return 18;
    }






    function granularity() public view returns (uint256) {
        return 1;
    }




    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }




    function balanceOf(address tokenHolder) public view returns (uint256) {
        return _balances[tokenHolder];
    }




    function isOperatorFor(
        address operator,
        address tokenHolder
    ) public view returns (bool)
    {
        return operator == tokenHolder ||
            (_defaultOperators[operator] && !_revokedDefaultOperators[tokenHolder][operator]) ||
            _operators[tokenHolder][operator];
    }




    function defaultOperators() public view returns (address[] memory) {
        return _defaultOperatorsArray;
    }








    function allowance(address holder, address spender) public view returns (uint256) {
        return _allowances[holder][spender];
    }


















    function _mint(
        address operator,
        address account,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    )
    internal
    {
        require(account != address(0), "ERC777: mint to the zero address");


        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);

        _callTokensReceived(
            operator, address(0), account, amount, userData, operatorData, true
        );

        emit Minted(
            operator, account, amount, userData, operatorData
        );
        emit Transfer(address(0), account, amount);
    }


    function _getLockedOf(address wallet) internal returns (uint);












    function _send(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData,
        bool requireReceptionAck
    )
        private
    {
        require(from != address(0), "ERC777: send from the zero address");
        require(to != address(0), "ERC777: send to the zero address");

        _callTokensToSend(
            operator, from, to, amount, userData, operatorData
        );

        _move(
            operator, from, to, amount, userData, operatorData
        );

        _callTokensReceived(
            operator, from, to, amount, userData, operatorData, requireReceptionAck
        );
    }










    function _burn(
        address operator,
        address from,
        uint256 amount,
        bytes memory data,
        bytes memory operatorData
    )
        private
    {
        require(from != address(0), "ERC777: burn from the zero address");

        _callTokensToSend(
            operator, from, address(0), amount, data, operatorData
        );


        _totalSupply = _totalSupply.sub(amount);
        _balances[from] = _balances[from].sub(amount);

        emit Burned(
            operator, from, amount, data, operatorData
        );
        emit Transfer(from, address(0), amount);
    }

    function _move(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    )
        private
    {

        uint locked = _getLockedOf(from);
        if (locked > 0) {
            require(_balances[from] >= locked + amount, "Token should be unlocked for transferring");
        }

        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amount);

        emit Sent(
            operator, from, to, amount, userData, operatorData
        );
        emit Transfer(from, to, amount);
    }

    function _approve(address holder, address spender, uint256 value) private {



        require(spender != address(0), "ERC777: approve to the zero address");

        _allowances[holder][spender] = value;
        emit Approval(holder, spender, value);
    }










    function _callTokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    )
        private
    {
        address implementer = _erc1820.getInterfaceImplementer(from, TOKENS_SENDER_INTERFACE_HASH);
        if (implementer != address(0)) {
            IERC777Sender(implementer).tokensToSend(
                operator, from, to, amount, userData, operatorData
            );
        }
    }












    function _callTokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData,
        bool requireReceptionAck
    )
        private
    {
        address implementer = _erc1820.getInterfaceImplementer(to, TOKENS_RECIPIENT_INTERFACE_HASH);
        if (implementer != address(0)) {
            IERC777Recipient(implementer).tokensReceived(
                operator, from, to, amount, userData, operatorData
            );
        } else if (requireReceptionAck) {
            require(!to.isContract(), "Token recipient contract has no implementer for ERC777TokensRecipient");
        }
    }
}
