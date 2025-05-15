






pragma solidity ^0.5.8;


contract IsContract {

    function ISCONTRACT505(address _target) internal view returns (bool) {
        if (_target == address(0)) {
            return false;
        }

        uint256 size;
        assembly { size := extcodesize(_target) }
        return size > 0;
    }
}






pragma solidity ^0.5.8;



contract ERC20 {
    function TOTALSUPPLY734() public view returns (uint256);

    function BALANCEOF87(address _who) public view returns (uint256);

    function ALLOWANCE217(address _owner, address _spender) public view returns (uint256);

    function TRANSFER438(address _to, uint256 _value) public returns (bool);

    function APPROVE791(address _spender, uint256 _value) public returns (bool);

    function TRANSFERFROM747(address _from, address _to, uint256 _value) public returns (bool);

    event TRANSFER133(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event APPROVAL808(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}






pragma solidity ^0.5.8;



library SafeERC20 {


    bytes4 private constant transfer_selector206 = 0xa9059cbb;


    function SAFETRANSFER7(ERC20 _token, address _to, uint256 _amount) internal returns (bool) {
        bytes memory transferCallData = abi.encodeWithSelector(
            transfer_selector206,
            _to,
            _amount
        );
        return INVOKEANDCHECKSUCCESS678(address(_token), transferCallData);
    }


    function SAFETRANSFERFROM771(ERC20 _token, address _from, address _to, uint256 _amount) internal returns (bool) {
        bytes memory transferFromCallData = abi.encodeWithSelector(
            _token.TRANSFERFROM747.selector,
            _from,
            _to,
            _amount
        );
        return INVOKEANDCHECKSUCCESS678(address(_token), transferFromCallData);
    }


    function SAFEAPPROVE557(ERC20 _token, address _spender, uint256 _amount) internal returns (bool) {
        bytes memory approveCallData = abi.encodeWithSelector(
            _token.APPROVE791.selector,
            _spender,
            _amount
        );
        return INVOKEANDCHECKSUCCESS678(address(_token), approveCallData);
    }

    function INVOKEANDCHECKSUCCESS678(address _addr, bytes memory _calldata) private returns (bool) {
        bool ret;
        assembly {
            let ptr := mload(0x40)

            let success := call(
                gas,
                _addr,
                0,
                add(_calldata, 0x20),
                mload(_calldata),
                ptr,
                0x20
            )

            if gt(success, 0) {

                switch returndatasize


                case 0 {
                    ret := 1
                }


                case 0x20 {


                    ret := eq(mload(ptr), 1)
                }


                default { }
            }
        }
        return ret;
    }
}



pragma solidity ^0.5.8;



interface ERC900 {
    event STAKED64(address indexed user, uint256 amount, uint256 total, bytes data);
    event UNSTAKED870(address indexed user, uint256 amount, uint256 total, bytes data);


    function STAKE84(uint256 _amount, bytes calldata _data) external;


    function STAKEFOR84(address _user, uint256 _amount, bytes calldata _data) external;


    function UNSTAKE238(uint256 _amount, bytes calldata _data) external;


    function TOTALSTAKEDFOR777(address _addr) external view returns (uint256);


    function TOTALSTAKED236() external view returns (uint256);


    function TOKEN451() external view returns (address);


    function SUPPORTSHISTORY821() external pure returns (bool);
}



pragma solidity ^0.5.0;

interface IUniswapExchange {
  event TOKENPURCHASE996(address indexed buyer, uint256 indexed eth_sold, uint256 indexed tokens_bought);
  event ETHPURCHASE686(address indexed buyer, uint256 indexed tokens_sold, uint256 indexed eth_bought);
  event ADDLIQUIDITY195(address indexed provider, uint256 indexed eth_amount, uint256 indexed token_amount);
  event REMOVELIQUIDITY507(address indexed provider, uint256 indexed eth_amount, uint256 indexed token_amount);


  function () external payable;


  function GETINPUTPRICE733(uint256 input_amount, uint256 input_reserve, uint256 output_reserve) external view returns (uint256);


  function GETOUTPUTPRICE452(uint256 output_amount, uint256 input_reserve, uint256 output_reserve) external view returns (uint256);



  function ETHTOTOKENSWAPINPUT342(uint256 min_tokens, uint256 deadline) external payable returns (uint256);


  function ETHTOTOKENTRANSFERINPUT323(uint256 min_tokens, uint256 deadline, address recipient) external payable returns(uint256);



  function ETHTOTOKENSWAPOUTPUT701(uint256 tokens_bought, uint256 deadline) external payable returns(uint256);

  function ETHTOTOKENTRANSFEROUTPUT693(uint256 tokens_bought, uint256 deadline, address recipient) external payable returns (uint256);


  function TOKENTOETHSWAPINPUT977(uint256 tokens_sold, uint256 min_eth, uint256 deadline) external returns (uint256);


  function TOKENTOETHTRANSFERINPUT18(uint256 tokens_sold, uint256 min_eth, uint256 deadline, address recipient) external returns (uint256);


  function TOKENTOETHSWAPOUTPUT664(uint256 eth_bought, uint256 max_tokens, uint256 deadline) external returns (uint256);


  function TOKENTOETHTRANSFEROUTPUT247(uint256 eth_bought, uint256 max_tokens, uint256 deadline, address recipient) external returns (uint256);


  function TOKENTOTOKENSWAPINPUT27(
    uint256 tokens_sold,
    uint256 min_tokens_bought,
    uint256 min_eth_bought,
    uint256 deadline,
    address token_addr)
    external returns (uint256);


  function TOKENTOTOKENTRANSFERINPUT278(
    uint256 tokens_sold,
    uint256 min_tokens_bought,
    uint256 min_eth_bought,
    uint256 deadline,
    address recipient,
    address token_addr)
    external returns (uint256);



  function TOKENTOTOKENSWAPOUTPUT751(
    uint256 tokens_bought,
    uint256 max_tokens_sold,
    uint256 max_eth_sold,
    uint256 deadline,
    address token_addr)
    external returns (uint256);


  function TOKENTOTOKENTRANSFEROUTPUT428(
    uint256 tokens_bought,
    uint256 max_tokens_sold,
    uint256 max_eth_sold,
    uint256 deadline,
    address recipient,
    address token_addr)
    external returns (uint256);


  function TOKENTOEXCHANGESWAPINPUT174(
    uint256 tokens_sold,
    uint256 min_tokens_bought,
    uint256 min_eth_bought,
    uint256 deadline,
    address exchange_addr)
    external returns (uint256);


  function TOKENTOEXCHANGETRANSFERINPUT767(
    uint256 tokens_sold,
    uint256 min_tokens_bought,
    uint256 min_eth_bought,
    uint256 deadline,
    address recipient,
    address exchange_addr)
    external returns (uint256);


  function TOKENTOEXCHANGESWAPOUTPUT918(
    uint256 tokens_bought,
    uint256 max_tokens_sold,
    uint256 max_eth_sold,
    uint256 deadline,
    address exchange_addr)
    external returns (uint256);


  function TOKENTOEXCHANGETRANSFEROUTPUT147(
    uint256 tokens_bought,
    uint256 max_tokens_sold,
    uint256 max_eth_sold,
    uint256 deadline,
    address recipient,
    address exchange_addr)
    external returns (uint256);





  function GETETHTOTOKENINPUTPRICE69(uint256 eth_sold) external view returns (uint256);


  function GETETHTOTOKENOUTPUTPRICE555(uint256 tokens_bought) external view returns (uint256);


  function GETTOKENTOETHINPUTPRICE162(uint256 tokens_sold) external view returns (uint256);


  function GETTOKENTOETHOUTPUTPRICE369(uint256 eth_bought) external view returns (uint256);


  function TOKENADDRESS963() external view returns (address);


  function FACTORYADDRESS389() external view returns (address);





  function ADDLIQUIDITY566(uint256 min_liquidity, uint256 max_tokens, uint256 deadline) external payable returns (uint256);


  function REMOVELIQUIDITY718(uint256 amount, uint256 min_eth, uint256 min_tokens, uint256 deadline) external returns (uint256, uint256);
}



pragma solidity ^0.5.0;

interface IUniswapFactory {
  event NEWEXCHANGE290(address indexed token, address indexed exchange);

  function INITIALIZEFACTORY19(address template) external;
  function CREATEEXCHANGE596(address token) external returns (address payable);
  function GETEXCHANGE730(address token) external view returns (address payable);
  function GETTOKEN772(address token) external view returns (address);
  function GETTOKENWIHID451(uint256 token_id) external view returns (address);
}



pragma solidity ^0.5.8;




contract Refundable {
    using SafeERC20 for ERC20;

    string private constant error_not_governor455 = "REF_NOT_GOVERNOR";
    string private constant error_zero_amount252 = "REF_ZERO_AMOUNT";
    string private constant error_not_enough_balance862 = "REF_NOT_ENOUGH_BALANCE";
    string private constant error_eth_refund150 = "REF_ETH_REFUND";
    string private constant error_token_refund409 = "REF_TOKEN_REFUND";

    address public governor;

    modifier ONLYGOVERNOR318() {
        require(msg.sender == governor, error_not_governor455);
        _;
    }

    constructor(address _governor) public {
        governor = _governor;
    }


    function REFUNDETH646(address payable _recipient, uint256 _amount) external ONLYGOVERNOR318 {
        require(_amount > 0, error_zero_amount252);
        uint256 selfBalance = address(this).balance;
        require(selfBalance >= _amount, error_not_enough_balance862);


        (bool result,) = _recipient.call.value(_amount)("");
        require(result, error_eth_refund150);
    }


    function REFUNDTOKEN5(ERC20 _token, address _recipient, uint256 _amount) external ONLYGOVERNOR318 {
        require(_amount > 0, error_zero_amount252);
        uint256 selfBalance = _token.BALANCEOF87(address(this));
        require(selfBalance >= _amount, error_not_enough_balance862);

        require(_token.SAFETRANSFER7(_recipient, _amount), error_token_refund409);
    }
}



pragma solidity ^0.5.8;









contract UniswapWrapper is Refundable, IsContract {
    using SafeERC20 for ERC20;

    string private constant error_token_not_contract383 = "UW_TOKEN_NOT_CONTRACT";
    string private constant error_registry_not_contract179 = "UW_REGISTRY_NOT_CONTRACT";
    string private constant error_uniswap_factory_not_contract907 = "UW_UNISWAP_FACTORY_NOT_CONTRACT";
    string private constant error_received_wrong_token364 = "UW_RECEIVED_WRONG_TOKEN";
    string private constant error_wrong_data_length344 = "UW_WRONG_DATA_LENGTH";
    string private constant error_zero_amount252 = "UW_ZERO_AMOUNT";
    string private constant error_token_transfer_failed211 = "UW_TOKEN_TRANSFER_FAILED";
    string private constant error_token_approval_failed944 = "UW_TOKEN_APPROVAL_FAILED";
    string private constant error_uniswap_unavailable264 = "UW_UNISWAP_UNAVAILABLE";

    bytes32 internal constant activate_data805 = keccak256("activate(uint256)");

    ERC20 public bondedToken;
    ERC900 public registry;
    IUniswapFactory public uniswapFactory;

    constructor(address _governor, ERC20 _bondedToken, ERC900 _registry, IUniswapFactory _uniswapFactory) Refundable(_governor) public {
        require(ISCONTRACT505(address(_bondedToken)), error_token_not_contract383);
        require(ISCONTRACT505(address(_registry)), error_registry_not_contract179);
        require(ISCONTRACT505(address(_uniswapFactory)), error_uniswap_factory_not_contract907);

        bondedToken = _bondedToken;
        registry = _registry;
        uniswapFactory = _uniswapFactory;
    }


    function RECEIVEAPPROVAL744(address _from, uint256 _amount, address _token, bytes calldata _data) external {
        require(_token == msg.sender, error_received_wrong_token364);

        require(_data.length == 128, error_wrong_data_length344);

        bool activate;
        uint256 minTokens;
        uint256 minEth;
        uint256 deadline;
        bytes memory data = _data;
        assembly {
            activate := mload(add(data, 0x20))
            minTokens := mload(add(data, 0x40))
            minEth := mload(add(data, 0x60))
            deadline := mload(add(data, 0x80))
        }

        _CONTRIBUTEEXTERNALTOKEN25(_from, _amount, _token, minTokens, minEth, deadline, activate);
    }


    function CONTRIBUTEEXTERNALTOKEN307(
        uint256 _amount,
        address _token,
        uint256 _minTokens,
        uint256 _minEth,
        uint256 _deadline,
        bool _activate
    )
        external
    {
        _CONTRIBUTEEXTERNALTOKEN25(msg.sender, _amount, _token, _minTokens, _minEth, _deadline, _activate);
    }


    function CONTRIBUTEETH468(uint256 _minTokens, uint256 _deadline, bool _activate) external payable {
        require(msg.value > 0, error_zero_amount252);


        address payable uniswapExchangeAddress = uniswapFactory.GETEXCHANGE730(address(bondedToken));
        require(uniswapExchangeAddress != address(0), error_uniswap_unavailable264);
        IUniswapExchange uniswapExchange = IUniswapExchange(uniswapExchangeAddress);


        uint256 bondedTokenAmount = uniswapExchange.ETHTOTOKENSWAPINPUT342.value(msg.value)(_minTokens, _deadline);


        _STAKEANDACTIVATE532(msg.sender, bondedTokenAmount, _activate);
    }

    function _CONTRIBUTEEXTERNALTOKEN25(
        address _from,
        uint256 _amount,
        address _token,
        uint256 _minTokens,
        uint256 _minEth,
        uint256 _deadline,
        bool _activate
    )
        internal
    {
        require(_amount > 0, error_zero_amount252);


        ERC20 token = ERC20(_token);
        require(token.SAFETRANSFERFROM771(_from, address(this), _amount), error_token_transfer_failed211);


        address payable uniswapExchangeAddress = uniswapFactory.GETEXCHANGE730(_token);
        require(uniswapExchangeAddress != address(0), error_uniswap_unavailable264);
        IUniswapExchange uniswapExchange = IUniswapExchange(uniswapExchangeAddress);

        require(token.SAFEAPPROVE557(address(uniswapExchange), _amount), error_token_approval_failed944);


        uint256 bondedTokenAmount = uniswapExchange.TOKENTOTOKENSWAPINPUT27(_amount, _minTokens, _minEth, _deadline, address(bondedToken));


        _STAKEANDACTIVATE532(_from, bondedTokenAmount, _activate);
    }

    function _STAKEANDACTIVATE532(address _from, uint256 _amount, bool _activate) internal {

        bondedToken.APPROVE791(address(registry), _amount);
        bytes memory data;
        if (_activate) {
            data = abi.encodePacked(activate_data805);
        }
        registry.STAKEFOR84(_from, _amount, data);
    }
}
