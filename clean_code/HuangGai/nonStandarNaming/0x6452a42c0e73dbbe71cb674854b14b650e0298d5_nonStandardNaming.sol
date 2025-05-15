
















pragma solidity 0.6.5;
pragma experimental ABIEncoderV2;


interface ERC20 {
    function BALANCEOF194(address) external view returns (uint256);
}



interface ProtocolAdapter {


    function ADAPTERTYPE498() external pure returns (string memory);


    function TOKENTYPE764() external pure returns (string memory);


    function GETBALANCE157(address token, address account) external view returns (uint256);
}



interface CurveRewards {
    function EARNED229(address) external view returns (uint256);
}



interface iETHRewards {
    function EARNED229(address) external view returns (uint256);
}



interface Unipool {
    function EARNED229(address) external view returns (uint256);
}



interface Synthetix {
    function COLLATERAL748(address) external view returns (uint256);
}



contract SynthetixAssetAdapter is ProtocolAdapter {

    string public constant override adaptertype685 = "Asset";

    string public constant override tokentype264 = "ERC20";

    address internal constant snx54 = 0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F;
    address internal constant susd_pool_token932 = 0xC25a3A3b969415c80451098fa907EC722572917F;
    address internal constant ieth559 = 0xA9859874e1743A32409f75bB11549892138BBA1E;
    address internal constant uniswap_seth654 = 0xe9Cf7887b93150D4F2Da7dFc6D502B216438F244;
    address internal constant lp_reward_curve216 = 0xDCB6A51eA3CA5d3Fd898Fd6564757c7aAeC3ca92;
    address internal constant lp_reward_ieth63 = 0xC746bc860781DC90BBFCD381d6A058Dc16357F8d;
    address internal constant lp_reward_uniswap423 = 0x48D7f315feDcaD332F68aafa017c7C158BC54760;


    function GETBALANCE157(address token, address account) external view override returns (uint256) {
        if (token == snx54) {
            uint256 balance = Synthetix(snx54).COLLATERAL748(account);
            balance = balance + CurveRewards(lp_reward_curve216).EARNED229(account);
            balance = balance + iETHRewards(lp_reward_ieth63).EARNED229(account);
            balance = balance + Unipool(lp_reward_uniswap423).EARNED229(account);
            return balance;
        } else if (token == susd_pool_token932) {
            return ERC20(lp_reward_curve216).BALANCEOF194(account);
        } else if (token == ieth559) {
            return ERC20(lp_reward_ieth63).BALANCEOF194(account);
        } else if (token == uniswap_seth654) {
            return ERC20(lp_reward_uniswap423).BALANCEOF194(account);
        } else {
            return 0;
        }
    }
}
