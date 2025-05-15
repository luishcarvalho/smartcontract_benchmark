



pragma solidity 0.5.7;



interface ICore {

    function TRANSFERPROXY290()
        external
        view
        returns (address);


    function VAULT497()
        external
        view
        returns (address);


    function EXCHANGEIDS396(
        uint8 _exchangeId
    )
        external
        view
        returns (address);


    function VALIDSETS319(address)
        external
        view
        returns (bool);


    function VALIDMODULES100(address)
        external
        view
        returns (bool);


    function VALIDPRICELIBRARIES391(
        address _priceLibrary
    )
        external
        view
        returns (bool);


    function ISSUE203(
        address _set,
        uint256 _quantity
    )
        external;


    function ISSUETO740(
        address _recipient,
        address _set,
        uint256 _quantity
    )
        external;


    function ISSUEINVAULT15(
        address _set,
        uint256 _quantity
    )
        external;


    function REDEEM524(
        address _set,
        uint256 _quantity
    )
        external;


    function REDEEMTO270(
        address _recipient,
        address _set,
        uint256 _quantity
    )
        external;


    function REDEEMINVAULT358(
        address _set,
        uint256 _quantity
    )
        external;


    function REDEEMANDWITHDRAWTO873(
        address _set,
        address _to,
        uint256 _quantity,
        uint256 _toExclude
    )
        external;


    function BATCHDEPOSIT892(
        address[] calldata _tokens,
        uint256[] calldata _quantities
    )
        external;


    function BATCHWITHDRAW872(
        address[] calldata _tokens,
        uint256[] calldata _quantities
    )
        external;


    function DEPOSIT357(
        address _token,
        uint256 _quantity
    )
        external;


    function WITHDRAW715(
        address _token,
        uint256 _quantity
    )
        external;


    function INTERNALTRANSFER147(
        address _token,
        address _to,
        uint256 _quantity
    )
        external;


    function CREATESET426(
        address _factory,
        address[] calldata _components,
        uint256[] calldata _units,
        uint256 _naturalUnit,
        bytes32 _name,
        bytes32 _symbol,
        bytes calldata _callData
    )
        external
        returns (address);


    function DEPOSITMODULE827(
        address _from,
        address _to,
        address _token,
        uint256 _quantity
    )
        external;


    function WITHDRAWMODULE670(
        address _from,
        address _to,
        address _token,
        uint256 _quantity
    )
        external;


    function BATCHDEPOSITMODULE88(
        address _from,
        address _to,
        address[] calldata _tokens,
        uint256[] calldata _quantities
    )
        external;


    function BATCHWITHDRAWMODULE533(
        address _from,
        address _to,
        address[] calldata _tokens,
        uint256[] calldata _quantities
    )
        external;


    function ISSUEMODULE367(
        address _owner,
        address _recipient,
        address _set,
        uint256 _quantity
    )
        external;


    function REDEEMMODULE605(
        address _burnAddress,
        address _incrementAddress,
        address _set,
        uint256 _quantity
    )
        external;


    function BATCHINCREMENTTOKENOWNERMODULE149(
        address[] calldata _tokens,
        address _owner,
        uint256[] calldata _quantities
    )
        external;


    function BATCHDECREMENTTOKENOWNERMODULE440(
        address[] calldata _tokens,
        address _owner,
        uint256[] calldata _quantities
    )
        external;


    function BATCHTRANSFERBALANCEMODULE930(
        address[] calldata _tokens,
        address _from,
        address _to,
        uint256[] calldata _quantities
    )
        external;


    function TRANSFERMODULE315(
        address _token,
        uint256 _quantity,
        address _from,
        address _to
    )
        external;


    function BATCHTRANSFERMODULE23(
        address[] calldata _tokens,
        uint256[] calldata _quantities,
        address _from,
        address _to
    )
        external;
}





pragma solidity 0.5.7;



library RebalancingLibrary {



    enum State { Default, Proposal, Rebalance, Drawdown }



    struct AuctionPriceParameters {
        uint256 auctionStartTime;
        uint256 auctionTimeToPivot;
        uint256 auctionStartPrice;
        uint256 auctionPivotPrice;
    }

    struct BiddingParameters {
        uint256 minimumBid;
        uint256 remainingCurrentSets;
        uint256[] combinedCurrentUnits;
        uint256[] combinedNextSetUnits;
        address[] combinedTokenArray;
    }
}





pragma solidity 0.5.7;


interface IFeeCalculator {



    function INITIALIZE627(
        bytes calldata _feeCalculatorData
    )
        external;

    function GETFEE645()
        external
        view
        returns(uint256);

    function UPDATEANDGETFEE787()
        external
        returns(uint256);

    function ADJUSTFEE487(
        bytes calldata _newFeeData
    )
        external;
}





pragma solidity 0.5.7;


