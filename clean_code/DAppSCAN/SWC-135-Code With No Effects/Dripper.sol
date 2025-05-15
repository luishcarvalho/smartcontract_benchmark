
pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Governable } from "../governance/Governable.sol";
import { IVault } from "../interfaces/IVault.sol";







































contract Dripper is Governable {
    using SafeERC20 for IERC20;

    struct Drip {
        uint64 lastCollect;
        uint192 perBlock;
    }

    address immutable vault;
    address immutable token;
    uint256 public dripDuration;
    Drip public drip;

    constructor(address _vault, address _token) {
        vault = _vault;
        token = _token;
    }




    function availableFunds() external view returns (uint256) {
        uint256 balance = IERC20(token).balanceOf(address(this));
        return _availableFunds(balance, drip);
    }



    function collect() external {
        _collect();
    }



    function collectAndRebase() external {
        _collect();
        IVault(vault).rebase();
    }




    function setDripDuration(uint256 _durationSeconds) external onlyGovernor {
        require(_durationSeconds > 0, "duration must be non-zero");

        dripDuration = uint192(_durationSeconds);
        Dripper(this).collect();
    }




    function transferToken(address _asset, uint256 _amount)
        external
        onlyGovernor
    {
        IERC20(_asset).safeTransfer(governor(), _amount);
    }






    function _availableFunds(uint256 _balance, Drip memory _drip)
        internal
        view
        returns (uint256)
    {
        uint256 elapsed = block.timestamp - _drip.lastCollect;
        uint256 allowed = (elapsed * _drip.perBlock);
        return (allowed > _balance) ? _balance : allowed;
    }



    function _collect() internal {

        uint256 balance = IERC20(token).balanceOf(address(this));
        uint256 amountToSend = _availableFunds(balance, drip);
        uint256 remaining = balance - amountToSend;


        drip = Drip({
            perBlock: uint192(remaining / dripDuration),
            lastCollect: uint64(block.timestamp)
        });

        IERC20(token).safeTransfer(vault, amountToSend);
    }
}
