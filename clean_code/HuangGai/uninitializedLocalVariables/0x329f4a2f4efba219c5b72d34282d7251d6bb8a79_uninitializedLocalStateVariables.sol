



pragma solidity 0.5.13;

interface tokenInterface {

    function balanceOf(address _address) external view returns (uint balance);

}

contract balanceViewer {

    address sai ;

    address mkr ;


    function readAllBalances(address _address) public view returns(uint256 mkrBalance, uint256 saiBalance) {
        saiBalance = tokenInterface(sai).balanceOf(_address);
        mkrBalance = tokenInterface(mkr).balanceOf(_address);
    }

}