interface ISetToken {




    function NATURALUNIT908()
        external
        view
        returns (uint256);


    function GETCOMPONENTS458()
        external
        view
        returns (address[] memory);


    function GETUNITS229()
        external
        view
        returns (uint256[] memory);


    function TOKENISCOMPONENT45(
        address _tokenAddress
    )
        external
        view
        returns (bool);


    function MINT918(
        address _issuer,
        uint256 _quantity
    )
        external;


    function BURN396(
        address _from,
        uint256 _quantity
    )
        external;


    function TRANSFER558(
        address to,
        uint256 value
    )
        external;
}





pragma solidity 0.5.7;




interface IRebalancingSetToken {


    function AUCTIONLIBRARY983()
        external
        view
        returns (address);


    function TOTALSUPPLY978()
        external
        view
        returns (uint256);


    function PROPOSALSTARTTIME533()
        external
        view
        returns (uint256);


    function LASTREBALANCETIMESTAMP491()
        external
        view
        returns (uint256);


    function REBALANCEINTERVAL619()
        external
        view
        returns (uint256);


    function REBALANCESTATE812()
        external
        view
        returns (RebalancingLibrary.State);


    function STARTINGCURRENTSETAMOUNT132()
        external
        view
        returns (uint256);


    function BALANCEOF827(
        address owner
    )
        external
        view
        returns (uint256);


    function PROPOSE395(
        address _nextSet,
        address _auctionLibrary,
        uint256 _auctionTimeToPivot,
        uint256 _auctionStartPrice,
        uint256 _auctionPivotPrice
    )
        external;


    function NATURALUNIT908()
        external
        view
        returns (uint256);


    function CURRENTSET165()
        external
        view
        returns (address);


    function NEXTSET94()
        external
        view
        returns (address);


    function UNITSHARES97()
        external
        view
        returns (uint256);


    function BURN396(
        address _from,
        uint256 _quantity
    )
        external;


    function PLACEBID341(
        uint256 _quantity
    )
        external
        returns (address[] memory, uint256[] memory, uint256[] memory);


    function GETCOMBINEDTOKENARRAYLENGTH557()
        external
        view
        returns (uint256);


    function GETCOMBINEDTOKENARRAY587()
        external
        view
        returns (address[] memory);


    function GETFAILEDAUCTIONWITHDRAWCOMPONENTS419()
        external
        view
        returns (address[] memory);


    function GETAUCTIONPRICEPARAMETERS272()
        external
        view
        returns (uint256[] memory);


    function GETBIDDINGPARAMETERS33()
        external
        view
        returns (uint256[] memory);


    function GETBIDPRICE601(
        uint256 _quantity
    )
        external
        view
        returns (uint256[] memory, uint256[] memory);

}





pragma solidity 0.5.7;




library Rebalance {

    struct TokenFlow {
        address[] addresses;
        uint256[] inflow;
        uint256[] outflow;
    }

    function COMPOSETOKENFLOW703(
        address[] memory _addresses,
        uint256[] memory _inflow,
        uint256[] memory _outflow
    )
        internal
        pure
        returns(TokenFlow memory)
    {
        return TokenFlow({addresses: _addresses, inflow: _inflow, outflow: _outflow });
    }

    function DECOMPOSETOKENFLOW508(TokenFlow memory _tokenFlow)
        internal
        pure
        returns (address[] memory, uint256[] memory, uint256[] memory)
    {
        return (_tokenFlow.addresses, _tokenFlow.inflow, _tokenFlow.outflow);
    }

    function DECOMPOSETOKENFLOWTOBIDPRICE741(TokenFlow memory _tokenFlow)
        internal
        pure
        returns (uint256[] memory, uint256[] memory)
    {
        return (_tokenFlow.inflow, _tokenFlow.outflow);
    }


    function GETTOKENFLOWS792(
        IRebalancingSetToken _rebalancingSetToken,
        uint256 _quantity
    )
        internal
        view
        returns (address[] memory, uint256[] memory, uint256[] memory)
    {

        address[] memory combinedTokenArray = _rebalancingSetToken.GETCOMBINEDTOKENARRAY587();


        (
            uint256[] memory inflowArray,
            uint256[] memory outflowArray
        ) = _rebalancingSetToken.GETBIDPRICE601(_quantity);

        return (combinedTokenArray, inflowArray, outflowArray);
    }
}





pragma solidity 0.5.7;





interface ILiquidator {



    function STARTREBALANCE53(
        ISetToken _currentSet,
        ISetToken _nextSet,
        uint256 _startingCurrentSetQuantity,
        bytes calldata _liquidatorData
    )
        external;

    function GETBIDPRICE601(
        address _set,
        uint256 _quantity
    )
        external
        view
        returns (Rebalance.TokenFlow memory);

