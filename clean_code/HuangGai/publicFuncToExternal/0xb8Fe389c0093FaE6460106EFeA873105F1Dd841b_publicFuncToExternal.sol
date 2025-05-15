





pragma solidity ^0.5.7;






contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);





    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }




    function owner() public view returns (address) {
        return _owner;
    }




    modifier onlyOwner() {
        require(isOwner());
        _;
    }




    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }








    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }





    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }





    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


pragma solidity >=0.4.24;

library StringUtils {






    function strlen(string memory s) internal pure returns (uint) {
        uint len;
        uint i = 0;
        uint bytelength = bytes(s).length;
        for(len = 0; i < bytelength; len++) {
            byte b = bytes(s)[i];
            if(b < 0x80) {
                i += 1;
            } else if (b < 0xE0) {
                i += 2;
            } else if (b < 0xF0) {
                i += 3;
            } else if (b < 0xF8) {
                i += 4;
            } else if (b < 0xFC) {
                i += 5;
            } else {
                i += 6;
            }
        }
        return len;
    }
}


pragma solidity ^0.5.7;





library SafeMath {



    function mul(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }




    function div(uint256 a, uint256 b) internal pure returns (uint256) {

        require(b > 0);
        uint256 c = a / b;


        return c;
    }




    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }




    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }





    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}


pragma solidity >=0.4.24;

interface PriceOracle {







    function price(string calldata name, uint expires, uint duration) external view returns(uint);
}



pragma solidity >=0.5.0;


interface AggregatorInterface {
  function latestAnswer() external view returns (int256);
}



contract StablePriceOracle is Ownable, PriceOracle {
    using SafeMath for *;
    using StringUtils for *;

    mapping(address=>bool) public controllers;


    uint[] public rentPrices;
    uint public successRegistNumber;


    AggregatorInterface public usdOracle;

    event OracleChanged(address oracle);
    event SccessRegistNumberChanged(uint successRegistNumber);
    event RentPriceChanged(uint[] prices);

    bytes4 constant private INTERFACE_META_ID = bytes4(keccak256("supportsInterface(bytes4)"));
    bytes4 constant private ORACLE_ID = bytes4(keccak256("price(string,uint256,uint256)") ^ keccak256("premium(string,uint256,uint256)"));
    modifier onlyController {
        require(controllers[msg.sender]);
        _;
    }


    function addController(address controller) public onlyOwner {
        controllers[controller] = true;
    }


    function removeController(address controller) public onlyOwner {
        controllers[controller] = false;
    }

    constructor(AggregatorInterface _usdOracle, uint[] memory _rentPrices) public {
        usdOracle = _usdOracle;
        setPrices(_rentPrices);
    }

    function updateSuccessRegistNumber()  public onlyController  {
        successRegistNumber ++;

        emit SccessRegistNumberChanged(successRegistNumber);

    }

    function price(string calldata name, uint expires, uint duration) external view returns(uint) {
        uint len = name.strlen();
        if(len > rentPrices.length) {
            len = rentPrices.length;
        }
        require(len > 0);

        uint basePrice = rentPrices[len - 1].mul(duration);
        basePrice = basePrice.add(_premium(name, expires, duration));

        return attoUSDToWei(basePrice);
    }









    function setPrices(uint[] memory _rentPrices) public onlyOwner {
        rentPrices = _rentPrices;
        emit RentPriceChanged(_rentPrices);
    }





    function setOracle(AggregatorInterface _usdOracle) public onlyOwner {
        usdOracle = _usdOracle;
        emit OracleChanged(address(_usdOracle));
    }




    function premium(string calldata name, uint expires, uint duration) external view returns(uint) {
        return attoUSDToWei(_premium(name, expires, duration));
    }




    function _premium(string memory name, uint expires, uint duration) internal view returns(uint) {
        return 0;
    }

    function attoUSDToWei(uint amount) internal view returns(uint) {
        uint ethPrice = uint(usdOracle.latestAnswer());
        return amount.mul(1e8).div(ethPrice);
    }

    function weiToAttoUSD(uint amount) internal view returns(uint) {
        uint ethPrice = uint(usdOracle.latestAnswer());
        return amount.mul(ethPrice).div(1e8);
    }

    function supportsInterface(bytes4 interfaceID) public view returns (bool) {
        return interfaceID == INTERFACE_META_ID || interfaceID == ORACLE_ID;
    }
}
