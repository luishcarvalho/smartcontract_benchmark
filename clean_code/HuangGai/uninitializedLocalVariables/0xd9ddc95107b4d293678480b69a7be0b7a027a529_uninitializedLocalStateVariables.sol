







pragma solidity 0.6.8;














library SafeMath {










    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c ;

        require(c >= a, "SafeMath: addition overflow");

        return c;
    }











    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }











    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c ;


        return c;
    }











    function mul(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c ;

        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }













    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }













    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c ;



        return c;
    }













    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }













    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}











library WadRayMath {
    using SafeMath for uint256;

    uint256 internal constant WAD = 1e18;
    uint256 internal constant halfWAD = WAD / 2;

    uint256 internal constant RAY = 1e27;
    uint256 internal constant halfRAY = RAY / 2;

    uint256 internal constant WAD_RAY_RATIO = 1e9;

    function ray() internal pure returns (uint256) {
        return RAY;
    }
    function wad() internal pure returns (uint256) {
        return WAD;
    }

    function halfRay() internal pure returns (uint256) {
        return halfRAY;
    }

    function halfWad() internal pure returns (uint256) {
        return halfWAD;
    }

    function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return halfWAD.add(a.mul(b)).div(WAD);
    }

    function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 halfB ;


        return halfB.add(a.mul(WAD)).div(b);
    }

    function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return halfRAY.add(a.mul(b)).div(RAY);
    }

    function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 halfB ;


        return halfB.add(a.mul(RAY)).div(b);
    }

    function rayToWad(uint256 a) internal pure returns (uint256) {
        uint256 halfRatio ;


        return halfRatio.add(a).div(WAD_RAY_RATIO);
    }

    function wadToRay(uint256 a) internal pure returns (uint256) {
        return a.mul(WAD_RAY_RATIO);
    }






    function rayPow(uint256 x, uint256 n) internal pure returns (uint256 z) {

        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rayMul(x, x);

            if (n % 2 != 0) {
                z = rayMul(z, x);
            }
        }
    }

}














abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}









library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }




    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }




    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }





    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}









contract WhitelistAdminRole is Context {
    using Roles for Roles.Role;

    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    Roles.Role private _whitelistAdmins;

    constructor () internal {
        _addWhitelistAdmin(_msgSender());
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelistAdmin(_msgSender()), "WhitelistAdminRole: caller does not have the WhitelistAdmin role");
        _;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account);
    }

    function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
        _addWhitelistAdmin(account);
    }

    function renounceWhitelistAdmin() public {
        _removeWhitelistAdmin(_msgSender());
    }

    function _addWhitelistAdmin(address account) internal {
        _whitelistAdmins.add(account);
        emit WhitelistAdminAdded(account);
    }

    function _removeWhitelistAdmin(address account) internal {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }
}











contract WhitelistedRole is Context, WhitelistAdminRole {
    using Roles for Roles.Role;

    event WhitelistedAdded(address indexed account);
    event WhitelistedRemoved(address indexed account);

    Roles.Role private _whitelisteds;

    modifier onlyWhitelisted() {
        require(isWhitelisted(_msgSender()), "WhitelistedRole: caller does not have the Whitelisted role");
        _;
    }

    function isWhitelisted(address account) public view returns (bool) {
        return _whitelisteds.has(account);
    }

    function addWhitelisted(address account) public onlyWhitelistAdmin {
        _addWhitelisted(account);
    }

    function removeWhitelisted(address account) public onlyWhitelistAdmin {
        _removeWhitelisted(account);
    }

    function renounceWhitelisted() public {
        _removeWhitelisted(_msgSender());
    }

    function _addWhitelisted(address account) internal {
        _whitelisteds.add(account);
        emit WhitelistedAdded(account);
    }

    function _removeWhitelisted(address account) internal {
        _whitelisteds.remove(account);
        emit WhitelistedRemoved(account);
    }
}








interface ILinearDividendOracle {








    function calculateAccruedDividends(
        uint256 tokenAmount,
        uint256 timestamp,
        uint256 fromIndex
    ) external view returns (uint256, uint256);









    function calculateAccruedDividendsBounded(
        uint256 tokenAmount,
        uint256 timestamp,
        uint256 fromIndex,
        uint256 toIndex
    ) external view returns (uint256, uint256, uint256);





    function getCurrentIndex() external view returns (uint256);





    function getCurrentValue() external view returns (uint256);





    function getHistoricalValue(uint256 dividendIndex) external view returns (uint256);
}








