



pragma solidity ^0.5.15;


contract JugAbstract {
    function drip(bytes32) external returns (uint256);
}


contract PotAbstract {
    function drip() external returns (uint256);
    function dsr() public view returns (uint256);
    function chi() public view returns (uint256);
    function rho() public view returns (uint256);
}


contract VatAbstract {
    function dai(address) public view returns (uint256);
    function sin(address) public view returns (uint256);
}


contract VowAbstract {
    function sin(uint256) public view returns (uint256);
    function Sin() public view returns (uint256);
    function Ash() public view returns (uint256);
    function bump() public view returns (uint256);
    function hump() public view returns (uint256);
    function flap() external returns (uint256);
    function heal(uint256) external;
}


contract GemPitAbstract {
    function burn(address) public;
}


contract DSTokenAbstract {
    function balanceOf(address) external view returns (uint256);
}


contract PotHelper {

    PotAbstract pa;

    constructor(address pot) public {
        pa = PotAbstract(pot);
    }


    uint256 constant ONE = 10 ** 27;

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = mul(x, y) / ONE;
    }

    function rpow(uint x, uint n, uint base) internal pure returns (uint z) {
        assembly {
            switch x case 0 {switch n case 0 {z := base} default {z := 0}}
            default {
                switch mod(n, 2) case 0 { z := base } default { z := x }
                let half := div(base, 2)
                for { n := div(n, 2) } n { n := div(n,2) } {
                    let xx := mul(x, x)
                    if iszero(eq(div(xx, x), x)) { revert(0,0) }
                    let xxRound := add(xx, half)
                    if lt(xxRound, xx) { revert(0,0) }
                    x := div(xxRound, base)
                    if mod(n,2) {
                        let zx := mul(z, x)
                        if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
                        let zxRound := add(zx, half)
                        if lt(zxRound, zx) { revert(0,0) }
                        z := div(zxRound, base)
                    }
                }
            }
        }
    }


    function drop() public view returns (uint256) {
        if (now == pa.rho()) return pa.chi();
        return rmul(rpow(pa.dsr(), now - pa.rho(), ONE), pa.chi());
    }


    function pot() public view returns (PotAbstract) {
        return pa;
    }
}





contract Hadaiken {

    address constant internal PIT = address(0x69076e44a9C70a67D5b79d95795Aba299083c275);
    address constant internal MKR = address(0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2);
    address constant internal JUG = address(0x19c0976f590D67707E62397C87829d896Dc0f1F1);
    address constant internal POT = address(0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7);
    address constant internal VAT = address(0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B);
    address constant internal VOW = address(0xA950524441892A31ebddF91d3cEEFa04Bf454466);

    GemPitAbstract  constant internal pit  = GemPitAbstract(PIT);
    DSTokenAbstract constant internal gem  = DSTokenAbstract(MKR);
    JugAbstract     constant internal jug  = JugAbstract(JUG);
    PotAbstract     constant internal pot  = PotAbstract(POT);
    VowAbstract     constant internal vow  = VowAbstract(VOW);
    VatAbstract     constant internal vat  = VatAbstract(VAT);
    PotHelper                internal poth;

    bytes32 constant internal ETH_A = bytes32("ETH-A");
    bytes32 constant internal BAT_A = bytes32("BAT-A");
    bytes32 constant internal USDC_A = bytes32("USDC-A");

    constructor() public {
        poth = new PotHelper(POT);
    }


    function _rawSysDebt() internal view returns (uint256) {
        return (vat.sin(VOW) - vow.Sin() - vow.Ash());
    }

    function rawSysDebt() public view returns (uint256) {
        return _rawSysDebt();
    }

    function _sysSurplusThreshold() internal view returns (uint256) {
        return (vat.sin(VOW) + vow.bump() + vow.hump());
    }

    function  sysSurplusThreshold() public view returns (uint256) {
        return _sysSurplusThreshold();
    }


    function heal() public {
        _heal();
    }


    function healStat() public returns (uint256 sd) {
        sd = _rawSysDebt();
        _heal();
    }


    function _heal() internal {
        vow.heal(_rawSysDebt());
    }


    function drip() public returns (uint256 chi) {
        chi = pot.drip();
        _dripIlks();
    }


    function drop() public view returns (uint256) {
        return poth.drop();
    }

    function _dripPot() internal {
        pot.drip();
    }

    function dripIlks() public {
        _dripIlks();
    }

    function _dripIlks() internal {
        jug.drip(ETH_A);
        jug.drip(BAT_A);
        jug.drip(USDC_A);
    }

    function kickable() public view returns (bool) {
        return _kickable();
    }


    function _kickable() internal view returns (bool) {



        return (vat.dai(VOW) >= _sysSurplusThreshold());
    }


    function finishhim() public returns (uint256 burned) {
        burned = gem.balanceOf(PIT);
        _finishhim();
    }

    function _finishhim() internal {
        pit.burn(MKR);
    }


    function ccccombobreaker() public returns (uint256) {
        _heal();
        return vow.flap();
    }


    function _ccccombobreaker() internal {
        vow.flap();
    }


    function hadaiken() public {
        _dripPot();
        _dripIlks();
        _heal();
        if (_kickable()) { _ccccombobreaker(); }
    }
}
