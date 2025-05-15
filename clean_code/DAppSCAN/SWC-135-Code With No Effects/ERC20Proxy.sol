

















pragma solidity 0.4.24;

import "../../utils/LibBytes/LibBytes.sol";
import "./MixinAuthorizable.sol";


contract ERC20Proxy is
    MixinAuthorizable
{

    bytes4 constant internal PROXY_ID = bytes4(keccak256("ERC20Token(address)"));


    function ()
        external
    {
        assembly {

            let selector := and(calldataload(0), 0xffffffff00000000000000000000000000000000000000000000000000000000)







            if eq(selector, 0xa85e59e400000000000000000000000000000000000000000000000000000000) {



                let start := mload(64)
                mstore(start, and(caller, 0xffffffffffffffffffffffffffffffffffffffff))
                mstore(add(start, 32), authorized_slot)


                if iszero(sload(keccak256(start, 64))) {

                    mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                    mstore(32, 0x0000002000000000000000000000000000000000000000000000000000000000)
                    mstore(64, 0x0000001553454e4445525f4e4f545f415554484f52495a454400000000000000)
                    mstore(96, 0)
                    revert(0, 100)
                }









                let token := calldataload(add(calldataload(4), 40))





                mstore(0, 0x23b872dd00000000000000000000000000000000000000000000000000000000)




                calldatacopy(4, 36, 96)


                let success := call(
                    gas,
                    token,
                    0,
                    0,
                    100,
                    0,
                    32
                )









                success := and(success, or(
                    iszero(returndatasize),
                    and(
                        eq(returndatasize, 32),
                        gt(mload(0), 0)
                    )
                ))
                if success {
                    return(0, 0)
                }


                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(32, 0x0000002000000000000000000000000000000000000000000000000000000000)
                mstore(64, 0x0000000f5452414e534645525f4641494c454400000000000000000000000000)
                mstore(96, 0)
                revert(0, 100)
            }
        }
    }



    function getProxyId()
        external
        pure
        returns (bytes4)
    {
        return PROXY_ID;
    }
}
