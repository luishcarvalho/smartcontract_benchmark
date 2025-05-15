

pragma solidity ^0.8.0;

import "../interfaces/IERC20Permit.sol";




abstract contract ERC20Permit is IERC20Permit {


    string public name;

    string public override symbol;

    uint8 public override decimals;


    mapping(address => uint256) public override balanceOf;

    mapping(address => mapping(address => uint256)) public override allowance;

    mapping(address => uint256) public override nonces;



    bytes32 public override DOMAIN_SEPARATOR;

    bytes32
        public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;






    constructor(string memory name_, string memory symbol_) {

        name = name_;
        symbol = symbol_;
        decimals = 18;






        balanceOf[address(0)] = type(uint256).max;
        balanceOf[address(this)] = type(uint256).max;




        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }







    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {

        return transferFrom(msg.sender, recipient, amount);
    }







    function transferFrom(
        address spender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {

        uint256 balance = balanceOf[spender];
        require(balance >= amount, "ERC20: insufficient-balance");

        if (spender != msg.sender) {


            uint256 allowed = allowance[spender][msg.sender];



            if (allowed != type(uint256).max) {
                require(allowed >= amount, "ERC20: insufficient-allowance");
                allowance[spender][msg.sender] = allowed - amount;
            }
        }

        balanceOf[spender] = balance - amount;



        balanceOf[recipient] = balanceOf[recipient] + amount;

        emit Transfer(spender, recipient, amount);

        return true;
    }








    function _mint(address account, uint256 amount) internal virtual {

        balanceOf[account] = balanceOf[account] + amount;

        emit Transfer(address(0), account, amount);
    }








    function _burn(address account, uint256 amount) internal virtual {

        balanceOf[account] = balanceOf[account] - amount;

        emit Transfer(account, address(0), amount);
    }






    function approve(address account, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {

        allowance[msg.sender][account] = amount;

        emit Approval(msg.sender, account, amount);
        return true;
    }













    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        owner,
                        spender,
                        value,
                        nonces[owner],
                        deadline
                    )
                )
            )
        );

        require(owner != address(0), "ERC20: invalid-address-0");


        require(owner == ecrecover(digest, v, r, s), "ERC20: invalid-permit");

        require(
            deadline == 0 || block.timestamp <= deadline,
            "ERC20: permit-expired"
        );

        nonces[owner]++;

        allowance[owner][spender] = value;

        emit Approval(owner, spender, value);
    }



    function _setupDecimals(uint8 decimals_) internal {

        decimals = decimals_;
    }
}
