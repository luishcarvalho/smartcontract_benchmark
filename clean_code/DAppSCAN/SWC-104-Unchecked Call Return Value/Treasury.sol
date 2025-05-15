






pragma solidity ^0.8.3;

import "../interfaces/IERC20.sol";




contract Treasury {

    address _governance;


    address internal constant _ETH_CONSTANT =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);


    modifier onlyGovernance() {
        require(msg.sender == _governance, "!governance");
        _;
    }



    constructor(address __governance) {
        _governance = __governance;
    }






    function sendFunds(
        address _token,
        uint256 _amount,
        address _recipient
    ) external onlyGovernance {
        if (_token == _ETH_CONSTANT) {
            payable(_recipient).transfer(_amount);
        } else {

            IERC20(_token).transfer(_recipient, _amount);
        }
    }





    function approve(
        address _token,
        address _spender,
        uint256 _amount
    ) external onlyGovernance {
        IERC20(_token).approve(_spender, _amount);
    }





    function genericCall(address _target, bytes calldata _callData)
        external
        onlyGovernance
    {
        _target.call(_callData);
    }

    fallback() external payable {}
}
