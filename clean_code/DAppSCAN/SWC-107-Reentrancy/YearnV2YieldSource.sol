
pragma solidity 0.6.12;

import "../interfaces/IYieldSource.sol";
import "../external/yearn/IYVaultV2.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";






contract YearnV2YieldSource is IYieldSource, ERC20Upgradeable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint;


    IYVaultV2 public vault;

    IERC20Upgradeable internal token;

    uint256 public maxLosses = 0;


    event Sponsored(
        address indexed user,
        uint256 amount
    );


    event YieldSourceYearnV2Initialized(
        IYVaultV2 vault,
        IERC20Upgradeable token
    );


    event MaxLossesChanged(
        uint256 newMaxLosses
    );


    event SuppliedTokenTo(
        address indexed from,
        uint256 shares,
        uint256 amount,
        address indexed to
    );


    event RedeemedToken(
        address indexed from,
        uint256 shares,
        uint256 amount
    );




    function initialize(
        IYVaultV2 _vault,
        IERC20Upgradeable _token
    )
        public
        initializer
    {
        require(address(vault) == address(0), "!already initialized");
        require(_vault.token() == address(_token), "!incorrect vault");
        require(_vault.activation() != uint256(0), "!vault not initialized");

        require(!areEqualStrings(_vault.apiVersion(), "0.3.2"), "!vault not compatible");
        require(!areEqualStrings(_vault.apiVersion(), "0.3.3"), "!vault not compatible");
        require(!areEqualStrings(_vault.apiVersion(), "0.3.4"), "!vault not compatible");

        vault = _vault;
        token = _token;

        __Ownable_init();

        _token.safeApprove(address(vault), type(uint256).max);

        emit YieldSourceYearnV2Initialized(
            _vault,
            _token
        );
    }

    function setMaxLosses(uint256 _maxLosses) external onlyOwner {
        require(_maxLosses <= 10_000, "!losses set too high");

        maxLosses = _maxLosses;

        emit MaxLossesChanged(_maxLosses);
    }



    function depositToken() external view override returns (address) {
        return address(token);
    }




    function balanceOfToken(address addr) external override returns (uint256) {
        return _sharesToToken(balanceOf(addr));
    }







    function supplyTokenTo(uint256 _amount, address to) override external {
        uint256 shares = _tokenToShares(_amount);

        _mint(to, shares);


        token.safeTransferFrom(msg.sender, address(this), _amount);

        _depositInVault();

        emit SuppliedTokenTo(msg.sender, shares, _amount, to);
    }






    function redeemToken(uint256 amount) external override returns (uint256) {
        uint256 shares = _tokenToShares(amount);

        uint256 withdrawnAmount = _withdrawFromVault(amount);

        _burn(msg.sender, shares);

        token.safeTransfer(msg.sender, withdrawnAmount);

        emit RedeemedToken(msg.sender, shares, amount);
        return withdrawnAmount;
    }




    function sponsor(uint256 amount) external {
        token.safeTransferFrom(msg.sender, address(this), amount);

        _depositInVault();

        emit Sponsored(msg.sender, amount);
    }







    function _depositInVault() internal returns (uint256) {
        IYVaultV2 v = vault;
        if(token.allowance(address(this), address(v)) < token.balanceOf(address(this))) {
            token.safeApprove(address(v), 0);
            token.safeApprove(address(v), type(uint256).max);
        }

        return v.deposit();
    }






    function _withdrawFromVault(uint amount) internal returns (uint256) {
        uint256 yShares = _tokenToYShares(amount);
        uint256 previousBalance = token.balanceOf(address(this));

        if(maxLosses != 0) {
            vault.withdraw(yShares, address(this), maxLosses);
        } else {
            vault.withdraw(yShares);
        }
        uint256 currentBalance = token.balanceOf(address(this));

        return previousBalance.sub(currentBalance);
    }



    function _balanceOfYShares() internal view returns (uint256) {
        return vault.balanceOf(address(this));
    }





    function _pricePerYShare() internal view returns (uint256) {
        return vault.pricePerShare();
    }



    function _balanceOfToken() internal view returns (uint256) {
        return token.balanceOf(address(this));
    }




    function _totalAssetsInToken() internal view returns (uint256) {
        return _balanceOfToken().add(_ySharesToToken(_balanceOfYShares()));
    }




    function _vaultDecimals() internal view returns (uint256) {
        return vault.decimals();
    }






    function _tokenToYShares(uint256 tokens) internal view returns (uint256) {
        return tokens.mul(10 ** _vaultDecimals()).div(_pricePerYShare());
    }




    function _ySharesToToken(uint256 yShares) internal view returns (uint256) {
        return yShares.mul(_pricePerYShare()).div(10 ** _vaultDecimals());
    }




    function _tokenToShares(uint256 tokens) internal view returns (uint256 shares) {
        if(totalSupply() == 0) {
            shares = tokens;
        } else {
            uint256 _totalTokens = _totalAssetsInToken();
            shares = tokens.mul(totalSupply()).div(_totalTokens);
        }
    }





    function _sharesToToken(uint256 shares) internal view returns (uint256 tokens) {
        if(totalSupply() == 0) {
            tokens = shares;
        } else {
            uint256 _totalTokens = _totalAssetsInToken();
            tokens = shares.mul(_totalTokens).div(totalSupply());
        }
    }





    function areEqualStrings(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }
}
