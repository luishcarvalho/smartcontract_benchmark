pragma solidity ^0.5.16;

import "./SafeMath.sol";
import "./Ownable.sol";


interface HoldefiInterface {

	function updateSupplyIndex(address market) external;

	function updateBorrowIndex(address market) external;

	function updatePromotionReserve(address market) external;
}


contract HoldefiSettings is Ownable {

	using SafeMath for uint256;

	uint constant public ratesDecimal = 10 ** 4;

	uint constant public secondsPerTenDays = 864000;

	uint constant public maxBorrowRate = 4000;

	uint constant public borrowRateMaxIncrease = 500;

	uint constant public minSuppliersShareRate = 5000;

	uint constant public suppliersShareRateMaxDecrease = 500;

	uint constant public maxValueToLoanRate = 20000;

	uint constant public valueToLoanRateMaxIncrease = 500;

	uint constant public maxPenaltyRate = 13000;

	uint constant public penaltyRateMaxIncrease = 500;


	struct Market {
		bool isActive;

		uint borrowRate;
		uint borrowRateUpdateTime;

		uint suppliersShareRate;
		uint suppliersShareRateUpdateTime;
	}


	struct Collateral {
		bool isActive;
		uint valueToLoanRate;
		uint VTLUpdateTime;
		uint penaltyRate;
		uint penaltyUpdateTime;
		uint bonusRate;
	}


	mapping (address => Market) public marketAssets;
	address[] public marketsList;


	mapping (address => Collateral) public collateralAssets;

	HoldefiInterface public holdefiContract;

	event BorrowRateChanged(address market, uint newRate);

	event SuppliersShareRateChanged(address market, uint newRate);

	event MarketAdded(address market);

	event MarketRemoved(address market);

	event CollateralAdded(address collateral, uint valueToLoanRate, uint penaltyRate, uint bonusRate);

	event CollateralRemoved(address collateral);

	event ValueToLoanRateChanged(address collateral, uint newRate);

	event PenaltyRateChanged(address collateral, uint newRate);

	event BonusRateChanged(address collateral, uint newRate);

	constructor (address newOwnerChanger) Ownable(newOwnerChanger) public {
	}


	function setHoldefiContract(HoldefiInterface holdefiContractAddress) external onlyOwner {
		require (address(holdefiContract) == address(0),'Should be set once');
		holdefiContract = holdefiContractAddress;
	}



	function getInterests (address market, uint totalSupply, uint totalBorrow) external view returns(uint borrowRate, uint supplyRate) {
		borrowRate = marketAssets[market].borrowRate;
		uint suppliersShareRate = marketAssets[market].suppliersShareRate;
		if (totalSupply == 0){
			supplyRate = 0;
		}
		else {
			uint totalInterestFromBorrow = totalBorrow.mul(borrowRate);
			uint suppliersShare = totalInterestFromBorrow.mul(suppliersShareRate);
			suppliersShare = suppliersShare.div(ratesDecimal);
			supplyRate = suppliersShare.div(totalSupply);
		}
	}


	function getMarketsList() external view returns (address[] memory res){
		res = marketsList;
	}


	function getMarket(address market) external view returns (bool active){
		active = marketAssets[market].isActive;
	}


	function getCollateral(address collateral) external view returns (bool, uint, uint, uint){
		return(
			collateralAssets[collateral].isActive,
			collateralAssets[collateral].valueToLoanRate,
			collateralAssets[collateral].penaltyRate,
			collateralAssets[collateral].bonusRate
			);
	}


	function setBorrowRate (address market, uint newBorrowRate) external onlyOwner {
		require (newBorrowRate <= maxBorrowRate,'Rate should be less than max');
		uint currentTime = block.timestamp;

		if (newBorrowRate > marketAssets[market].borrowRate){
			uint deltaTime = currentTime.sub(marketAssets[market].borrowRateUpdateTime);
			require (deltaTime >= secondsPerTenDays,'Increasing rate is not allowed at this time');
			uint maxIncrease = marketAssets[market].borrowRate.add(borrowRateMaxIncrease);
			require (newBorrowRate <= maxIncrease,'Rate should be increased less than max allowed');
		}

		holdefiContract.updateBorrowIndex(market);
		holdefiContract.updateSupplyIndex(market);
		holdefiContract.updatePromotionReserve(market);
		marketAssets[market].borrowRate = newBorrowRate;
		marketAssets[market].borrowRateUpdateTime = currentTime;

		emit BorrowRateChanged(market, newBorrowRate);
	}


	function setSuppliersShareRate (address market, uint newSuppliersShareRate) external onlyOwner {
		require (newSuppliersShareRate >= minSuppliersShareRate && newSuppliersShareRate <= ratesDecimal,'Rate should be in allowed range');
		uint currentTime = block.timestamp;

		if (newSuppliersShareRate < marketAssets[market].suppliersShareRate) {
			uint deltaTime = currentTime.sub(marketAssets[market].suppliersShareRateUpdateTime);
			require (deltaTime >= secondsPerTenDays,'Decreasing rate is not allowed at this time');
			uint maxDecrease = marketAssets[market].suppliersShareRate.sub(suppliersShareRateMaxDecrease);
			require (newSuppliersShareRate >= maxDecrease,'Rate should be decreased less than max allowed');
		}

		holdefiContract.updateSupplyIndex(market);
		holdefiContract.updatePromotionReserve(market);
		marketAssets[market].suppliersShareRate = newSuppliersShareRate;
		marketAssets[market].suppliersShareRateUpdateTime = currentTime;

		emit SuppliersShareRateChanged(market, newSuppliersShareRate);
	}


	function addMarket (address market, uint borrowRate, uint suppliersShareRate) external onlyOwner {
		require(!marketAssets[market].isActive, "Market exists");
		require (borrowRate <= maxBorrowRate
			&& suppliersShareRate >= minSuppliersShareRate
			&& suppliersShareRate <= ratesDecimal
			, 'Rate should be in allowed range');

		marketAssets[market].isActive = true;
		marketAssets[market].borrowRate = borrowRate;
		marketAssets[market].borrowRateUpdateTime = block.timestamp;
		marketAssets[market].suppliersShareRate = suppliersShareRate;
		marketAssets[market].suppliersShareRateUpdateTime = block.timestamp;

		bool exist = false;
		for (uint i=0; i<marketsList.length; i++) {
			if (marketsList[i] == market){
				exist = true;
				break;
			}
		}

		if (!exist) {
			marketsList.push(market);
		}

		emit MarketAdded(market);
	}


	function removeMarket (address market) external onlyOwner {
		marketAssets[market].isActive = false;
		emit MarketRemoved(market);
	}


	function addCollateral (address collateralAsset, uint valueToLoanRate, uint penaltyRate, uint bonusRate) external onlyOwner {
		require(!collateralAssets[collateralAsset].isActive, "Collateral exists");
		require (valueToLoanRate <= maxValueToLoanRate
				&& penaltyRate <= maxPenaltyRate
				&& penaltyRate <= valueToLoanRate
				&& bonusRate <= penaltyRate
				&& bonusRate >= ratesDecimal
			,'Rate should be in allowed range');

		collateralAssets[collateralAsset].isActive = true;
		collateralAssets[collateralAsset].valueToLoanRate = valueToLoanRate;
		collateralAssets[collateralAsset].penaltyRate  = penaltyRate;
	    collateralAssets[collateralAsset].bonusRate = bonusRate;
	    collateralAssets[collateralAsset].VTLUpdateTime = block.timestamp;
	    collateralAssets[collateralAsset].penaltyUpdateTime = block.timestamp;

		emit CollateralAdded(collateralAsset, valueToLoanRate, penaltyRate, bonusRate);
	}


	function removeCollateral (address collateralAsset) external onlyOwner {
		collateralAssets[collateralAsset].isActive = false;
		emit CollateralRemoved(collateralAsset);
	}


	function setValueToLoanRate (address collateralAsset, uint newValueToLoanRate) external onlyOwner {
		require (newValueToLoanRate <= maxValueToLoanRate
				&& collateralAssets[collateralAsset].penaltyRate <= newValueToLoanRate
				,'Rate should be in allowed range');

		uint currentTime = block.timestamp;
		if (newValueToLoanRate > collateralAssets[collateralAsset].valueToLoanRate) {
			uint deltaTime = currentTime.sub(collateralAssets[collateralAsset].VTLUpdateTime);
			require (deltaTime >= secondsPerTenDays,'Increasing rate is not allowed at this time');
			uint maxIncrease = collateralAssets[collateralAsset].valueToLoanRate.add(valueToLoanRateMaxIncrease);
			require (newValueToLoanRate <= maxIncrease,'Rate should be increased less than max allowed');
		}
	    collateralAssets[collateralAsset].valueToLoanRate = newValueToLoanRate;
	    collateralAssets[collateralAsset].VTLUpdateTime = currentTime;

	    emit ValueToLoanRateChanged(collateralAsset, newValueToLoanRate);
	}


	function setPenaltyRate (address collateralAsset ,uint newPenaltyRate) external onlyOwner {
		require (newPenaltyRate <= maxPenaltyRate
				&& newPenaltyRate <= collateralAssets[collateralAsset].valueToLoanRate
				&& collateralAssets[collateralAsset].bonusRate <= newPenaltyRate
				,'Rate should be in allowed range');

		uint currentTime = block.timestamp;
		if (newPenaltyRate > collateralAssets[collateralAsset].penaltyRate){
			uint deltaTime = currentTime.sub(collateralAssets[collateralAsset].penaltyUpdateTime);
			require (deltaTime >= secondsPerTenDays,'Increasing rate is not allowed at this time');
			uint maxIncrease = collateralAssets[collateralAsset].penaltyRate.add(penaltyRateMaxIncrease);
			require (newPenaltyRate <= maxIncrease,'Rate should be increased less than max allowed');
		}
	    collateralAssets[collateralAsset].penaltyRate  = newPenaltyRate;
	    collateralAssets[collateralAsset].penaltyUpdateTime = currentTime;

	    emit PenaltyRateChanged(collateralAsset, newPenaltyRate);
	}


	function setBonusRate (address collateralAsset, uint newBonusRate) external onlyOwner {
		require (newBonusRate <= collateralAssets[collateralAsset].penaltyRate
				&& newBonusRate >= ratesDecimal
				,'Rate should be in allowed range');

	    collateralAssets[collateralAsset].bonusRate = newBonusRate;

	    emit BonusRateChanged(collateralAsset, newBonusRate);
	}

	function() payable external {
        revert();
    }
}
