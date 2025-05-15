pragma solidity >=0.5.0 <0.6.0;

import "./JoinSplitABIEncoder.sol";
import "../../../interfaces/JoinSplitInterface.sol";

























contract JoinSplit {











    function() external {
        assembly {





            validateJoinSplit()



            mstore(0x40, 0x60)





















            function validateJoinSplit() {
                mstore(0x80, calldataload(0x44))
                mstore(0xa0, calldataload(0x64))
                let notes := add(0x104, calldataload(0x184))
                let m := calldataload(0x124)
                let n := calldataload(notes)
                let gen_order := 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001
                let challenge := mod(calldataload(0x144), gen_order)


                if gt(m, n) { mstore(0x00, 404) revert(0x00, 0x20) }


                let kn := calldataload(sub(add(notes, mul(calldataload(notes), 0xc0)), 0xa0))


                mstore(0x2a0, calldataload(0x24))
                mstore(0x2c0, kn)
                mstore(0x2e0, m)
                mstore(0x300, calldataload(0x164))
                kn := mulmod(sub(gen_order, kn), challenge, gen_order)
                hashCommitments(notes, n)
                let b := add(0x320, mul(n, 0x80))


                let x := 1



                for { let i := 0 } lt(i, n) { i := add(i, 0x01) } {


                    let noteIndex := add(add(notes, 0x20), mul(i, 0xc0))



















                    let k := calldataload(noteIndex)
                    let a := calldataload(add(noteIndex, 0x20))
                    let c := challenge







                    switch eq(add(i, 0x01), n)
                    case 1 {
                        k := kn


                        switch eq(m, n)
                        case 1 {
                            k := sub(gen_order, k)
                        }
                    }


                    validateCommitment(noteIndex, k, a)

                    x := mulmod(x, mload(0x00), gen_order)


                    switch gt(add(i, 0x01), m)
                    case 1 {


                        kn := addmod(kn, sub(gen_order, k), gen_order)

                        k := mulmod(k, x, gen_order)
                        a := mulmod(a, x, gen_order)
                        c := mulmod(challenge, x, gen_order)
                    }
                    case 0 {


                        kn := addmod(kn, k, gen_order)
                    }












                    calldatacopy(0xe0, add(noteIndex, 0x80), 0x40)
                    calldatacopy(0x20, add(noteIndex, 0x40), 0x40)
                    mstore(0x120, sub(gen_order, c))
                    mstore(0x60, k)
                    mstore(0xc0, a)






                    let result := staticcall(gas, 7, 0xe0, 0x60, 0x1a0, 0x40)
                    result := and(result, staticcall(gas, 7, 0x20, 0x60, 0x120, 0x40))
                    result := and(result, staticcall(gas, 7, 0x80, 0x60, 0x160, 0x40))




                    result := and(result, staticcall(gas, 6, 0x120, 0x80, 0x160, 0x40))



                    result := and(result, staticcall(gas, 6, 0x160, 0x80, b, 0x40))





                    if eq(i, m) {
                        mstore(0x260, mload(0x20))
                        mstore(0x280, mload(0x40))
                        mstore(0x1e0, mload(0xe0))
                        mstore(
                            0x200,
                            sub(0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47, mload(0x100))
                        )
                    }




                    if gt(i, m) {
                        mstore(0x60, c)

                        result := and(
                            result,
                            and(
                                and(
                                    staticcall(gas, 6, 0x1a0, 0x80, 0x1e0, 0x40),
                                    staticcall(gas, 6, 0x220, 0x80, 0x260, 0x40)
                                ),
                                staticcall(gas, 7, 0x20, 0x60, 0x220, 0x40)
                            )
                        )







                    }


                    if iszero(result) { mstore(0x00, 400) revert(0x00, 0x20)}
                    b := add(b, 0x40)
                }





                if lt(m, n) {
                    validatePairing(0x84)
                }




                let expected := mod(keccak256(0x2a0, sub(b, 0x2a0)), gen_order)
                if iszero(eq(expected, challenge)) {


                    mstore(0x00, 404)
                    revert(0x00, 0x20)
                }



            }






            function validatePairing(t2) {
                let field_order := 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47
                let t2_x_1 := calldataload(t2)
                let t2_x_2 := calldataload(add(t2, 0x20))
                let t2_y_1 := calldataload(add(t2, 0x40))
                let t2_y_2 := calldataload(add(t2, 0x60))


                if or(or(or(or(or(or(or(
                    iszero(t2_x_1),
                    iszero(t2_x_2)),
                    iszero(t2_y_1)),
                    iszero(t2_y_2)),
                    eq(t2_x_1, 0x1800deef121f1e76426a00665e5c4479674322d4f75edadd46debd5cd992f6ed)),
                    eq(t2_x_2, 0x198e9393920d483a7260bfb731fb5d25f1aa493335a9e71297e485b7aef312c2)),
                    eq(t2_y_1, 0x12c85ea5db8c6deb4aab71808dcb408fe3d1e7690c43d37b4ce6cc0166fa7daa)),
                    eq(t2_y_2, 0x90689d0585ff075ec9e99ad690c3395bc4b313370b38ef355acdadcd122975b))
                {
                    mstore(0x00, 400)
                    revert(0x00, 0x20)
                }






                mstore(0x20, mload(0x1e0))
                mstore(0x40, mload(0x200))
                mstore(0x80, 0x1800deef121f1e76426a00665e5c4479674322d4f75edadd46debd5cd992f6ed)
                mstore(0x60, 0x198e9393920d483a7260bfb731fb5d25f1aa493335a9e71297e485b7aef312c2)
                mstore(0xc0, 0x12c85ea5db8c6deb4aab71808dcb408fe3d1e7690c43d37b4ce6cc0166fa7daa)
                mstore(0xa0, 0x90689d0585ff075ec9e99ad690c3395bc4b313370b38ef355acdadcd122975b)
                mstore(0xe0, mload(0x260))
                mstore(0x100, mload(0x280))
                mstore(0x140, t2_x_1)
                mstore(0x120, t2_x_2)
                mstore(0x180, t2_y_1)
                mstore(0x160, t2_y_2)

                let success := staticcall(gas, 8, 0x20, 0x180, 0x20, 0x20)

                if or(iszero(success), iszero(mload(0x20))) {
                    mstore(0x00, 400)
                    revert(0x00, 0x20)
                }
            }







            function validateCommitment(note, k, a) {
                let gen_order := 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001
                let field_order := 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47
                let gammaX := calldataload(add(note, 0x40))
                let gammaY := calldataload(add(note, 0x60))
                let sigmaX := calldataload(add(note, 0x80))
                let sigmaY := calldataload(add(note, 0xa0))
                if iszero(
                    and(
                        and(
                        and(
                            eq(mod(a, gen_order), a),
                            gt(a, 1)
                        ),
                        and(
                            eq(mod(k, gen_order), k),
                            gt(k, 1)
                        )
                        ),
                        and(
                        eq(
                            addmod(
                                mulmod(mulmod(sigmaX, sigmaX, field_order), sigmaX, field_order),
                                3,
                                field_order
                            ),
                            mulmod(sigmaY, sigmaY, field_order)
                        ),
                        eq(
                            addmod(
                                mulmod(mulmod(gammaX, gammaX, field_order), gammaX, field_order),
                                3,
                                field_order
                            ),
                            mulmod(gammaY, gammaY, field_order)
                        )
                        )
                    )
                ) {
                    mstore(0x00, 400)
                    revert(0x00, 0x20)
                }
            }










            function hashCommitments(notes, n) {
                for { let i := 0 } lt(i, n) { i := add(i, 0x01) } {
                    let index := add(add(notes, mul(i, 0xc0)), 0x60)
                    calldatacopy(add(0x320, mul(i, 0x80)), index, 0x80)
                }
                mstore(0x00, keccak256(0x320, mul(n, 0x80)))
            }

        }


        JoinSplitABIEncoder.encodeAndExit();
    }
}
