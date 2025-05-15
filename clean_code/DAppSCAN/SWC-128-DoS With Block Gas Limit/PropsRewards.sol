pragma solidity ^0.4.24;

import "zos-lib/contracts/Initializable.sol";
import "openzeppelin-eth/contracts/math/SafeMath.sol";
import "openzeppelin-eth/contracts/token/ERC20/ERC20.sol";
import { PropsRewardsLib } from "./PropsRewardsLib.sol";





contract PropsRewards is Initializable, ERC20 {
    using SafeMath for uint256;



    event DailyRewardsSubmitted(
        uint256 indexed rewardsDay,
        bytes32 indexed rewardsHash,
        address indexed validator
    );

    event DailyRewardsApplicationsMinted(
        uint256 indexed rewardsDay,
        bytes32 indexed rewardsHash,
        uint256 numOfApplications,
        uint256 amount
    );

    event DailyRewardsValidatorsMinted(
        uint256 indexed rewardsDay,
        bytes32 indexed rewardsHash,
        uint256 numOfValidators,
        uint256 amount
    );

    event EntityUpdated(
        address indexed id,
        PropsRewardsLib.RewardedEntityType indexed entityType,
        bytes32 name,
        address rewardsAddress,
        address indexed sidechainAddress
    );

    event ParameterUpdated(
        PropsRewardsLib.ParameterName param,
        uint256 newValue,
        uint256 oldValue,
        uint256 rewardsDay
    );

    event ValidatorsListUpdated(
        address[] validatorsList,
        uint256 indexed rewardsDay
    );

    event ApplicationsListUpdated(
        address[] applicationsList,
        uint256 indexed rewardsDay
    );

    event ControllerUpdated(address indexed newController);





    PropsRewardsLib.Data internal rewardsLibData;
    uint256 public maxTotalSupply;
    uint256 public rewardsStartTimestamp;
    address public controller;




    modifier onlyController() {
        require(
            msg.sender == controller,
            "Must be the controller"
        );
        _;
    }







    function initializePostRewardsUpgrade1(
        address _controller,
        uint256 _minSecondsBetweenDays,
        uint256 _rewardsStartTimestamp
    )
        public
    {
        uint256 decimals = 18;
        _initializePostRewardsUpgrade1(_controller, decimals, _minSecondsBetweenDays, _rewardsStartTimestamp);
    }






    function setValidators(uint256 _rewardsDay, address[] _validators)
        public
        onlyController
        returns (bool)
    {
        PropsRewardsLib.setValidators(rewardsLibData, _rewardsDay, _validators);
        emit ValidatorsListUpdated(_validators, _rewardsDay);
        return true;
    }






    function setApplications(uint256 _rewardsDay, address[] _applications)
        public
        onlyController
        returns (bool)
    {
        PropsRewardsLib.setApplications(rewardsLibData, _rewardsDay, _applications);
        emit ApplicationsListUpdated(_applications, _rewardsDay);
        return true;
    }






    function getEntities(PropsRewardsLib.RewardedEntityType _entityType, uint256 _rewardsDay)
        public
        view
        returns (address[])
    {
        return PropsRewardsLib.getEntities(rewardsLibData, _entityType, _rewardsDay);
    }









    function submitDailyRewards(
        uint256 _rewardsDay,
        bytes32 _rewardsHash,
        address[] _applications,
        uint256[] _amounts
    )
        public
        returns (bool)
    {

        if (_rewardsDay > 0 && (_rewardsDay > rewardsLibData.dailyRewards.lastRewardsDay)) {
            uint256 previousDayValidatorRewardsAmount = PropsRewardsLib.calculateValidatorRewards(
                rewardsLibData,
                rewardsLibData.dailyRewards.lastRewardsDay,
                rewardsLibData.dailyRewards.lastConfirmedRewardsHash,
                false
            );
            if (previousDayValidatorRewardsAmount > 0) {
                _mintDailyRewardsForValidators(rewardsLibData.dailyRewards.lastRewardsDay, rewardsLibData.dailyRewards.lastConfirmedRewardsHash, previousDayValidatorRewardsAmount);
            }
        }

        uint256 appRewardsSum = PropsRewardsLib.calculateApplicationRewards(
            rewardsLibData,
            _rewardsDay,
            _rewardsHash,
            _applications,
            _amounts,
            totalSupply()
        );
        if (appRewardsSum > 0) {
            _mintDailyRewardsForApps(_rewardsDay, _rewardsHash, _applications, _amounts, appRewardsSum);
        }


        uint256 validatorRewardsAmount = PropsRewardsLib.calculateValidatorRewards(
            rewardsLibData,
            _rewardsDay,
            _rewardsHash,
            true
        );
        if (validatorRewardsAmount > 0) {
            _mintDailyRewardsForValidators(_rewardsDay, _rewardsHash, validatorRewardsAmount);
        }

        emit DailyRewardsSubmitted(_rewardsDay, _rewardsHash, msg.sender);
        return true;
    }





    function updateController(
        address _controller
    )
        public
        onlyController
        returns (bool)
    {
        controller = _controller;
        emit ControllerUpdated
        (
            _controller
        );
        return true;
    }






    function getParameter(
        PropsRewardsLib.ParameterName _name,
        uint256 _rewardsDay
    )
        public
        view
        returns (uint256)
    {
        return PropsRewardsLib.getParameterValue(rewardsLibData, _name, _rewardsDay);
    }







    function updateParameter(
        PropsRewardsLib.ParameterName _name,
        uint256 _value,
        uint256 _rewardsDay
    )
        public
        onlyController
        returns (bool)
    {
        PropsRewardsLib.updateParameter(rewardsLibData, _name, _value, _rewardsDay);
        emit ParameterUpdated(
            _name,
            rewardsLibData.parameters[uint256(_name)].currentValue,
            rewardsLibData.parameters[uint256(_name)].previousValue,
            rewardsLibData.parameters[uint256(_name)].rewardsDay
        );
        return true;
    }








    function updateEntity(
        PropsRewardsLib.RewardedEntityType _entityType,
        bytes32 _name,
        address _rewardsAddress,
        address _sidechainAddress
    )
        public
        returns (bool)
    {
        PropsRewardsLib.updateEntity(rewardsLibData, _entityType, _name, _rewardsAddress, _sidechainAddress);
        emit EntityUpdated(msg.sender, _entityType, _name, _rewardsAddress, _sidechainAddress);
        return true;
    }








    function _initializePostRewardsUpgrade1(
        address _controller,
        uint256 _decimals,
        uint256 _minSecondsBetweenDays,
        uint256 _rewardsStartTimestamp
    )
        internal
    {
        require(maxTotalSupply==0, "Initialize rewards upgrade1 can happen only once");
        controller = _controller;

        PropsRewardsLib.updateParameter(rewardsLibData, PropsRewardsLib.ParameterName.ApplicationRewardsPercent, 34750, 0);

        PropsRewardsLib.updateParameter(rewardsLibData, PropsRewardsLib.ParameterName.ApplicationRewardsMaxVariationPercent, 150 * 1e6, 0);

        PropsRewardsLib.updateParameter(rewardsLibData, PropsRewardsLib.ParameterName.ValidatorMajorityPercent, 50 * 1e6, 0);

        PropsRewardsLib.updateParameter(rewardsLibData, PropsRewardsLib.ParameterName.ValidatorRewardsPercent, 1829, 0);


        rewardsLibData.maxTotalSupply = maxTotalSupply = 1 * 1e9 * (10 ** uint256(_decimals));
        rewardsLibData.rewardsStartTimestamp = rewardsStartTimestamp = _rewardsStartTimestamp;
        rewardsLibData.minSecondsBetweenDays = _minSecondsBetweenDays;

    }







    function _mintDailyRewardsForValidators(uint256 _rewardsDay, bytes32 _rewardsHash, uint256 _amount)
        internal
    {
        uint256 validatorsCount = rewardsLibData.dailyRewards.submissions[_rewardsHash].validatorsList.length;
        for (uint256 i = 0; i < validatorsCount; i++) {
            _mint(rewardsLibData.validators[rewardsLibData.dailyRewards.submissions[_rewardsHash].validatorsList[i]].rewardsAddress,_amount);
        }
        PropsRewardsLib._resetDailyRewards(rewardsLibData);
        emit DailyRewardsValidatorsMinted(
            _rewardsDay,
            _rewardsHash,
            validatorsCount,
            (_amount * validatorsCount)
        );
    }









    function _mintDailyRewardsForApps(
        uint256 _rewardsDay,
        bytes32 _rewardsHash,
        address[] _applications,
        uint256[] _amounts,
        uint256 _sum
    )
        internal
    {
        for (uint256 i = 0; i < _applications.length; i++) {
            _mint(rewardsLibData.applications[_applications[i]].rewardsAddress, _amounts[i]);
        }
        emit DailyRewardsApplicationsMinted(_rewardsDay, _rewardsHash, _applications.length, _sum);
    }
}
