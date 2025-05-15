pragma solidity 0.5.11;

import "../../helpers/SafeMath.sol";
import "../../helpers/ISettings.sol";
import "../../helpers/IToken.sol";
import "../../helpers/IOracle.sol";
import "../../helpers/ILogic.sol";



contract Gate {
    using SafeMath for uint256;


    address public admin;


    uint256 public feePercentTMV;


    uint256 public feePercentETH;


    uint256 public minOrder;


    address payable public timviWallet;

    ISettings public settings;



    Order[] public orders;



    struct Order {
        address payable owner;
        uint256 amount;
    }


    event OrderCreated(uint256 id, address owner, uint256 tmv);


    event OrderCancelled(uint256 id, address owner, uint256 tmv);


    event OrderFilled(uint256 id, address owner, uint256 tmvTotal, uint256 tmvExecution, uint256 ethTotal, uint256 ethExecution);


    event OrderFilledPool(uint256 id, address owner, uint256 tmv, uint256 eth);


    event Converted(address owner, uint256 tmv, uint256 eth);


    event Funded(uint256 eth);


    event AdminChanged(address admin);

    event GateTmvFeeUpdated(uint256 value);
    event GateEthFeeUpdated(uint256 value);
    event GateMinOrderUpdated(uint256 value);
    event TimviWalletChanged(address wallet);
    event GateFundsWithdrawn(uint256 value);


    modifier onlyAdmin() {
        require(admin == msg.sender, "You have no access");
        _;
    }





    constructor(ISettings _settings) public {
        admin = msg.sender;
        timviWallet = msg.sender;
        settings = ISettings(_settings);

        feePercentTMV = 500;
        feePercentETH = 500;
        minOrder = 10 ** 18;

        emit GateTmvFeeUpdated(feePercentTMV);
        emit GateEthFeeUpdated(feePercentETH);
        emit GateMinOrderUpdated(minOrder);
        emit TimviWalletChanged(timviWallet);
        emit AdminChanged(admin);
    }


    function () external payable {
        emit Funded(msg.value);
    }


    function withdraw(address payable _beneficiary, uint256 _amount) external onlyAdmin {
        require(_beneficiary != address(0), "Zero address, be careful");
        require(address(this).balance >= _amount, "Insufficient funds");
        _beneficiary.transfer(_amount);
        emit GateFundsWithdrawn(_amount);
    }


    function setTmvFee(uint256 _value) external onlyAdmin {
        require(_value <= 10000, "Too much");
        feePercentTMV = _value;
        emit GateTmvFeeUpdated(_value);
    }


    function setEthFee(uint256 _value) external onlyAdmin {
        require(_value <= 10000, "Too much");
        feePercentETH = _value;
        emit GateEthFeeUpdated(_value);
    }


    function setMinOrder(uint256 _value) external onlyAdmin {

        require(_value <= 100 ether, "Too much");

        minOrder = _value;
        emit GateMinOrderUpdated(_value);
    }


    function setTimviWallet(address payable _wallet) external onlyAdmin {
        require(_wallet != address(0), "Zero address, be careful");

        timviWallet = _wallet;
        emit TimviWalletChanged(_wallet);
    }


    function changeAdmin(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0), "Zero address, be careful");
        admin = _newAdmin;
        emit AdminChanged(msg.sender);
    }

    function convert(uint256 _amount) external {
        require(_amount >= minOrder, "Too small amount");
        uint256 eth = tmv2eth(_amount);
        if (address(this).balance >= eth) {
            IToken(settings.tmvAddress()).transferFrom(msg.sender, timviWallet, _amount);
            msg.sender.transfer(eth);
            emit Converted(msg.sender, _amount, eth);
        } else {
            IToken(settings.tmvAddress()).transferFrom(msg.sender, address(this), _amount);
            uint256 id = orders.push(Order(msg.sender, _amount)).sub(1);
            emit OrderCreated(id, msg.sender, _amount);
        }
    }


    function cancel(uint256 _id) external {
        require(orders[_id].owner == msg.sender, "Order isn't your");

        uint256 tmv = orders[_id].amount;
        delete orders[_id];
        IToken(settings.tmvAddress()).transfer(msg.sender, tmv);
        emit OrderCancelled(_id, msg.sender, tmv);
    }


    function multiFill(uint256[] calldata _ids) external onlyAdmin() payable {

        emit Funded(msg.value);

        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 id = _ids[i];

            require(orders[id].owner != address(0), "Order doesn't exist");

            uint256 tmv = orders[id].amount;
            uint256 eth = tmv2eth(tmv);

            require(address(this).balance >= eth, "Not enough funds");

            address payable owner = orders[id].owner;
            delete orders[id];
            IToken(settings.tmvAddress()).transfer(timviWallet, tmv);
            owner.transfer(eth);
            emit OrderFilledPool(id, owner, tmv, eth);
        }
    }


    function fill(uint256 _id) external payable {
        require(orders[_id].owner != address(0), "Order doesn't exist");


        uint256 tmv = orders[_id].amount;
        address payable owner = orders[_id].owner;


        uint256 eth = tmv.mul(precision()).div(rate());

        require(msg.value >= eth, "Not enough funds");

        emit Funded(eth);


        uint256 tmvFee = tmv.mul(feePercentTMV).div(precision());
        uint256 ethFee = eth.mul(feePercentETH).div(precision());

        uint256 tmvExecution = tmv.sub(tmvFee);
        uint256 ethExecution = eth.sub(ethFee);


        delete orders[_id];


        owner.transfer(ethExecution);
        IToken(settings.tmvAddress()).transfer(msg.sender, tmvExecution);
        IToken(settings.tmvAddress()).transfer(timviWallet, tmvFee);


        msg.sender.transfer(msg.value.sub(eth));

        emit OrderFilled(_id, owner, tmv, tmvExecution, eth, ethExecution);
    }


    function rate() public view returns(uint256) {
        return IOracle(settings.oracleAddress()).ethUsdPrice();
    }


    function precision() public view returns(uint256) {
        return ILogic(settings.logicManager()).precision();
    }


    function tmv2eth(uint256 _amount) public view returns(uint256) {
        uint256 equivalent = _amount.mul(precision()).div(rate());
        return chargeFee(equivalent, feePercentETH);
    }


    function chargeFee(uint256 _amount, uint256 _percent) public view returns(uint256) {
        uint256 fee = _amount.mul(_percent).div(precision());
        return _amount.sub(fee);
    }
}
