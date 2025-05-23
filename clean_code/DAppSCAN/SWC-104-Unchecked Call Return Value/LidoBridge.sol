

pragma solidity >=0.6.10 <=0.8.10;
pragma experimental ABIEncoderV2;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IDefiBridge} from "../../interfaces/IDefiBridge.sol";
import {AztecTypes} from "../../aztec/AztecTypes.sol";

interface ICurvePool {
    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external payable returns (uint256);
}

interface ILido {
    function submit(address _referral) external payable returns (uint256);
}

interface ILidoOracle {
    function getLastCompletedReportDelta() external view returns (uint256 postTotalPooledEther, uint256 preTotalPooledEther, uint256 timeElapsed);
}

interface IWstETH {
    function wrap(uint256 _stETHAmount) external returns (uint256);
    function unwrap(uint256 _wstETHAmount) external returns (uint256);
    function getStETHByWstETH(uint256 _wstETHAmount) external view returns (uint256);
    function getWstETHByStETH(uint256 _stETHAmount) external view returns (uint256);
}

interface IRollupProcessor {
    function receiveEthFromBridge(uint256 interactionNonce) external payable;
}

contract LidoBridge is IDefiBridge {
    using SafeERC20 for IERC20;

    address public immutable rollupProcessor;
    address public referral;

    ILido public lido = ILido(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);
    IWstETH public wrappedStETH = IWstETH(0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0);
    ICurvePool public curvePool = ICurvePool(0xDC24316b9AE028F1497c275EB9192a3Ea0f67022);

    int128 private curveETHIndex = 0;
    int128 private curveStETHIndex = 1;

    constructor(address _rollupProcessor, address _referral) {
        rollupProcessor = _rollupProcessor;
        referral = _referral;
    }

    receive() external payable {}

    function convert(
        AztecTypes.AztecAsset calldata inputAssetA,
        AztecTypes.AztecAsset calldata,
        AztecTypes.AztecAsset calldata outputAssetA,
        AztecTypes.AztecAsset calldata,
        uint256 inputValue,
        uint256 interactionNonce,
        uint64,
        address
    )
        external
        payable
        returns (
            uint256 outputValueA,
            uint256,
            bool isAsync
        )
    {
        require(msg.sender == rollupProcessor, "LidoBridge: Invalid Caller");

        bool isETHInput = inputAssetA.assetType == AztecTypes.AztecAssetType.ETH;
        bool isWstETHInput = inputAssetA.assetType == AztecTypes.AztecAssetType.ERC20 && inputAssetA.erc20Address == address(wrappedStETH);

        require(isETHInput || isWstETHInput, "LidoBridge: Invalid Input");

        isAsync = false;
        outputValueA = isETHInput ? wrapETH(inputValue, outputAssetA) : unwrapETH(inputValue, outputAssetA, interactionNonce);
    }




    function wrapETH(uint256 inputValue, AztecTypes.AztecAsset calldata outputAsset) private returns (uint256 outputValue) {
        require(
            outputAsset.assetType == AztecTypes.AztecAssetType.ERC20 && outputAsset.erc20Address == address(wrappedStETH),
            "LidoBridge: Invalid Output Token"
        );


        uint256 minOutput = inputValue;





        uint256 curveStETHBalance = curvePool.get_dy(curveETHIndex, curveStETHIndex, inputValue);

        if (curveStETHBalance > minOutput) {


            curvePool.exchange{value: inputValue}(curveETHIndex, curveStETHIndex, inputValue, minOutput);
        } else {


            lido.submit{value: inputValue}(referral);
        }



        uint256 outputStETHBalance = IERC20(address(lido)).balanceOf(address(this));

        IERC20(address(lido)).safeIncreaseAllowance(address(wrappedStETH), outputStETHBalance);
        outputValue = wrappedStETH.wrap(outputStETHBalance);


        IERC20(address(wrappedStETH)).safeIncreaseAllowance(rollupProcessor, outputValue);
    }




    function unwrapETH(uint256 inputValue, AztecTypes.AztecAsset calldata outputAsset, uint256 interactionNonce) private returns (uint256 outputValue) {
        require(outputAsset.assetType == AztecTypes.AztecAssetType.ETH, "LidoBridge: Invalid Output Token");


        uint256 stETH = wrappedStETH.unwrap(inputValue);


        IERC20(address(lido)).safeIncreaseAllowance(address(curvePool), stETH);
        outputValue = curvePool.exchange(curveStETHIndex, curveETHIndex, stETH, 0);


        IRollupProcessor(rollupProcessor).receiveEthFromBridge{value: outputValue}(interactionNonce);
    }

  function finalise(
    AztecTypes.AztecAsset calldata,
    AztecTypes.AztecAsset calldata,
    AztecTypes.AztecAsset calldata,
    AztecTypes.AztecAsset calldata,
    uint256,
    uint64
  ) external payable returns (uint256, uint256, bool) {
    require(false);
  }
}