    function PLACEBID341(
        uint256 _quantity
    )
        external
        returns (Rebalance.TokenFlow memory);


    function SETTLEREBALANCE859()
        external;

    function ENDFAILEDREBALANCE906() external;





    function AUCTIONPRICEPARAMETERS855(address _set)
        external
        view
        returns (RebalancingLibrary.AuctionPriceParameters memory);





    function HASREBALANCEFAILED531(address _set) external view returns (bool);
    function MINIMUMBID335(address _set) external view returns (uint256);
    function STARTINGCURRENTSETS972(address _set) external view returns (uint256);
    function REMAININGCURRENTSETS800(address _set) external view returns (uint256);
    function GETCOMBINEDCURRENTSETUNITS997(address _set) external view returns (uint256[] memory);
    function GETCOMBINEDNEXTSETUNITS743(address _set) external view returns (uint256[] memory);
    function GETCOMBINEDTOKENARRAY587(address _set) external view returns (address[] memory);
}





pragma solidity 0.5.7;







interface IRebalancingSetTokenV2 {


    function TOTALSUPPLY978()
        external
        view
        returns (uint256);


    function LIQUIDATOR933()
        external
        view
        returns (ILiquidator);


    function LASTREBALANCETIMESTAMP491()
        external
        view
        returns (uint256);


    function REBALANCESTARTTIME708()
        external
        view
        returns (uint256);


    function STARTINGCURRENTSETAMOUNT132()
        external
        view
        returns (uint256);


    function REBALANCEINTERVAL619()
        external
        view
        returns (uint256);


    function GETAUCTIONPRICEPARAMETERS272() external view returns (uint256[] memory);


    function GETBIDDINGPARAMETERS33() external view returns (uint256[] memory);


    function REBALANCESTATE812()
        external
        view
        returns (RebalancingLibrary.State);


    function BALANCEOF827(
        address owner
    )
        external
        view
        returns (uint256);


    function MANAGER161()
        external
        view
        returns (address);


    function FEERECIPIENT200()
        external
        view
        returns (address);


    function ENTRYFEE977()
        external
        view
        returns (uint256);


    function REBALANCEFEE979()
        external
        view
        returns (uint256);


    function REBALANCEFEECALCULATOR847()
        external
        view
        returns (IFeeCalculator);


    function INITIALIZE627(
        bytes calldata _rebalanceFeeCalldata
    )
        external;


    function SETLIQUIDATOR462(
        ILiquidator _newLiquidator
    )
        external;


    function SETFEERECIPIENT786(
        address _newFeeRecipient
    )
        external;


    function SETENTRYFEE61(
        uint256 _newEntryFee
    )
        external;


    function STARTREBALANCE53(
        address _nextSet,
        bytes calldata _liquidatorData

    )
        external;


    function SETTLEREBALANCE859()
        external;


    function NATURALUNIT908()
        external
        view
        returns (uint256);


    function CURRENTSET165()
        external
        view
        returns (ISetToken);


    function NEXTSET94()
        external
        view
        returns (ISetToken);


    function UNITSHARES97()
        external
        view
        returns (uint256);


    function PLACEBID341(
        uint256 _quantity
    )
        external
        returns (address[] memory, uint256[] memory, uint256[] memory);


    function GETBIDPRICE601(
        uint256 _quantity
    )
        external
        view
        returns (uint256[] memory, uint256[] memory);


    function NAME118()
        external
        view
        returns (string memory);


    function SYMBOL994()
        external
        view
        returns (string memory);
}





pragma solidity 0.5.7;







interface IRebalancingSetTokenV3 {


    function TOTALSUPPLY978()
        external
        view
        returns (uint256);


    function LIQUIDATOR933()
        external
        view
        returns (ILiquidator);


    function LASTREBALANCETIMESTAMP491()
        external
        view
        returns (uint256);


    function REBALANCESTARTTIME708()
        external
        view
        returns (uint256);


    function STARTINGCURRENTSETAMOUNT132()
        external
        view
        returns (uint256);


    function REBALANCEINTERVAL619()
        external
        view
        returns (uint256);


    function GETAUCTIONPRICEPARAMETERS272() external view returns (uint256[] memory);


    function GETBIDDINGPARAMETERS33() external view returns (uint256[] memory);


    function REBALANCESTATE812()
        external
        view
        returns (RebalancingLibrary.State);


    function BALANCEOF827(
        address owner
    )
        external
        view
        returns (uint256);


    function MANAGER161()
        external
        view
        returns (address);


    function FEERECIPIENT200()
        external
        view
        returns (address);


    function ENTRYFEE977()
        external
        view
        returns (uint256);


    function REBALANCEFEE979()
        external
        view
        returns (uint256);


    function REBALANCEFEECALCULATOR847()
        external
        view
        returns (IFeeCalculator);


    function INITIALIZE627(
        bytes calldata _rebalanceFeeCalldata
    )
        external;


