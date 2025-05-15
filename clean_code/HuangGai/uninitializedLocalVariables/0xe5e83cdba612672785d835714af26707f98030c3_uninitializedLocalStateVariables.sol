







pragma solidity 0.6.12;














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




pragma solidity 0.6.12;


interface ERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract BalanceReader {
    using SafeMath for uint256;

    address private constant ETH_ASSET_HASH = address(0);

    function getBalances(
        address _user,
        address[] memory _assetIds
    )
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory balances = new uint256[](_assetIds.length);

        for (uint256 i ; i < _assetIds.length; i++) {

            if (_assetIds[i] == ETH_ASSET_HASH) {
                balances[i] = _user.balance;
                continue;
            }
            if (!_isContract(_assetIds[i])) {
                continue;
            }

            ERC20 token ;

            balances[i] = token.balanceOf(_user);
        }

        return balances;
    }

    function _isContract(address account) private view returns (bool) {



        bytes32 codehash;
        bytes32 accountHash ;


        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
}
