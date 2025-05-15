


pragma solidity ^0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {Auth, Authority} from "solmate/auth/Auth.sol";

import {Multicall} from "ERC4626/external/Multicall.sol";
import {xERC4626, ERC4626} from "ERC4626/xERC4626.sol";
import {ERC20MultiVotes} from "flywheel/token/ERC20MultiVotes.sol";
import {ERC20Gauges} from "flywheel/token/ERC20Gauges.sol";

interface ITribe {
    function getPriorVotes(address account, uint256 blockNumber)
        external
        view
        returns (uint96);

    function getCurrentVotes(address account) external view returns (uint96);
}










contract xTRIBE is ERC20MultiVotes, ERC20Gauges, xERC4626, Multicall {
    constructor(
        ERC20 _tribe,
        address _owner,
        Authority _authority,
        uint32 _rewardsCycleLength,
        uint32 _incrementFreezeWindow
    )
        Auth(_owner, _authority)
        xERC4626(_rewardsCycleLength)
        ERC20Gauges(_rewardsCycleLength, _incrementFreezeWindow)
        ERC4626(_tribe, "xTribe: Gov + Yield", "xTRIBE")
    {}

    function tribe() public view returns (ITribe) {
        return ITribe(address(asset));
    }










    function getVotes(address account) public view override returns (uint256) {
        return
            super.getVotes(account) +
            convertToShares(tribe().getCurrentVotes(account));
    }









    function getPastVotes(address account, uint256 blockNumber)
        public
        view
        override
        returns (uint256)
    {
        return
            super.getPastVotes(account, blockNumber) +
            convertToShares(tribe().getPriorVotes(account, blockNumber));
    }







    function emitVotingBalances(address[] calldata accounts) external {
        uint256 size = accounts.length;

        for (uint256 i = 0; i < size; ) {
            emit DelegateVotesChanged(accounts[i], 0, getVotes(accounts[i]));

            unchecked {
                i++;
            }
        }
    }









































