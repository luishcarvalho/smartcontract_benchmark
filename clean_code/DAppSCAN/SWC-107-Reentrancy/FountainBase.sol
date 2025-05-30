

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./libraries/ReentrancyGuard.sol";
import "./libraries/SafeERC20.sol";
import "./libraries/SafeMath.sol";
import "./interfaces/IArchangel.sol";
import "./interfaces/IAngel.sol";
import "./interfaces/IFountain.sol";
import "./interfaces/IFountainFactory.sol";
import "./utils/ErrorMsg.sol";
import "./FountainToken.sol";


abstract contract FountainBase is FountainToken, ReentrancyGuard, ErrorMsg {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;


    IERC20 public immutable stakingToken;

    IFountainFactory public immutable factory;
    IArchangel public immutable archangel;


    struct AngelInfo {
        bool isSet;
        uint256 pid;
        uint256 totalBalance;
    }


    mapping(address => IAngel[]) private _joinedAngels;

    mapping(IAngel => AngelInfo) private _angelInfos;

    event Join(address user, address angel);
    event Quit(address user, address angel);
    event Deposit(address indexed user, uint256 amount, address indexed to);
    event Withdraw(address indexed user, uint256 amount, address indexed to);
    event EmergencyWithdraw(
        address indexed user,
        uint256 amount,
        address indexed to
    );
    event Harvest(address indexed user);

    constructor(IERC20 token) public {
        stakingToken = token;
        IFountainFactory f = IFountainFactory(msg.sender);
        factory = f;
        archangel = IArchangel(f.archangel());
    }



    function getContractName() public pure override returns (string memory) {
        return "Fountain";
    }




    function joinedAngel(address user) public view returns (IAngel[] memory) {
        return _joinedAngels[user];
    }






    function angelInfo(IAngel angel) public view returns (uint256, uint256) {
        AngelInfo storage info = _angelInfos[angel];
        _requireMsg(info.isSet, "angelInfo", "Fountain: angel not set");
        return (info.pid, info.totalBalance);
    }





    function setPoolId(uint256 pid) external {
        IAngel angel = IAngel(_msgSender());
        AngelInfo storage info = _angelInfos[angel];
        _requireMsg(info.isSet == false, "setPoolId", "Fountain: angel is set");
        _requireMsg(
            angel.lpToken(pid) == address(stakingToken),
            "setPoolId",
            "Fountain: token not matched"
        );
        info.isSet = true;
        info.pid = pid;
    }






    function deposit(uint256 amount) external {

        _mint(_msgSender(), amount);


        stakingToken.safeTransferFrom(_msgSender(), address(this), amount);

        emit Deposit(_msgSender(), amount, _msgSender());
    }







    function depositTo(uint256 amount, address to) external {

        _mint(to, amount);


        stakingToken.safeTransferFrom(_msgSender(), address(this), amount);
        emit Deposit(_msgSender(), amount, to);
    }





    function withdraw(uint256 amount) external {

        amount = amount == type(uint256).max ? balanceOf(_msgSender()) : amount;


        _burn(_msgSender(), amount);


        stakingToken.safeTransfer(_msgSender(), amount);
        emit Withdraw(_msgSender(), amount, _msgSender());
    }






    function withdrawTo(uint256 amount, address to) external {

        amount = amount == type(uint256).max ? balanceOf(_msgSender()) : amount;


        _burn(_msgSender(), amount);


        stakingToken.safeTransfer(to, amount);
        emit Withdraw(_msgSender(), amount, to);
    }



    function harvest(IAngel angel) external {
        _harvestAngel(angel, _msgSender(), _msgSender());
        emit Harvest(_msgSender());
    }


    function harvestAll() external {

        IAngel[] storage angels = _joinedAngels[_msgSender()];
        for (uint256 i = 0; i < angels.length; i++) {
            IAngel angel = angels[i];
            _harvestAngel(angel, _msgSender(), _msgSender());
        }
        emit Harvest(_msgSender());
    }


    function emergencyWithdraw() external {
        uint256 amount = balanceOf(_msgSender());


        _burn(_msgSender(), type(uint256).max);


        stakingToken.safeTransfer(_msgSender(), amount);
        emit EmergencyWithdraw(_msgSender(), amount, _msgSender());
    }



    function joinAngel(IAngel angel) external {
        _joinAngel(angel, _msgSender());
    }



    function joinAngels(IAngel[] calldata angels) external {
        for (uint256 i = 0; i < angels.length; i++) {
            _joinAngel(angels[i], _msgSender());
        }
    }



    function quitAngel(IAngel angel) external {
        IAngel[] storage angels = _joinedAngels[_msgSender()];
        uint256 len = angels.length;
        if (angels[len - 1] == angel) {
            angels.pop();
        } else {
            for (uint256 i = 0; i < len - 1; i++) {
                if (angels[i] == angel) {
                    angels[i] = angels[len - 1];
                    angels.pop();
                    break;
                }
            }
        }
        _requireMsg(
            angels.length != len,
            "quitAngel",
            "Fountain: unjoined angel"
        );

        emit Quit(_msgSender(), address(angel));


        _withdrawAngel(_msgSender(), angel, balanceOf(_msgSender()));
    }


    function quitAllAngel() external {
        IAngel[] storage angels = _joinedAngels[_msgSender()];
        for (uint256 i = 0; i < angels.length; i++) {
            IAngel angel = angels[i];
            emit Quit(_msgSender(), address(angel));

            _withdrawAngel(_msgSender(), angel, balanceOf(_msgSender()));
        }
        delete _joinedAngels[_msgSender()];
    }




    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (from != address(0)) {
            IAngel[] storage angels = _joinedAngels[from];
            if (amount < type(uint256).max) {
                for (uint256 i = 0; i < angels.length; i++) {
                    IAngel angel = angels[i];
                    _withdrawAngel(from, angel, amount);
                }
            } else {
                for (uint256 i = 0; i < angels.length; i++) {
                    IAngel angel = angels[i];
                    _emergencyWithdrawAngel(from, angel);
                }
            }
        }
        if (to != address(0)) {
            IAngel[] storage angels = _joinedAngels[to];
            for (uint256 i = 0; i < angels.length; i++) {
                IAngel angel = angels[i];
                _depositAngel(to, angel, amount);
            }
        }
    }




    function _depositAngel(
        address user,
        IAngel angel,
        uint256 amount
    ) internal nonReentrant {
        AngelInfo storage info = _angelInfos[angel];
        _requireMsg(
            info.isSet,
            "_depositAngel",
            "Fountain: not added by angel"
        );
        angel.deposit(info.pid, amount, user);
        info.totalBalance = info.totalBalance.add(amount);
    }


    function _withdrawAngel(
        address user,
        IAngel angel,
        uint256 amount
    ) internal nonReentrant {
        AngelInfo storage info = _angelInfos[angel];
        _requireMsg(
            info.isSet,
            "_withdrawAngel",
            "Fountain: not added by angel"
        );
        angel.withdraw(info.pid, amount, user);
        info.totalBalance = info.totalBalance.sub(amount);
    }

    function _harvestAngel(
        IAngel angel,
        address from,
        address to
    ) internal nonReentrant {
        AngelInfo storage info = _angelInfos[angel];
        _requireMsg(
            info.isSet,
            "_harvestAngel",
            "Fountain: not added by angel"
        );
        angel.harvest(info.pid, from, to);
    }

    function _emergencyWithdrawAngel(address user, IAngel angel)
        internal
        nonReentrant
    {
        AngelInfo storage info = _angelInfos[angel];
        _requireMsg(
            info.isSet,
            "_emergencyAngel",
            "Fountain: not added by angel"
        );
        uint256 amount = balanceOf(user);
        angel.emergencyWithdraw(info.pid, user);
        info.totalBalance = info.totalBalance.sub(amount);
    }

    function _joinAngel(IAngel angel, address user) internal {
        IAngel[] storage angels = _joinedAngels[user];
        for (uint256 i = 0; i < angels.length; i++) {
            _requireMsg(angels[i] != angel, "_joinAngel", "Angel joined");
        }
        angels.push(angel);

        emit Join(user, address(angel));


        _depositAngel(user, angel, balanceOf(user));
    }
}