    function SETLIQUIDATOR462(
        ILiquidator _newLiquidator
    )
        external;


    function SETFEERECIPIENT786(
        address _newFeeRecipient
    )
        external;


    function SETENTRYFEE61(
        uint256 _newEntryFee
    )
        external;


    function STARTREBALANCE53(
        address _nextSet,
        bytes calldata _liquidatorData

    )
        external;


    function SETTLEREBALANCE859()
        external;


    function ACTUALIZEFEE454()
        external;


    function ADJUSTFEE487(
        bytes calldata _newFeeData
    )
        external;


    function NATURALUNIT908()
        external
        view
        returns (uint256);


    function CURRENTSET165()
        external
        view
        returns (ISetToken);


    function NEXTSET94()
        external
        view
        returns (ISetToken);


    function UNITSHARES97()
        external
        view
        returns (uint256);


    function PLACEBID341(
        uint256 _quantity
    )
        external
        returns (address[] memory, uint256[] memory, uint256[] memory);


    function GETBIDPRICE601(
        uint256 _quantity
    )
        external
        view
        returns (uint256[] memory, uint256[] memory);


    function NAME118()
        external
        view
        returns (string memory);


    function SYMBOL994()
        external
        view
        returns (string memory);
}



pragma solidity ^0.5.2;


