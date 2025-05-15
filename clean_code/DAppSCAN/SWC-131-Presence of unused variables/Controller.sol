

pragma solidity ^0.6.11;

import "deps/@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "deps/@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "deps/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "deps/@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "deps/@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

import "interfaces/badger/IConverter.sol";
import "interfaces/badger/IOneSplitAudit.sol";
import "interfaces/badger/IStrategy.sol";
import "./SettAccessControl.sol";

contract Controller is SettAccessControl {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;

    address public onesplit;
    address public rewards;
    mapping(address => address) public vaults;
    mapping(address => address) public strategies;
    mapping(address => mapping(address => address)) public converters;
    mapping(address => mapping(address => bool)) public approvedStrategies;

    uint256 public split = 500;
    uint256 public constant max = 10000;





    function initialize(
        address _governance,
        address _strategist,
        address _keeper,
        address _rewards
    ) public initializer {
        governance = _governance;
        strategist = _strategist;
        keeper = _keeper;

        rewards = _rewards;
        onesplit = address(0x50FDA034C0Ce7a8f7EFDAebDA7Aa7cA21CC1267e);
    }




    function _onlyApprovedForWant(address want) internal view {
        require(msg.sender == vaults[want] || msg.sender == keeper || msg.sender == strategist || msg.sender == governance, "!authorized");
    }




    function balanceOf(address _token) external view returns (uint256) {
        return IStrategy(strategies[_token]).balanceOf();
    }

    function getExpectedReturn(
        address _strategy,
        address _token,
        uint256 parts
    ) public view returns (uint256 expected) {
        uint256 _balance = IERC20Upgradeable(_token).balanceOf(_strategy);
        address _want = IStrategy(_strategy).want();
        (expected, ) = IOneSplitAudit(onesplit).getExpectedReturn(_token, _want, _balance, parts, 0);
    }




    function approveStrategy(address _token, address _strategy) public {
        _onlyGovernance();
        approvedStrategies[_token][_strategy] = true;
    }


    function revokeStrategy(address _token, address _strategy) public {
        _onlyGovernance();
        approvedStrategies[_token][_strategy] = false;
    }


    function setRewards(address _rewards) public {
        _onlyGovernance();
        rewards = _rewards;
    }

    function setSplit(uint256 _split) public {
        _onlyGovernance();
        split = _split;
    }


    function setOneSplit(address _onesplit) public {
        _onlyGovernance();
        onesplit = _onesplit;
    }





    function setVault(address _token, address _vault) public {
        _onlyGovernanceOrStrategist();

        require(vaults[_token] == address(0), "vault");
        vaults[_token] = _vault;
    }




    function setStrategy(address _token, address _strategy) public {
        _onlyGovernanceOrStrategist();

        require(approvedStrategies[_token][_strategy] == true, "!approved");

        address _current = strategies[_token];
        if (_current != address(0)) {
            IStrategy(_current).withdrawAll();
        }
        strategies[_token] = _strategy;
    }


    function setConverter(
        address _input,
        address _output,
        address _converter
    ) public {
        _onlyGovernanceOrStrategist();
        converters[_input][_output] = _converter;
    }




    function withdrawAll(address _token) public {
        _onlyGovernanceOrStrategist();
        IStrategy(strategies[_token]).withdrawAll();
    }



    function inCaseTokensGetStuck(address _token, uint256 _amount) public {
        _onlyGovernanceOrStrategist();
        IERC20Upgradeable(_token).safeTransfer(msg.sender, _amount);
    }



    function inCaseStrategyTokenGetStuck(address _strategy, address _token) public {
        _onlyGovernanceOrStrategist();
        IStrategy(_strategy).withdrawOther(_token);
    }







    function earn(address _token, uint256 _amount) public {
        address _strategy = strategies[_token];
        address _want = IStrategy(_strategy).want();

        _onlyApprovedForWant(_want);

        if (_want != _token) {
            address converter = converters[_token][_want];
            IERC20Upgradeable(_token).safeTransfer(converter, _amount);
            _amount = IConverter(converter).convert(_strategy);
            IERC20Upgradeable(_want).safeTransfer(_strategy, _amount);
        } else {
            IERC20Upgradeable(_token).safeTransfer(_strategy, _amount);
        }
        IStrategy(_strategy).deposit();
    }





    function withdraw(address _token, uint256 _amount) public {
        require(msg.sender == vaults[_token], "!vault");
        IStrategy(strategies[_token]).withdraw(_amount);
    }
}
