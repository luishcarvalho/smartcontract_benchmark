
pragma solidity ^0.8.4;

import "./IOracle.sol";
import "./ICollateralizationOracle.sol";
import "../refs/CoreRef.sol";
import "../pcv/IPCVDepositBalances.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

interface IPausable {
    function paused() external view returns (bool);
}






contract CollateralizationOracle is ICollateralizationOracle, CoreRef {
    using Decimal for Decimal.D256;
    using EnumerableSet for EnumerableSet.AddressSet;



    event DepositAdd(address from, address indexed deposit, address indexed token);
    event DepositRemove(address from, address indexed deposit);
    event OracleUpdate(address from, address indexed token, address indexed oldOracle, address indexed newOracle);




    mapping(address => bool) public excludedDeposits;




    mapping(address => address) public tokenToOracle;



    mapping(address => EnumerableSet.AddressSet) private tokenToDeposits;



    mapping(address => address) public depositToToken;


    EnumerableSet.AddressSet private tokensInPcv;








    constructor(
        address _core,
        address[] memory _deposits,
        address[] memory _tokens,
        address[] memory _oracles
    ) CoreRef(_core) {
        _setOracles(_tokens, _oracles);
        _addDeposits(_deposits);
    }




    function isTokenInPcv(address token) external view returns(bool) {
        return tokensInPcv.contains(token);
    }


    function getTokensInPcv() external view returns(address[] memory) {
        uint256 _length = tokensInPcv.length();
        address[] memory tokens = new address[](_length);
        for (uint256 i = 0; i < _length; i++) {
            tokens[i] = tokensInPcv.at(i);
        }
        return tokens;
    }


    function getTokenInPcv(uint256 i) external view returns(address) {
        return tokensInPcv.at(i);
    }


    function getDepositsForToken(address _token) external view returns(address[] memory) {
        uint256 _length = tokenToDeposits[_token].length();
        address[] memory deposits = new address[](_length);
        for (uint256 i = 0; i < _length; i++) {
            deposits[i] = tokenToDeposits[_token].at(i);
        }
        return deposits;
    }


    function getDepositForToken(address token, uint256 i) external view returns(address) {
        return tokenToDeposits[token].at(i);
    }








    function setDepositExclusion(address _deposit, bool _excluded) external onlyGuardianOrGovernor {
        excludedDeposits[_deposit] = _excluded;
    }






    function addDeposit(address _deposit) public onlyGovernor {
        _addDeposit(_deposit);
    }


    function addDeposits(address[] memory _deposits) public onlyGovernor {
        _addDeposits(_deposits);
    }

    function _addDeposits(address[] memory _deposits) internal {
        for (uint256 i = 0; i < _deposits.length; i++) {
            _addDeposit(_deposits[i]);
        }
    }

    function _addDeposit(address _deposit) internal {

        require(depositToToken[_deposit] == address(0), "CollateralizationOracle: deposit duplicate");


        address _token = IPCVDepositBalances(_deposit).balanceReportedIn();


        require(tokenToOracle[_token] != address(0), "CollateralizationOracle: no oracle");


        depositToToken[_deposit] = _token;
        tokenToDeposits[_token].add(_deposit);
        tokensInPcv.add(_token);


        emit DepositAdd(msg.sender, _deposit, _token);
    }





    function removeDeposit(address _deposit) public onlyGovernor {
        _removeDeposit(_deposit);
    }


    function removeDeposits(address[] memory _deposits) public onlyGovernor {
        for (uint256 i = 0; i < _deposits.length; i++) {
            _removeDeposit(_deposits[i]);
        }
    }

    function _removeDeposit(address _deposit) internal {

        address _token = depositToToken[_deposit];


        require(_token != address(0), "CollateralizationOracle: deposit not found");



        depositToToken[_deposit] = address(0);
        tokenToDeposits[_token].remove(_deposit);



        if (tokenToDeposits[_token].length() == 0) {
          tokensInPcv.remove(_token);
        }


        emit DepositRemove(msg.sender, _deposit);
    }





    function swapDeposit(address _oldDeposit, address _newDeposit) external onlyGovernor {
        removeDeposit(_oldDeposit);
        addDeposit(_newDeposit);
    }




    function setOracle(address _token, address _newOracle) external onlyGovernor {
        _setOracle(_token, _newOracle);
    }


    function setOracles(address[] memory _tokens, address[] memory _oracles) public onlyGovernor {
        _setOracles(_tokens, _oracles);
    }

    function _setOracles(address[] memory _tokens, address[] memory _oracles) internal {
        require(_tokens.length == _oracles.length, "CollateralizationOracle: length mismatch");
        for (uint256 i = 0; i < _tokens.length; i++) {
            _setOracle(_tokens[i], _oracles[i]);
        }
    }

    function _setOracle(address _token, address _newOracle) internal {
        require(_token != address(0), "CollateralizationOracle: token must be != 0x0");
        require(_newOracle != address(0), "CollateralizationOracle: oracle must be != 0x0");


        address _oldOracle = tokenToOracle[_token];
        tokenToOracle[_token] = _newOracle;


        emit OracleUpdate(msg.sender, _token, _oldOracle, _newOracle);
    }




    function update() external override whenNotPaused {
        for (uint256 i = 0; i < tokensInPcv.length(); i++) {
            address _oracle = tokenToOracle[tokensInPcv.at(i)];
            if (!IPausable(_oracle).paused()) {
                IOracle(_oracle).update();
            }
        }
    }



    function isOutdated() external override view returns (bool) {
        bool _outdated = false;
        for (uint256 i = 0; i < tokensInPcv.length() && !_outdated; i++) {
            address _oracle = tokenToOracle[tokensInPcv.at(i)];
            if (!IPausable(_oracle).paused()) {
                _outdated = _outdated || IOracle(_oracle).isOutdated();
            }
        }
        return _outdated;
    }






    function read() public override view returns (Decimal.D256 memory collateralRatio, bool validityStatus) {

        (
          uint256 _protocolControlledValue,
          uint256 _userCirculatingFei,
          ,
          bool _valid
        ) = pcvStats();



        collateralRatio = Decimal.ratio(_protocolControlledValue, _userCirculatingFei);
        validityStatus = _valid;
    }













    function pcvStats() public override view returns (
      uint256 protocolControlledValue,
      uint256 userCirculatingFei,
      int256 protocolEquity,
      bool validityStatus
    ) {
        uint256 _protocolControlledFei = 0;
        validityStatus = !paused();


        for (uint256 i = 0; i < tokensInPcv.length(); i++) {
            address _token = tokensInPcv.at(i);
            uint256 _totalTokenBalance  = 0;


            for (uint256 j = 0; j < tokenToDeposits[_token].length(); j++) {
                address _deposit = tokenToDeposits[_token].at(j);


                if (!excludedDeposits[_deposit]) {

                    (uint256 _depositBalance, uint256 _depositFei) = IPCVDepositBalances(_deposit).resistantBalanceAndFei();
                    _totalTokenBalance += _depositBalance;
                    _protocolControlledFei += _depositFei;
                }
            }



            if (_totalTokenBalance != 0) {
                (Decimal.D256 memory _oraclePrice, bool _oracleValid) = IOracle(tokenToOracle[_token]).read();
                if (!_oracleValid) {
                    validityStatus = false;
                }

                protocolControlledValue += _oraclePrice.mul(_totalTokenBalance).asUint256();
            }
        }

        userCirculatingFei = fei().totalSupply() - _protocolControlledFei;
        protocolEquity = int256(protocolControlledValue) - int256(userCirculatingFei);
    }






    function isOvercollateralized() external override view whenNotPaused returns (bool) {
        (,, int256 _protocolEquity, bool _valid) = pcvStats();
        require(_valid, "CollateralizationOracle: reading is invalid");
        return _protocolEquity > 0;
    }
}