library SafeMath {

    function MUL940(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }


    function DIV983(uint256 a, uint256 b) internal pure returns (uint256) {

        require(b > 0);
        uint256 c = a / b;


        return c;
    }


    function SUB806(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }


    function ADD949(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }


    function MOD276(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}



pragma solidity ^0.5.2;


contract Ownable {
    address private _owner;

    event OWNERSHIPTRANSFERRED84(address indexed previousOwner, address indexed newOwner);


    constructor () internal {
        _owner = msg.sender;
        emit OWNERSHIPTRANSFERRED84(address(0), _owner);
    }


    function OWNER334() public view returns (address) {
        return _owner;
    }


    modifier ONLYOWNER733() {
        require(ISOWNER347());
        _;
    }


    function ISOWNER347() public view returns (bool) {
        return msg.sender == _owner;
    }


    function RENOUNCEOWNERSHIP178() public ONLYOWNER733 {
        emit OWNERSHIPTRANSFERRED84(_owner, address(0));
        _owner = address(0);
    }


    function TRANSFEROWNERSHIP217(address newOwner) public ONLYOWNER733 {
        _TRANSFEROWNERSHIP828(newOwner);
    }


    function _TRANSFEROWNERSHIP828(address newOwner) internal {
        require(newOwner != address(0));
        emit OWNERSHIPTRANSFERRED84(_owner, newOwner);
        _owner = newOwner;
    }
}





pragma solidity 0.5.7;





contract TimeLockUpgrade is
    Ownable
{
    using SafeMath for uint256;




    uint256 public timeLockPeriod;


    mapping(bytes32 => uint256) public timeLockedUpgrades;



    event UPGRADEREGISTERED246(
        bytes32 _upgradeHash,
        uint256 _timestamp
    );



    modifier TIMELOCKUPGRADE701() {


        if (timeLockPeriod == 0) {
            _;

            return;
        }



        bytes32 upgradeHash = keccak256(
            abi.encodePacked(
                msg.data
            )
        );

        uint256 registrationTime = timeLockedUpgrades[upgradeHash];


        if (registrationTime == 0) {
            timeLockedUpgrades[upgradeHash] = block.timestamp;

            emit UPGRADEREGISTERED246(
                upgradeHash,
                block.timestamp
            );

            return;
        }

        require(
            block.timestamp >= registrationTime.ADD949(timeLockPeriod),
            "TimeLockUpgrade: Time lock period must have elapsed."
        );


        timeLockedUpgrades[upgradeHash] = 0;


        _;
    }




    function SETTIMELOCKPERIOD792(
        uint256 _timeLockPeriod
    )
        external
        ONLYOWNER733
    {

        require(
            _timeLockPeriod > timeLockPeriod,
            "TimeLockUpgrade: New period must be greater than existing"
        );

        timeLockPeriod = _timeLockPeriod;
    }
}





pragma solidity 0.5.7;






contract UnrestrictedTimeLockUpgrade is
    TimeLockUpgrade
{


    event REMOVEREGISTEREDUPGRADE343(
        bytes32 indexed _upgradeHash
    );




    function REMOVEREGISTEREDUPGRADEINTERNAL162(
        bytes32 _upgradeHash
    )
        internal
    {
        require(
            timeLockedUpgrades[_upgradeHash] != 0,
            "TimeLockUpgradeV2.removeRegisteredUpgrade: Upgrade hash must be registered"
        );


        timeLockedUpgrades[_upgradeHash] = 0;

        emit REMOVEREGISTEREDUPGRADE343(
            _upgradeHash
        );
    }
}





pragma solidity 0.5.7;





contract LimitOneUpgrade is
    UnrestrictedTimeLockUpgrade
{


    mapping(address => bytes32) public upgradeIdentifier;




    modifier LIMITONEUPGRADE170(address _upgradeAddress) {
        if (timeLockPeriod > 0) {

            bytes32 upgradeHash = keccak256(msg.data);

            if (upgradeIdentifier[_upgradeAddress] != 0) {

                require(
                    upgradeIdentifier[_upgradeAddress] == upgradeHash,
                    "Another update already in progress."
                );

                upgradeIdentifier[_upgradeAddress] = 0;

            } else {
                upgradeIdentifier[_upgradeAddress] = upgradeHash;
            }
        }
        _;
    }


    function REMOVEREGISTEREDUPGRADEINTERNAL162(
        address _upgradeAddress,
        bytes32 _upgradeHash
    )
        internal
    {
        require(
            upgradeIdentifier[_upgradeAddress] == _upgradeHash,
            "Passed upgrade hash does not match upgrade address."
        );

        UnrestrictedTimeLockUpgrade.REMOVEREGISTEREDUPGRADEINTERNAL162(_upgradeHash);

        upgradeIdentifier[_upgradeAddress] = 0;
    }
}






pragma solidity 0.5.7;


library AddressArrayUtils {


    function INDEXOF640(address[] memory A, address a) internal pure returns (uint256, bool) {
        uint256 length = A.length;
        for (uint256 i = 0; i < length; i++) {
            if (A[i] == a) {
                return (i, true);
            }
        }
        return (0, false);
    }


    function CONTAINS824(address[] memory A, address a) internal pure returns (bool) {
        bool isIn;
        (, isIn) = INDEXOF640(A, a);
        return isIn;
    }


    function EXTEND286(address[] memory A, address[] memory B) internal pure returns (address[] memory) {
        uint256 aLength = A.length;
        uint256 bLength = B.length;
        address[] memory newAddresses = new address[](aLength + bLength);
        for (uint256 i = 0; i < aLength; i++) {
            newAddresses[i] = A[i];
        }
        for (uint256 j = 0; j < bLength; j++) {
            newAddresses[aLength + j] = B[j];
        }
        return newAddresses;
    }


    function APPEND631(address[] memory A, address a) internal pure returns (address[] memory) {
        address[] memory newAddresses = new address[](A.length + 1);
        for (uint256 i = 0; i < A.length; i++) {
            newAddresses[i] = A[i];
        }
        newAddresses[A.length] = a;
        return newAddresses;
    }


    function INTERSECT449(address[] memory A, address[] memory B) internal pure returns (address[] memory) {
        uint256 length = A.length;
        bool[] memory includeMap = new bool[](length);
        uint256 newLength = 0;
        for (uint256 i = 0; i < length; i++) {
            if (CONTAINS824(B, A[i])) {
                includeMap[i] = true;
                newLength++;
            }
        }
        address[] memory newAddresses = new address[](newLength);
        uint256 j = 0;
        for (uint256 k = 0; k < length; k++) {
            if (includeMap[k]) {
                newAddresses[j] = A[k];
                j++;
            }
        }
        return newAddresses;
    }


    function UNION513(address[] memory A, address[] memory B) internal pure returns (address[] memory) {
        address[] memory leftDifference = DIFFERENCE589(A, B);
        address[] memory rightDifference = DIFFERENCE589(B, A);
        address[] memory intersection = INTERSECT449(A, B);
        return EXTEND286(leftDifference, EXTEND286(intersection, rightDifference));
    }


    function DIFFERENCE589(address[] memory A, address[] memory B) internal pure returns (address[] memory) {
        uint256 length = A.length;
        bool[] memory includeMap = new bool[](length);
        uint256 count = 0;

        for (uint256 i = 0; i < length; i++) {
            address e = A[i];
            if (!CONTAINS824(B, e)) {
                includeMap[i] = true;
                count++;
            }
        }
        address[] memory newAddresses = new address[](count);
        uint256 j = 0;
        for (uint256 k = 0; k < length; k++) {
            if (includeMap[k]) {
                newAddresses[j] = A[k];
                j++;
            }
        }
        return newAddresses;
    }


    function POP272(address[] memory A, uint256 index)
        internal
        pure
        returns (address[] memory, address)
    {
        uint256 length = A.length;
        address[] memory newAddresses = new address[](length - 1);
        for (uint256 i = 0; i < index; i++) {
            newAddresses[i] = A[i];
        }
        for (uint256 j = index + 1; j < length; j++) {
            newAddresses[j - 1] = A[j];
        }
        return (newAddresses, A[index]);
    }


    function REMOVE947(address[] memory A, address a)
        internal
        pure
        returns (address[] memory)
    {
        (uint256 index, bool isIn) = INDEXOF640(A, a);
        if (!isIn) {
            revert();
        } else {
            (address[] memory _A,) = POP272(A, index);
            return _A;
        }
    }


    function HASDUPLICATE629(address[] memory A) internal pure returns (bool) {
        if (A.length == 0) {
            return false;
        }
        for (uint256 i = 0; i < A.length - 1; i++) {
            for (uint256 j = i + 1; j < A.length; j++) {
                if (A[i] == A[j]) {
                    return true;
                }
            }
        }
        return false;
    }


    function ISEQUAL297(address[] memory A, address[] memory B) internal pure returns (bool) {
        if (A.length != B.length) {
            return false;
        }
        for (uint256 i = 0; i < A.length; i++) {
            if (A[i] != B[i]) {
                return false;
            }
        }
        return true;
    }
}





pragma solidity 0.5.7;






contract WhiteList is
    Ownable,
    TimeLockUpgrade
{
    using AddressArrayUtils for address[];



    address[] public addresses;
    mapping(address => bool) public whiteList;



    event ADDRESSADDED659(
        address _address
    );

    event ADDRESSREMOVED325(
        address _address
    );




    constructor(
        address[] memory _initialAddresses
    )
        public
    {

        for (uint256 i = 0; i < _initialAddresses.length; i++) {
            address addressToAdd = _initialAddresses[i];

            addresses.push(addressToAdd);
            whiteList[addressToAdd] = true;
        }
    }




    function ADDADDRESS683(
        address _address
    )
        external
        ONLYOWNER733
        TIMELOCKUPGRADE701
    {
        require(
            !whiteList[_address],
            "WhiteList.addAddress: Address has already been whitelisted."
        );

        addresses.push(_address);

        whiteList[_address] = true;

        emit ADDRESSADDED659(
            _address
        );
    }


    function REMOVEADDRESS177(
        address _address
    )
        external
        ONLYOWNER733
    {
        require(
            whiteList[_address],
            "WhiteList.removeAddress: Address is not current whitelisted."
        );

        addresses = addresses.REMOVE947(_address);

        whiteList[_address] = false;

        emit ADDRESSREMOVED325(
            _address
        );
    }


    function VALIDADDRESSES284()
        external
        view
        returns (address[] memory)
    {
        return addresses;
    }


    function AREVALIDADDRESSES358(
        address[] calldata _addresses
    )
        external
        view
        returns (bool)
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            if (!whiteList[_addresses[i]]) {
                return false;
            }
        }

        return true;
    }
}





