
pragma solidity 0.6.12;

interface IGeneric {


    function withdraw(uint256 amount) external returns (uint256);

    function emergencyWithdraw(uint256 amount) external;

    function deposit() external;

    function withdrawAll() external returns (bool);



    function nav() external view returns (uint256);

    function apr() external view returns (uint256);

    function weightedApr() external view returns (uint256);


    function enabled() external view returns (bool);

    function hasAssets() external view returns (bool);

    function aprAfterDeposit(uint256 amount) external view returns (uint256);
}
