
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../utils/AccessControl.sol";
import "./IDepositaryBalanceView.sol";

contract RealAssetDepositaryBalanceView is IDepositaryBalanceView, AccessControl {
    using SafeMath for uint256;


    struct Proof {
        string data;
        string signature;
    }


    struct Asset {
        string id;
        uint256 amount;
        uint256 price;
    }


    uint256 public maxSize;


    uint256 public override decimals = 6;


    Asset[] public portfolio;


    mapping(string => uint256) internal portfolioIndex;


    event AssetUpdated(string id, uint256 updatedAt, Proof proof);


    event AssetRemoved(string id);





    constructor(uint256 _decimals, uint256 _maxSize) public {
        decimals = _decimals;
        maxSize = _maxSize;
    }




    function size() public view returns (uint256) {
        return portfolio.length;
    }




    function assets() external view returns (Asset[] memory) {
        Asset[] memory result = new Asset[](size());

        for (uint256 i = 0; i < size(); i++) {
            result[i] = portfolio[i];
        }

        return result;
    }











    function put(
        string calldata id,
        uint256 amount,
        uint256 price,
        uint256 updatedAt,
        string calldata proofData,
        string calldata proofSignature
    ) external onlyAllowed {
        require(size() < maxSize, "RealAssetDepositaryBalanceView::put: too many assets");

        uint256 valueIndex = portfolioIndex[id];
        if (valueIndex != 0) {
            portfolio[valueIndex.sub(1)] = Asset(id, amount, price);
        } else {
            portfolio.push(Asset(id, amount, price));
            portfolioIndex[id] = size();
        }
        emit AssetUpdated(id, updatedAt, Proof(proofData, proofSignature));
    }





    function remove(string calldata id) external onlyAllowed {
        uint256 valueIndex = portfolioIndex[id];
        require(valueIndex != 0, "RealAssetDepositaryBalanceView::remove: asset already removed");

        uint256 toDeleteIndex = valueIndex.sub(1);
        uint256 lastIndex = size().sub(1);
        Asset memory lastValue = portfolio[lastIndex];
        portfolio[toDeleteIndex] = lastValue;
        portfolioIndex[lastValue.id] = toDeleteIndex.add(1);
        portfolio.pop();
        delete portfolioIndex[id];

        emit AssetRemoved(id);
    }

    function balance() external view override returns (uint256) {
        uint256 result;

        for (uint256 i = 0; i < size(); i++) {
            result = result.add(portfolio[i].amount.mul(portfolio[i].price));
        }

        return result;
    }
}