pragma solidity 0.5.7;



interface ISocialAllocator {


    function DETERMINENEWALLOCATION631(
        uint256 _targetBaseAssetAllocation
    )
        external
        returns (ISetToken);


    function CALCULATECOLLATERALSETVALUE480(
        ISetToken _collateralSet
    )
        external
        view
        returns(uint256);
}





pragma solidity 0.5.7;




library SocialTradingLibrary {


    struct PoolInfo {
        address trader;
        ISocialAllocator allocator;
        uint256 currentAllocation;
        uint256 newEntryFee;
        uint256 feeUpdateTimestamp;
    }
}





pragma solidity 0.5.7;












contract SocialTradingManager is
    WhiteList
{
    using SafeMath for uint256;



    event TRADINGPOOLCREATED990(
        address indexed trader,
        ISocialAllocator indexed allocator,
        address indexed tradingPool,
        uint256 startingAllocation
    );

    event ALLOCATIONUPDATE207(
        address indexed tradingPool,
        uint256 oldAllocation,
        uint256 newAllocation
    );

    event NEWTRADER325(
        address indexed tradingPool,
        address indexed oldTrader,
        address indexed newTrader
    );



    modifier ONLYTRADER541(IRebalancingSetTokenV2 _tradingPool) {
        require(
            msg.sender == TRADER685(_tradingPool),
            "Sender must be trader"
        );
        _;
    }



    uint256 public constant rebalancing_set_natural_unit564 = 1e8;
    uint public constant one_percent337 = 1e16;
    uint256 constant public maximum_allocation339 = 1e18;



    ICore public core;
    address public factory;
    mapping(address => SocialTradingLibrary.PoolInfo) public pools;

    uint256 public maxEntryFee;
    uint256 public feeUpdateTimelock;


    constructor(
        ICore _core,
        address _factory,
        address[] memory _whiteListedAllocators,
        uint256 _maxEntryFee,
        uint256 _feeUpdateTimelock
    )
        public
        WhiteList(_whiteListedAllocators)
    {
        core = _core;
        factory = _factory;

        maxEntryFee = _maxEntryFee;
        feeUpdateTimelock = _feeUpdateTimelock;
    }




    function CREATETRADINGPOOL384(
        ISocialAllocator _tradingPairAllocator,
        uint256 _startingBaseAssetAllocation,
        uint256 _startingUSDValue,
        bytes32 _name,
        bytes32 _symbol,
        bytes calldata _rebalancingSetCallData
    )
        external
    {

        VALIDATECREATETRADINGPOOL868(_tradingPairAllocator, _startingBaseAssetAllocation, _rebalancingSetCallData);


        ISetToken collateralSet = _tradingPairAllocator.DETERMINENEWALLOCATION631(
            _startingBaseAssetAllocation
        );

        uint256[] memory unitShares = new uint256[](1);


        uint256 collateralValue = _tradingPairAllocator.CALCULATECOLLATERALSETVALUE480(
            collateralSet
        );


        unitShares[0] = _startingUSDValue.MUL940(rebalancing_set_natural_unit564).DIV983(collateralValue);

        address[] memory components = new address[](1);
        components[0] = address(collateralSet);


        address tradingPool = core.CREATESET426(
            factory,
            components,
            unitShares,
            rebalancing_set_natural_unit564,
            _name,
            _symbol,
            _rebalancingSetCallData
        );

        pools[tradingPool].trader = msg.sender;
        pools[tradingPool].allocator = _tradingPairAllocator;
        pools[tradingPool].currentAllocation = _startingBaseAssetAllocation;
        pools[tradingPool].feeUpdateTimestamp = 0;

        emit TRADINGPOOLCREATED990(
            msg.sender,
            _tradingPairAllocator,
            tradingPool,
            _startingBaseAssetAllocation
        );
    }


    function UPDATEALLOCATION788(
        IRebalancingSetTokenV2 _tradingPool,
        uint256 _newAllocation,
        bytes calldata _liquidatorData
    )
        external
        ONLYTRADER541(_tradingPool)
    {

        VALIDATEALLOCATIONUPDATE492(_tradingPool, _newAllocation);


        ISetToken nextSet = ALLOCATOR261(_tradingPool).DETERMINENEWALLOCATION631(
            _newAllocation
        );


        _tradingPool.STARTREBALANCE53(address(nextSet), _liquidatorData);

        emit ALLOCATIONUPDATE207(
            address(_tradingPool),
            CURRENTALLOCATION387(_tradingPool),
            _newAllocation
        );


        pools[address(_tradingPool)].currentAllocation = _newAllocation;
    }


    function INITIATEENTRYFEECHANGE772(
        IRebalancingSetTokenV2 _tradingPool,
        uint256 _newEntryFee
    )
        external
        ONLYTRADER541(_tradingPool)
    {

        VALIDATENEWENTRYFEE141(_newEntryFee);


        pools[address(_tradingPool)].feeUpdateTimestamp = block.timestamp.ADD949(feeUpdateTimelock);
        pools[address(_tradingPool)].newEntryFee = _newEntryFee;
    }


    function FINALIZEENTRYFEECHANGE511(
        IRebalancingSetTokenV2 _tradingPool
    )
        external
        ONLYTRADER541(_tradingPool)
    {

        require(
            FEEUPDATETIMESTAMP466(_tradingPool) != 0,
            "SocialTradingManager.finalizeSetFeeRecipient: Must initiate fee change first."
        );


        require(
            block.timestamp >= FEEUPDATETIMESTAMP466(_tradingPool),
            "SocialTradingManager.finalizeSetFeeRecipient: Time lock period must elapse to update fees."
        );


        pools[address(_tradingPool)].feeUpdateTimestamp = 0;


        _tradingPool.SETENTRYFEE61(NEWENTRYFEE285(_tradingPool));


        pools[address(_tradingPool)].newEntryFee = 0;
    }


    function SETTRADER910(
        IRebalancingSetTokenV2 _tradingPool,
        address _newTrader
    )
        external
        ONLYTRADER541(_tradingPool)
    {
        emit NEWTRADER325(
            address(_tradingPool),
            TRADER685(_tradingPool),
            _newTrader
        );

        pools[address(_tradingPool)].trader = _newTrader;
    }


    function SETLIQUIDATOR462(
        IRebalancingSetTokenV2 _tradingPool,
        ILiquidator _newLiquidator
    )
        external
        ONLYTRADER541(_tradingPool)
    {
        _tradingPool.SETLIQUIDATOR462(_newLiquidator);
    }


    function SETFEERECIPIENT786(
        IRebalancingSetTokenV2 _tradingPool,
        address _newFeeRecipient
    )
        external
        ONLYTRADER541(_tradingPool)
    {
        _tradingPool.SETFEERECIPIENT786(_newFeeRecipient);
    }




    function VALIDATECREATETRADINGPOOL868(
        ISocialAllocator _tradingPairAllocator,
        uint256 _startingBaseAssetAllocation,
        bytes memory _rebalancingSetCallData
    )
        internal
        view
    {
        VALIDATEALLOCATIONAMOUNT616(_startingBaseAssetAllocation);

        VALIDATEMANAGERADDRESS45(_rebalancingSetCallData);

        require(
            whiteList[address(_tradingPairAllocator)],
            "SocialTradingManager.validateCreateTradingPool: Passed allocator is not valid."
        );
    }


    function VALIDATEALLOCATIONUPDATE492(
        IRebalancingSetTokenV2 _tradingPool,
        uint256 _newAllocation
    )
        internal
        view
    {
        VALIDATEALLOCATIONAMOUNT616(_newAllocation);


        uint256 currentAllocationValue = CURRENTALLOCATION387(_tradingPool);
        require(
            !(currentAllocationValue == maximum_allocation339 && _newAllocation == maximum_allocation339) &&
            !(currentAllocationValue == 0 && _newAllocation == 0),
            "SocialTradingManager.validateAllocationUpdate: Invalid allocation"
        );


        uint256 lastRebalanceTimestamp = _tradingPool.LASTREBALANCETIMESTAMP491();
        uint256 rebalanceInterval = _tradingPool.REBALANCEINTERVAL619();
        require(
            block.timestamp >= lastRebalanceTimestamp.ADD949(rebalanceInterval),
            "SocialTradingManager.validateAllocationUpdate: Rebalance interval not elapsed"
        );



        require(
            _tradingPool.REBALANCESTATE812() == RebalancingLibrary.State.Default,
            "SocialTradingManager.validateAllocationUpdate: State must be in Default"
        );
    }


    function VALIDATEALLOCATIONAMOUNT616(
        uint256 _allocation
    )
        internal
        view
    {
        require(
            _allocation <= maximum_allocation339,
            "Passed allocation must not exceed 100%."
        );

        require(
            _allocation.MOD276(one_percent337) == 0,
            "Passed allocation must be multiple of 1%."
        );
    }


    function VALIDATENEWENTRYFEE141(
        uint256 _entryFee
    )
        internal
        view
    {
        require(
            _entryFee <= maxEntryFee,
            "SocialTradingManager.validateNewEntryFee: Passed entry fee must not exceed maxEntryFee."
        );
    }


    function VALIDATEMANAGERADDRESS45(
        bytes memory _rebalancingSetCallData
    )
        internal
        view
    {
        address manager;

        assembly {
            manager := mload(add(_rebalancingSetCallData, 32))
        }

        require(
            manager == address(this),
            "SocialTradingManager.validateCallDataArgs: Passed manager address is not this address."
        );
    }

    function ALLOCATOR261(IRebalancingSetTokenV2 _tradingPool) internal view returns (ISocialAllocator) {
        return pools[address(_tradingPool)].allocator;
    }

    function TRADER685(IRebalancingSetTokenV2 _tradingPool) internal view returns (address) {
        return pools[address(_tradingPool)].trader;
    }

    function CURRENTALLOCATION387(IRebalancingSetTokenV2 _tradingPool) internal view returns (uint256) {
        return pools[address(_tradingPool)].currentAllocation;
    }

    function FEEUPDATETIMESTAMP466(IRebalancingSetTokenV2 _tradingPool) internal view returns (uint256) {
        return pools[address(_tradingPool)].feeUpdateTimestamp;
    }

    function NEWENTRYFEE285(IRebalancingSetTokenV2 _tradingPool) internal view returns (uint256) {
        return pools[address(_tradingPool)].newEntryFee;
    }
}





