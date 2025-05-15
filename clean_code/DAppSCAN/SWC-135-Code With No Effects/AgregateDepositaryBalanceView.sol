
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../utils/OwnablePausable.sol";
import "./IDepositaryBalanceView.sol";

contract AgregateDepositaryBalanceView is IDepositaryBalanceView, OwnablePausable {
    using SafeMath for uint256;


    uint256 public maxSize;


    uint256 public override decimals;


    IDepositaryBalanceView[] public depositaries;


    mapping(address => uint256) internal depositariesIndex;


    event DepositaryAdded(address depositary);


    event DepositaryRemoved(address depositary);





    constructor(uint256 _decimals, uint256 _maxSize) public {
        decimals = _decimals;
        maxSize = _maxSize;
    }




    function size() public view returns (uint256) {
        return depositaries.length;
    }






    function addDepositary(address depositary) external onlyOwner {
        require(depositariesIndex[depositary] == 0, "AgregateDepositaryBalanceView::addDepositary: depositary already added");
        require(size() < maxSize, "AgregateDepositaryBalanceView::addDepositary: too many depositaries");

        depositaries.push(IDepositaryBalanceView(depositary));
        depositariesIndex[depositary] = size().sub(1);
        emit DepositaryAdded(depositary);
    }





    function removeDepositary(address depositary) external onlyOwner {
        uint256 depositaryIndex = depositariesIndex[depositary];
        require(depositaryIndex != 0, "AgregateDepositaryBalanceView::removeDepositary: depositary already removed");

        delete depositariesIndex[depositary];
        depositaries[depositaryIndex] = depositaries[size().sub(1)];
        delete depositaries[size().sub(1)];
        emit DepositaryRemoved(depositary);
    }




    function allowedDepositaries() external view returns (address[] memory) {
        address[] memory result = new address[](size());

        for (uint256 i = 0; i < size(); i++) {
            result[i] = address(depositaries[i]);
        }

        return result;
    }

    function balance() external view override returns (uint256) {
        uint256 result;

        for (uint256 i = 0; i < size(); i++) {
            uint256 depositaryBalance = depositaries[i].balance();
            uint256 depositaryDecimals = depositaries[i].decimals();
            uint256 decimalsPower = decimals.sub(depositaryDecimals);
            result = result.add(depositaryBalance.mul(10**decimalsPower));
        }

        return result;
    }
}
