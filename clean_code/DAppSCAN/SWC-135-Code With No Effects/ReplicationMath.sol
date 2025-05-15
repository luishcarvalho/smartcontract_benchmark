
pragma solidity 0.8.6;

import "./ABDKMath64x64.sol";
import "./CumulativeNormalDistribution.sol";
import "./Units.sol";





library ReplicationMath {
    using ABDKMath64x64 for int128;
    using ABDKMath64x64 for uint256;
    using CumulativeNormalDistribution for int128;
    using Units for int128;
    using Units for uint256;

    int128 internal constant ONE_INT = 0x10000000000000000;





    function getProportionalVolatility(uint256 sigma, uint256 tau) internal pure returns (int128 vol) {
        int128 sqrtTauX64 = tau.toYears().sqrt();
        int128 sigmaX64 = sigma.percentage();
        vol = sigmaX64.mul(sqrtTauX64);
    }











    function getStableGivenRisky(
        int128 invariantLastX64,
        uint256 scaleFactorRisky,
        uint256 scaleFactorStable,
        uint256 riskyPerLiquidity,
        uint256 strike,
        uint256 sigma,
        uint256 tau
    ) internal pure returns (uint256 stablePerLiquidity) {
        int128 strikeX64 = strike.scaleToX64(scaleFactorStable);
        int128 volX64 = getProportionalVolatility(sigma, tau);
        int128 riskyX64 = riskyPerLiquidity.scaleToX64(scaleFactorRisky);
        int128 phi = ONE_INT.sub(riskyX64).getInverseCDF();
        int128 input = phi.sub(volX64);
        int128 stableX64 = strikeX64.mul(input.getCDF()).add(invariantLastX64);
        stablePerLiquidity = stableX64.scalefromX64(scaleFactorStable);
    }












    function getRiskyGivenStable(
        int128 invariantLastX64,
        uint256 scaleFactorRisky,
        uint256 scaleFactorStable,
        uint256 stablePerLiquidity,
        uint256 strike,
        uint256 sigma,
        uint256 tau
    ) internal pure returns (uint256 riskyPerLiquidity) {
        int128 strikeX64 = strike.scaleToX64(scaleFactorStable);
        int128 volX64 = getProportionalVolatility(sigma, tau);
        int128 stableX64 = stablePerLiquidity.scaleToX64(scaleFactorStable);
        int128 phi = stableX64.sub(invariantLastX64).div(strikeX64).getInverseCDF();
        int128 input = phi.add(volX64);
        int128 riskyX64 = ONE_INT.sub(input.getCDF());
        riskyPerLiquidity = riskyX64.scalefromX64(scaleFactorRisky);
    }








    function calcInvariant(
        uint256 scaleFactorRisky,
        uint256 scaleFactorStable,
        uint256 riskyPerLiquidity,
        uint256 stablePerLiquidity,
        uint256 strike,
        uint256 sigma,
        uint256 tau
    ) internal pure returns (int128 invariantX64) {
        uint256 output = getStableGivenRisky(
            0,
            scaleFactorRisky,
            scaleFactorStable,
            riskyPerLiquidity,
            strike,
            sigma,
            tau
        );
        int128 outputX64 = output.scaleToX64(scaleFactorStable);
        int128 stableX64 = stablePerLiquidity.scaleToX64(scaleFactorStable);
        invariantX64 = stableX64.sub(outputX64);
    }
}
