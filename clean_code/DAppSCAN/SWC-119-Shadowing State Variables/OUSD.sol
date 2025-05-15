pragma solidity 0.5.11;







import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import {
    Initializable
} from "@openzeppelin/upgrades/contracts/Initializable.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import { InitializableToken } from "../utils/InitializableToken.sol";
import { StableMath } from "../utils/StableMath.sol";
import { Governable } from "../governance/Governable.sol";

contract OUSD is Initializable, InitializableToken, Governable {
    using SafeMath for uint256;
    using StableMath for uint256;

    event TotalSupplyUpdated(
        uint256 totalSupply,
        uint256 rebasingCredits,
        uint256 rebasingCreditsPerToken
    );

    uint256 private constant MAX_SUPPLY = ~uint128(0);

    uint256 private _totalSupply;
    uint256 public rebasingCredits;

    uint256 public rebasingCreditsPerToken;

    mapping(address => uint256) private _creditBalances;



    mapping(address => mapping(address => uint256)) private _allowances;

    address public vaultAddress = address(0);



    uint256 public nonRebasingCredits;
    uint256 public nonRebasingSupply;
    mapping(address => uint256) public nonRebasingCreditsPerToken;
    enum RebaseOptions { NotSet, OptOut, OptIn }
    mapping(address => RebaseOptions) public rebaseState;

    function initialize(
        string calldata _nameArg,
        string calldata _symbolArg,
        address _vaultAddress
    ) external onlyGovernor initializer {
        InitializableToken._initialize(_nameArg, _symbolArg);

        _totalSupply = 0;
        rebasingCredits = 0;
        rebasingCreditsPerToken = 1e18;

        vaultAddress = _vaultAddress;

        nonRebasingCredits = 0;
        nonRebasingSupply = 0;
    }




    modifier onlyVault() {
        require(vaultAddress == msg.sender, "Caller is not the Vault");
        _;
    }




    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }







    function balanceOf(address _account) public view returns (uint256) {
        return
            _creditBalances[_account].divPrecisely(_creditsPerToken(_account));
    }







    function creditsBalanceOf(address _account)
        public
        view
        returns (uint256, uint256)
    {
        return (_creditBalances[_account], _creditsPerToken(_account));
    }







    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0), "Transfer to zero address");

        _executeTransfer(msg.sender, _to, _value);

        emit Transfer(msg.sender, _to, _value);

        return true;
    }







    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool) {
        require(_to != address(0), "Transfer to zero address");

        _allowances[_from][msg.sender] = _allowances[_from][msg.sender].sub(
            _value
        );

        _executeTransfer(_from, _to, _value);

        emit Transfer(_from, _to, _value);

        return true;
    }








    function _executeTransfer(
        address _from,
        address _to,
        uint256 _value
    ) internal {
        bool isNonRebasingTo = _isNonRebasingAccount(_to);
        bool isNonRebasingFrom = _isNonRebasingAccount(_from);



        uint256 creditsCredited = _value.mulTruncate(_creditsPerToken(_to));
        uint256 creditsDeducted = _value.mulTruncate(_creditsPerToken(_from));

        _creditBalances[_from] = _creditBalances[_from].sub(
            creditsDeducted,
            "Transfer amount exceeds balance"
        );
        _creditBalances[_to] = _creditBalances[_to].add(creditsCredited);

        if (isNonRebasingTo && !isNonRebasingFrom) {


            nonRebasingCredits = nonRebasingCredits.add(creditsCredited);
            nonRebasingSupply = nonRebasingSupply.add(_value);

            rebasingCredits = rebasingCredits.sub(creditsDeducted);
        } else if (!isNonRebasingTo && isNonRebasingFrom) {


            nonRebasingCredits = nonRebasingCredits.sub(creditsDeducted);
            nonRebasingSupply = nonRebasingSupply.sub(_value);

            rebasingCredits = rebasingCredits.add(creditsCredited);
        } else if (isNonRebasingTo && isNonRebasingFrom) {




            nonRebasingCredits =
                nonRebasingCredits +
                creditsCredited -
                creditsDeducted;
        }
    }







    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256)
    {
        return _allowances[_owner][_spender];
    }












    function approve(address _spender, uint256 _value) public returns (bool) {
        _allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }








    function increaseAllowance(address _spender, uint256 _addedValue)
        public
        returns (bool)
    {
        _allowances[msg.sender][_spender] = _allowances[msg.sender][_spender]
            .add(_addedValue);
        emit Approval(msg.sender, _spender, _allowances[msg.sender][_spender]);
        return true;
    }






    function decreaseAllowance(address _spender, uint256 _subtractedValue)
        public
        returns (bool)
    {
        uint256 oldValue = _allowances[msg.sender][_spender];
        if (_subtractedValue >= oldValue) {
            _allowances[msg.sender][_spender] = 0;
        } else {
            _allowances[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, _allowances[msg.sender][_spender]);
        return true;
    }




    function mint(address _account, uint256 _amount) external onlyVault {
        return _mint(_account, _amount);
    }











    function _mint(address _account, uint256 _amount) internal {
        require(_account != address(0), "Mint to the zero address");

        bool isNonRebasingAccount = _isNonRebasingAccount(_account);

        uint256 creditAmount = _amount.mulTruncate(_creditsPerToken(_account));
        _creditBalances[_account] = _creditBalances[_account].add(creditAmount);



        if (isNonRebasingAccount) {
            nonRebasingCredits = nonRebasingCredits.add(creditAmount);
            nonRebasingSupply = nonRebasingSupply.add(_amount);
        } else {
            rebasingCredits = rebasingCredits.add(creditAmount);
        }

        _totalSupply = _totalSupply.add(_amount);

        emit Transfer(address(0), _account, _amount);
    }




    function burn(address account, uint256 amount) external onlyVault {
        return _burn(account, amount);
    }












    function _burn(address _account, uint256 _amount) internal {
        require(_account != address(0), "Burn from the zero address");

        bool isNonRebasingAccount = _isNonRebasingAccount(_account);
        uint256 creditAmount = _amount.mulTruncate(_creditsPerToken(_account));
        uint256 currentCredits = _creditBalances[_account];


        if (
            currentCredits == creditAmount || currentCredits - 1 == creditAmount
        ) {

            _creditBalances[_account] = 0;
        } else if (currentCredits > creditAmount) {
            _creditBalances[_account] = _creditBalances[_account].sub(
                creditAmount
            );
        } else {
            revert("Remove exceeds balance");
        }


        if (isNonRebasingAccount) {
            nonRebasingCredits = nonRebasingCredits.sub(creditAmount);
            nonRebasingSupply = nonRebasingSupply.sub(_amount);
        } else {
            rebasingCredits = rebasingCredits.sub(creditAmount);
        }

        _totalSupply = _totalSupply.sub(_amount);

        emit Transfer(_account, address(0), _amount);
    }






    function _creditsPerToken(address _account)
        internal
        view
        returns (uint256)
    {
        if (nonRebasingCreditsPerToken[_account] != 0) {
            return nonRebasingCreditsPerToken[_account];
        } else {
            return rebasingCreditsPerToken;
        }
    }





    function _isNonRebasingAccount(address _account) internal returns (bool) {
        if (Address.isContract(_account)) {

            if (rebaseState[_account] == RebaseOptions.OptIn) {


                return false;
            }



            _ensureRebasingMigration(_account);
            return true;
        } else {


            return rebaseState[_account] == RebaseOptions.OptOut;
        }
    }





    function _ensureRebasingMigration(address _account) internal {
        if (nonRebasingCreditsPerToken[_account] == 0) {

            nonRebasingCreditsPerToken[_account] = rebasingCreditsPerToken;

            nonRebasingSupply = nonRebasingSupply.add(balanceOf(_account));

            rebasingCredits = rebasingCredits.sub(_creditBalances[_account]);
            nonRebasingCredits = nonRebasingCredits.add(
                _creditBalances[_account]
            );
        }
    }






    function rebaseOptIn() public {
        require(_isNonRebasingAccount(msg.sender), "Account has not opted out");


        uint256 newCreditBalance = _creditBalances[msg.sender]
            .mul(rebasingCreditsPerToken)
            .div(_creditsPerToken(msg.sender));


        nonRebasingSupply = nonRebasingSupply.sub(balanceOf(msg.sender));

        nonRebasingCredits = nonRebasingCredits.sub(
            _creditBalances[msg.sender]
        );

        _creditBalances[msg.sender] = newCreditBalance;



        rebasingCredits = rebasingCredits.add(_creditBalances[msg.sender]);

        rebaseState[msg.sender] = RebaseOptions.OptIn;


        delete nonRebasingCreditsPerToken[msg.sender];
    }




    function rebaseOptOut() public {
        require(!_isNonRebasingAccount(msg.sender), "Account has not opted in");


        nonRebasingSupply = nonRebasingSupply.add(balanceOf(msg.sender));

        nonRebasingCredits = nonRebasingCredits.add(
            _creditBalances[msg.sender]
        );


        nonRebasingCreditsPerToken[msg.sender] = rebasingCreditsPerToken;



        rebasingCredits = rebasingCredits.sub(_creditBalances[msg.sender]);


        rebaseState[msg.sender] = RebaseOptions.OptOut;
    }







    function changeSupply(uint256 _newTotalSupply)
        external
        onlyVault
        returns (uint256)
    {
        require(_totalSupply > 0, "Cannot increase 0 supply");

        if (_totalSupply == _newTotalSupply) {
            emit TotalSupplyUpdated(
                _totalSupply,
                rebasingCredits,
                rebasingCreditsPerToken
            );
            return _totalSupply;
        }

        _totalSupply = _newTotalSupply;

        if (_totalSupply > MAX_SUPPLY) _totalSupply = MAX_SUPPLY;

        rebasingCreditsPerToken = rebasingCredits.divPrecisely(
            _totalSupply.sub(nonRebasingSupply)
        );

        emit TotalSupplyUpdated(
            _totalSupply,
            rebasingCredits,
            rebasingCreditsPerToken
        );

        return _totalSupply;
    }
}
