pragma solidity 0.5.11;

import "../../helpers/SafeMath.sol";
import "../../helpers/ISettings.sol";
import "../../helpers/IToken.sol";
import "../../helpers/ILogic.sol";



contract LeverageService {
    using SafeMath for uint256;


    address public admin;


    uint256 public systemETH;


    uint256 public commission;


    uint256 public divider = 100000;


    uint256 public minEther;

    ISettings public settings;



    Bid[] public bids;



    struct Bid {
        address payable owner;
        uint256         pack;
        uint256         percent;
    }


    event BidCreated(uint256 id, address owner, uint256 pack, uint256 percent);


    event BidClosed(uint256 id, address who);


    event BidMatched(uint256 id, uint256 tBox, address who, address owner);

    event LeverageFeeUpdated(uint256 _value);
    event LeverageMinEtherUpdated(uint256 _value);


    modifier onlyAdmin() {
        require(admin == msg.sender, "You have no access");
        _;
    }


    modifier onlyOwner(uint256 _id) {
        require(bids[_id].owner == msg.sender, "Bid isn't your");
        _;
    }

    modifier onlyExists(uint256 _id) {
        require(bids[_id].owner != address(0), "Bid doesn't exist");
        _;
    }





    constructor(ISettings _settings) public {
        admin = msg.sender;
        settings = ISettings(_settings);

        commission = 500;
        emit LeverageFeeUpdated(commission);

        minEther = 1 ether;
        emit LeverageMinEtherUpdated(minEther);
    }


    function withdrawSystemETH(address payable _beneficiary) external onlyAdmin {
        require(_beneficiary != address(0), "Zero address, be careful");
        require(systemETH > 0, "There is no available ETH");

        uint256 _systemETH = systemETH;
        systemETH = 0;
        _beneficiary.transfer(_systemETH);
    }


    function reclaimERC20(address _token, address _beneficiary) external onlyAdmin {
        require(_beneficiary != address(0), "Zero address, be careful");

        uint256 _amount = IToken(_token).balanceOf(address(this));
        require(_amount > 0, "There are no tokens");
        IToken(_token).transfer(_beneficiary, _amount);
    }


    function setCommission(uint256 _value) external onlyAdmin {
        require(_value <= 10000, "Too much");
        commission = _value;
        emit LeverageFeeUpdated(_value);
    }


    function setMinEther(uint256 _value) external onlyAdmin {
        require(_value <= 100 ether, "Too much");
        minEther = _value;
        emit LeverageMinEtherUpdated(_value);
    }


    function changeAdmin(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0), "Zero address, be careful");
        admin = _newAdmin;
    }


    function create(uint256 _percent) public payable returns (uint256) {
        require(msg.value >= minEther, "Too small funds");
        require(_percent >= ILogic(settings.logicManager()).withdrawPercent(msg.value), "Collateralization is not enough");

        Bid memory _bid = Bid(
            tx.origin,
            msg.value,
            _percent
        );
        uint256 _id = bids.push(_bid).sub(1);
        emit BidCreated(_id, tx.origin, msg.value, _percent);
        return _id;
    }


    function close(uint256 _id) external onlyOwner(_id) {
        uint256 _eth = bids[_id].pack;
        delete bids[_id];
        msg.sender.transfer(_eth);
        emit BidClosed(_id, msg.sender);
    }


    function take(uint256 _id) external payable onlyExists(_id) {

        address payable _owner = bids[_id].owner;
        uint256 _eth = bids[_id].pack.mul(divider).div(bids[_id].percent);

        require(msg.value == _eth, "Incorrect ETH value");

        uint256 _sysEth = _eth.mul(commission).div(divider);
        systemETH = systemETH.add(_sysEth);
        uint256 _tmv = _eth.mul(ILogic(settings.logicManager()).rate()).div(ILogic(settings.logicManager()).precision());
        uint256 _box = ILogic(settings.logicManager()).create.value(bids[_id].pack)(_tmv);
        uint256 _sysTmv = _tmv.mul(commission).div(divider);
        delete bids[_id];
        _owner.transfer(_eth.sub(_sysEth));
        ILogic(settings.logicManager()).transferFrom(address(this), _owner, _box);
        IToken(settings.tmvAddress()).transfer(msg.sender, _tmv.sub(_sysTmv));
        emit BidMatched(_id, _box, msg.sender, _owner);
    }
}
