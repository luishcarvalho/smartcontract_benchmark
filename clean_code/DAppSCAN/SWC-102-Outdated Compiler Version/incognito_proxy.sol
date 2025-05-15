
pragma solidity ^0.5.12;
pragma experimental ABIEncoderV2;

import "./pause.sol";






contract IncognitoProxy is AdminPausable {
    struct Committee {
        address[] pubkeys;
        uint startBlock;
    }

    Committee[] public beaconCommittees;
    Committee[] public bridgeCommittees;

    event BeaconCommitteeSwapped(uint id, uint startHeight);
    event BridgeCommitteeSwapped(uint id, uint startHeight);















    constructor(
        address admin,
        address[] memory beaconCommittee,
        address[] memory bridgeCommittee
    ) public AdminPausable(admin) {
        beaconCommittees.push(Committee({
            pubkeys: beaconCommittee,
            startBlock: 0
        }));

        bridgeCommittees.push(Committee({
            pubkeys: bridgeCommittee,
            startBlock: 0
        }));
    }







    function getBeaconCommittee(uint i) public view returns(Committee memory) {
        return beaconCommittees[i];
    }





    function getBridgeCommittee(uint i) public view returns(Committee memory) {
        return bridgeCommittees[i];
    }
















    function swapBridgeCommittee(
        bytes memory inst,
        bytes32[][2] memory instPaths,
        bool[][2] memory instPathIsLefts,
        bytes32[2] memory instRoots,
        bytes32[2] memory blkData,
        uint[][2] memory sigIdxs,
        uint8[][2] memory sigVs,
        bytes32[][2] memory sigRs,
        bytes32[][2] memory sigSs
    ) public isNotPaused {
        bytes32 instHash = keccak256(inst);


        require(instructionApproved(
            true,
            instHash,
            beaconCommittees[beaconCommittees.length-1].startBlock,
            instPaths[0],
            instPathIsLefts[0],
            instRoots[0],
            blkData[0],
            sigIdxs[0],
            sigVs[0],
            sigRs[0],
            sigSs[0]
        ));


        require(instructionApproved(
            false,
            instHash,
            bridgeCommittees[bridgeCommittees.length-1].startBlock,
            instPaths[1],
            instPathIsLefts[1],
            instRoots[1],
            blkData[1],
            sigIdxs[1],
            sigVs[1],
            sigRs[1],
            sigSs[1]
        ));


        (uint8 meta, uint8 shard, uint startHeight, uint numVals) = extractMetaFromInstruction(inst);
        require(meta == 71 && shard == 1);


        require(startHeight > bridgeCommittees[bridgeCommittees.length-1].startBlock, "cannot change old committee");


        address[] memory pubkeys = extractCommitteeFromInstruction(inst, numVals);
        bridgeCommittees.push(Committee({
            pubkeys: pubkeys,
            startBlock: startHeight
        }));

        emit BridgeCommitteeSwapped(bridgeCommittees.length, startHeight);
    }








    function swapBeaconCommittee(
        bytes memory inst,
        bytes32[] memory instPath,
        bool[] memory instPathIsLeft,
        bytes32 instRoot,
        bytes32 blkData,
        uint[] memory sigIdx,
        uint8[] memory sigV,
        bytes32[] memory sigR,
        bytes32[] memory sigS
    ) public isNotPaused {
        bytes32 instHash = keccak256(inst);


        require(instructionApproved(
            true,
            instHash,
            beaconCommittees[beaconCommittees.length-1].startBlock,
            instPath,
            instPathIsLeft,
            instRoot,
            blkData,
            sigIdx,
            sigV,
            sigR,
            sigS
        ));


        (uint8 meta, uint8 shard, uint startHeight, uint numVals) = extractMetaFromInstruction(inst);
        require(meta == 70 && shard == 1);


        require(startHeight > beaconCommittees[beaconCommittees.length-1].startBlock, "cannot change old committee");


        address[] memory pubkeys = extractCommitteeFromInstruction(inst, numVals);
        beaconCommittees.push(Committee({
            pubkeys: pubkeys,
            startBlock: startHeight
        }));

        emit BeaconCommitteeSwapped(beaconCommittees.length, startHeight);
    }


















    function instructionApproved(
        bool isBeacon,
        bytes32 instHash,
        uint blkHeight,
        bytes32[] memory instPath,
        bool[] memory instPathIsLeft,
        bytes32 instRoot,
        bytes32 blkData,
        uint[] memory sigIdx,
        uint8[] memory sigV,
        bytes32[] memory sigR,
        bytes32[] memory sigS
    ) public view returns (bool) {

        address[] memory signers;
        uint _;
        if (isBeacon) {
            (signers, _) = findBeaconCommitteeFromHeight(blkHeight);
        } else {
            (signers, _) = findBridgeCommitteeFromHeight(blkHeight);
        }


        require(sigV.length == sigIdx.length);
        require(sigV.length == sigR.length);
        require(sigV.length == sigS.length);
        for (uint i = 0; i < sigIdx.length; i++) {
            if ((i > 0 && sigIdx[i] <= sigIdx[i-1]) || sigIdx[i] >= signers.length) {
                return false;
            }
            signers[i] = signers[sigIdx[i]];
        }


        bytes32 blk = keccak256(abi.encodePacked(keccak256(abi.encodePacked(blkData, instRoot))));


        if (sigIdx.length <= signers.length * 2 / 3) {
            return false;
        }


        require(verifySig(signers, blk, sigV, sigR, sigS));


        require(instructionInMerkleTree(
            instHash,
            instRoot,
            instPath,
            instPathIsLeft
        ));

        return true;
    }








    function findBeaconCommitteeFromHeight(uint blkHeight) public view returns (address[] memory, uint) {
        uint l = 0;
        uint r = beaconCommittees.length;
        require(r > 0);
        r = r - 1;
        while (l != r) {
            uint m = (l + r + 1) / 2;
            if (beaconCommittees[m].startBlock <= blkHeight) {
                l = m;
            } else {
                r = m - 1;
            }
        }
        return (beaconCommittees[l].pubkeys, l);
    }





    function findBridgeCommitteeFromHeight(uint blkHeight) public view returns (address[] memory, uint) {
        uint l = 0;
        uint r = bridgeCommittees.length;
        require(r > 0);
        r = r - 1;
        while (l != r) {
            uint m = (l + r + 1) / 2;
            if (bridgeCommittees[m].startBlock <= blkHeight) {
                l = m;
            } else {
                r = m - 1;
            }
        }
        return (bridgeCommittees[l].pubkeys, l);
    }









    function instructionInMerkleTree(
        bytes32 leaf,
        bytes32 root,
        bytes32[] memory path,
        bool[] memory left
    ) public pure returns (bool) {
        require(left.length == path.length);
        bytes32 hash = leaf;
        for (uint i = 0; i < path.length; i++) {
            if (left[i]) {
                hash = keccak256(abi.encodePacked(path[i], hash));
            } else if (path[i] == 0x0) {
                hash = keccak256(abi.encodePacked(hash, hash));
            } else {
                hash = keccak256(abi.encodePacked(hash, path[i]));
            }
        }
        return hash == root;
    }









    function extractMetaFromInstruction(bytes memory inst) public pure returns(uint8, uint8, uint, uint) {
        require(inst.length >= 0x42);
        uint8 meta = uint8(inst[0]);
        uint8 shard = uint8(inst[1]);
        uint height;
        uint numVals;
        assembly {

            height := mload(add(inst, 0x22))
            numVals := mload(add(inst, 0x42))
        }
        return (meta, shard, height, numVals);
    }







    function extractCommitteeFromInstruction(bytes memory inst, uint numVals) public pure returns (address[] memory) {
        require(inst.length == 0x42 + numVals * 0x20);
        address[] memory addr = new address[](numVals);
        address tmp;
        for (uint i = 0; i < numVals; i++) {
            assembly {


                tmp := mload(add(add(inst, 0x62), mul(i, 0x20)))
            }
            addr[i] = tmp;
        }
        return addr;
    }









    function verifySig(
        address[] memory committee,
        bytes32 msgHash,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) public pure returns (bool) {
        require(v.length == r.length);
        require(v.length == s.length);
        for (uint i = 0; i < v.length; i++){
            if (ecrecover(msgHash, v[i], r[i], s[i]) != committee[i]) {
                return false;
            }
        }
        return true;
    }
}