pragma solidity 0.5.7;
pragma experimental "ABIEncoderV2";








contract SocialTradingManagerV2 is
    SocialTradingManager,
    LimitOneUpgrade
{

    constructor(
        ICore _core,
        address _factory,
        address[] memory _whiteListedAllocators,
        uint256 _maxEntryFee,
        uint256 _feeUpdateTimelock
    )
        public
        SocialTradingManager(
            _core,
            _factory,
            _whiteListedAllocators,
            _maxEntryFee,
            _feeUpdateTimelock
        )
    {}




    function ADJUSTFEE487(
        address _tradingPool,
        bytes calldata _newFeeCallData
    )
        external
        ONLYTRADER541(IRebalancingSetTokenV2(_tradingPool))
        LIMITONEUPGRADE170(_tradingPool)
        TIMELOCKUPGRADE701
    {
        IRebalancingSetTokenV3(_tradingPool).ADJUSTFEE487(_newFeeCallData);
    }


    function REMOVEREGISTEREDUPGRADE402(
        address _tradingPool,
        bytes32 _upgradeHash
    )
        external
        ONLYTRADER541(IRebalancingSetTokenV2(_tradingPool))
    {
        LimitOneUpgrade.REMOVEREGISTEREDUPGRADEINTERNAL162(_tradingPool, _upgradeHash);
    }
}