contract ManagedLinearDividendOracle is ILinearDividendOracle, WhitelistedRole {
    using SafeMath for uint256;
    using WadRayMath for uint256;

    event DividendUpdated(uint256 value, uint256 timestamp);

    uint256 internal constant SECONDS_PER_YEAR = 365 days;

    struct CalcReturnInfo {
        uint256 dividendInWad;
        uint256 index;
        uint256 timestamp;
    }




    struct DividendPhase {

        uint256 USDPerSecondInRay;


        uint256 start;


        uint256 end;
    }

    DividendPhase[] internal _dividendPhases;


    constructor(uint256 USDPerAnnumInWad) public {
        _addWhitelisted(msg.sender);

        newDividendPhase(USDPerAnnumInWad);
    }









    function calculateAccruedDividends(
        uint256 tokenAmount,
        uint256 timestamp,
        uint256 fromIndex
    ) external view virtual override returns (uint256, uint256) {
        (uint256 totalDividendInWad, uint256 resultIndex,) = calculateAccruedDividendsBounded(
            tokenAmount,
            timestamp,
            fromIndex,
            _dividendPhases.length.sub(1)
        );

        return (totalDividendInWad, resultIndex);
    }









    function calculateAccruedDividendsBounded(
        uint256 tokenAmount,
        uint256 timestamp,
        uint256 fromIndex,
        uint256 toIndex
    ) public view virtual override returns (uint256, uint256, uint256){
        require(toIndex < _dividendPhases.length, "toIndex out of bounds");
        require(fromIndex <= toIndex, "fromIndex must be smaller than or equal to toIndex");


        uint256 dividendPerToken ;


        uint256 lastIndex ;



        DividendPhase storage firstPhase = _dividendPhases[fromIndex];
        require(timestamp >= firstPhase.start, "Timestamp must be within the specified starting phase");


        if (fromIndex == toIndex && toIndex == lastIndex) {

            dividendPerToken = calculatePhaseDividend(timestamp, block.timestamp, firstPhase.USDPerSecondInRay);
        } else {

            dividendPerToken = calculatePhaseDividend(timestamp, firstPhase.end, firstPhase.USDPerSecondInRay);

            for (uint256 i ; i <= toIndex && i < lastIndex; i = i.add(1)) {

                DividendPhase storage phase = _dividendPhases[i];

                uint256 phaseDividend ;


                dividendPerToken = dividendPerToken.add(phaseDividend);
            }

            if (toIndex == lastIndex) {
                DividendPhase storage lastPhase = _dividendPhases[lastIndex];

                uint256 phaseDividend ;


                dividendPerToken = dividendPerToken.add(phaseDividend);
            }
        }


        CalcReturnInfo memory result = CalcReturnInfo(0, 0, 0);

        if (toIndex == lastIndex) {
            result.index = lastIndex;
            result.timestamp = block.timestamp;
        } else {
            result.index = toIndex.add(1);
            result.timestamp = _dividendPhases[result.index].start;
        }

        result.dividendInWad = tokenAmount
            .wadToRay()
            .rayMul(dividendPerToken)
            .rayToWad();

        return (result.dividendInWad, result.index, result.timestamp);
    }





    function getCurrentIndex() external view virtual override returns (uint256) {
        return _dividendPhases.length.sub(1);
    }







    function getCurrentValue() external view virtual override returns (uint256) {
        return getHistoricalValue(_dividendPhases.length.sub(1));
    }







    function getHistoricalValue(uint256 dividendIndex) public view virtual override returns (uint256) {
        (uint256 USDPerSecondInRay,,) = getPreciseDividendData(dividendIndex);

        return USDPerSecondInRay.rayToWad();
    }





    function getPreciseDividendData(uint256 dividendIndex) public view virtual returns (uint256, uint256, uint256) {
        require(dividendIndex < _dividendPhases.length, "Dividend index out of bounds");


        DividendPhase storage dividendPhase = _dividendPhases[dividendIndex];

        return (dividendPhase.USDPerSecondInRay, dividendPhase.start, dividendPhase.end);
    }






    function newDividendPhase(uint256 USDPerAnnumInWad) public onlyWhitelisted returns (bool) {
        uint256 rateInRay ;


        if (_dividendPhases.length > 0) {
            DividendPhase storage previousDividendPhase = _dividendPhases[_dividendPhases.length.sub(1)];


            previousDividendPhase.end = block.timestamp;
        }

        DividendPhase memory newPhase = DividendPhase({ USDPerSecondInRay: rateInRay, start: block.timestamp, end: 0});
        _dividendPhases.push(newPhase);
        return true;
    }







    function USDPerAnnumInWadToPerSecondInRay(uint256 USDPerAnnumInWad) public pure returns (uint256) {
        return USDPerAnnumInWad
            .wadToRay()
            .div(SECONDS_PER_YEAR);
    }








    function calculatePhaseDividend(uint256 start, uint256 end, uint256 USDPerSecondInRay) public pure returns (uint256) {
        return end
            .sub(start, "Phase start end mismatch")
            .mul(USDPerSecondInRay);
    }
}
