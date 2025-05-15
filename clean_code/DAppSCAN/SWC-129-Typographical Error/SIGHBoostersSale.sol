
pragma experimental ABIEncoderV2;
pragma solidity 0.7.0;

import {Ownable} from "../dependencies/openzeppelin/access/Ownable.sol";
import {SafeMath} from "../dependencies/openzeppelin/math/SafeMath.sol";
import {ERC20} from "../dependencies/openzeppelin/token/ERC20/ERC20.sol";
import {BoostersStringUtils} from "../dependencies/BoostersDependencies/BoostersStringUtils.sol";

import {ISIGHBoosters} from "../../interfaces/NFTBoosters/ISIGHBoosters.sol";
import {ISIGHBoostersSale} from "../../interfaces/NFTBoosters/ISIGHBoostersSale.sol";
import {IERC721Receiver} from "../dependencies/openzeppelin/token/ERC721/IERC721Receiver.sol";

contract SIGHBoostersSale is IERC721Receiver,Ownable,ISIGHBoostersSale {

    using BoostersStringUtils for string;
    using SafeMath for uint256;

    ISIGHBoosters private _SIGH_NFT_BoostersContract;
    uint public initiateTimestamp;

    ERC20 private tokenAcceptedAsPayment;

    struct boosterList {
        uint256 totalAvailable;
        uint256[] boosterIdsList;
        uint256 salePrice;
        uint256 totalBoostersSold;
    }

    mapping (string => boosterList) private listOfBoosters;
    mapping (uint256 => bool) private boosterIdsForSale;
    mapping (string => bool) private boosterTypes;

    constructor(address _SIGHNFTBoostersContract) {
        require(_SIGHNFTBoostersContract != address(0),'SIGH Finance : Invalid _SIGHNFTBoostersContract address');
        _SIGH_NFT_BoostersContract = ISIGHBoosters(_SIGHNFTBoostersContract);
    }













    function updateSalePrice(string memory _BoosterType, uint256 _price ) external override onlyOwner {
        require( _SIGH_NFT_BoostersContract.isCategorySupported(_BoosterType),"Invalid Type");
        require( boosterTypes[_BoosterType] ,"Not yet initialized");
        listOfBoosters[_BoosterType].salePrice = _price;
        emit SalePriceUpdated(_BoosterType,_price);
    }


    function updateAcceptedToken(address token) external override onlyOwner {
        require( token != address(0) ,"Invalid address");
        tokenAcceptedAsPayment = ERC20(token);
        emit PaymentTokenUpdated(token);
    }


    function transferBalance(address to, uint amount) external override onlyOwner {
        require( to != address(0) ,"Invalid address");
        require( amount <= getCurrentFundsBalance() ,"Invalid amount");
        tokenAcceptedAsPayment.transfer(to,amount);
        emit FundsTransferred(amount);
    }


    function updateSaleTime(uint timestamp) external override onlyOwner {
        require( block.timestamp < timestamp,'Invalid stamp');
        initiateTimestamp = timestamp;
        emit SaleTimeUpdated(initiateTimestamp);
    }


    function transferTokens(address token, address to, uint amount) external override onlyOwner {
        require( to != address(0) ,"Invalid address");
        ERC20 token_ = ERC20(token);
        uint balance = token_.balanceOf(address(this));
        require( amount <= balance ,"Invalid amount");
        token_.transfer(to,amount);
        emit TokensTransferred(token,to,amount);
    }






    function buyBoosters(address receiver, string memory _BoosterType, uint boostersToBuy) override external {
        require( block.timestamp > initiateTimestamp,'Sale not begin');
        require(boostersToBuy >= 1,"Invalid number of boosters");
        require(boosterTypes[_BoosterType],"Invalid Booster Type");
        require(listOfBoosters[_BoosterType].totalAvailable >=  boostersToBuy,"Boosters not available");

        uint amountToBePaid = boostersToBuy.mul(listOfBoosters[_BoosterType].salePrice);

        require(transferFunds(msg.sender,amountToBePaid),'Funds transfer Failed');
        require(transferBoosters(receiver, _BoosterType, boostersToBuy),'Boosters transfer Failed');

        emit BoostersBought(msg.sender,receiver,_BoosterType,boostersToBuy,amountToBePaid);
    }






    function getBoosterSaleDetails(string memory _Boostertype) external view override returns (uint256 available,uint256 price, uint256 sold) {
        require( _SIGH_NFT_BoostersContract.isCategorySupported(_Boostertype),"SIGH Finance : Not a valid Booster Type");
        available = listOfBoosters[_Boostertype].totalAvailable;
        price = listOfBoosters[_Boostertype].salePrice;
        sold = listOfBoosters[_Boostertype].totalBoostersSold;
    }

    function getTokenAccepted() public view override returns(string memory symbol, address tokenAddress) {
        require( address(tokenAcceptedAsPayment) != address(0) );
        symbol = tokenAcceptedAsPayment.symbol();
        tokenAddress = address(tokenAcceptedAsPayment);
    }

    function getCurrentFundsBalance() public view override returns (uint256) {
        require( address(tokenAcceptedAsPayment) != address(0) );
        return tokenAcceptedAsPayment.balanceOf(address(this));
    }

    function getTokenBalance(address token) public view override returns (uint256) {
        require(address(tokenAcceptedAsPayment)!=address(0));
        ERC20 token_ = ERC20(token);
        uint balance = token_.balanceOf(address(this));
        return balance;
    }





    function addBoosterForSaleInternal(uint256 boosterId) internal {
        require( !boosterIdsForSale[boosterId], "Already Added");
        ( , string memory _BoosterType, , ) = _SIGH_NFT_BoostersContract.getBoosterInfo(boosterId);

        if (!boosterTypes[_BoosterType]) {
            boosterTypes[_BoosterType] = true;
        }

        listOfBoosters[_BoosterType].boosterIdsList.push( boosterId );
        listOfBoosters[_BoosterType].totalAvailable = listOfBoosters[_BoosterType].totalAvailable.add(1);
        boosterIdsForSale[boosterId] = true;
        emit BoosterAddedForSale(_BoosterType , boosterId);
    }


    function transferBoosters(address to, string memory _BoosterType, uint totalBoosters) internal returns (bool) {
        uint listLength = listOfBoosters[_BoosterType].boosterIdsList.length;

        for (uint i=0; i < totalBoosters; i++ ) {
            uint256 _boosterId = listOfBoosters[_BoosterType].boosterIdsList[0];

            if (boosterIdsForSale[_boosterId]) {

                _SIGH_NFT_BoostersContract.safeTransferFrom(address(this),to,_boosterId);
                require(to == _SIGH_NFT_BoostersContract.ownerOfBooster(_boosterId),"Booster Transfer failed");


                listOfBoosters[_BoosterType].boosterIdsList[0] = listOfBoosters[_BoosterType].boosterIdsList[listLength.sub(1)];
                listOfBoosters[_BoosterType].boosterIdsList.pop();
                listLength = listLength.sub(1);


                listOfBoosters[_BoosterType].totalAvailable = listOfBoosters[_BoosterType].totalAvailable.sub(1);
                listOfBoosters[_BoosterType].totalBoostersSold = listOfBoosters[_BoosterType].totalBoostersSold.add(1);


                boosterIdsForSale[_boosterId] = false;

                emit BoosterSold(to, _BoosterType, _boosterId, listOfBoosters[_BoosterType].salePrice );
            }
        }
        return true;
    }


    function transferFunds(address from, uint amount) internal returns (bool) {
        uint prevBalance = tokenAcceptedAsPayment.balanceOf(address(this));
        tokenAcceptedAsPayment.transferFrom(from,address(this),amount);
        uint newBalance = tokenAcceptedAsPayment.balanceOf(address(this));
        require(newBalance == prevBalance.add(amount),'Funds Transfer failed');
        return true;
    }





    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory _data) public virtual override returns (bytes4) {
        addBoosterForSaleInternal(tokenId);
        emit BoosterAdded(operator,from,tokenId);
        return this.onERC721Received.selector;
    }
}
