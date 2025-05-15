





pragma solidity ^0.5.16;


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function add(int256 a, int256 b) internal pure returns (int256 c) {
        if (b > 0) {
            c = a + b;
            assert(c >= a);
        } else {
            c = a + b;
            assert(c <= a);
        }
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    function max(int256 a, int256 b) internal pure returns (uint256) {
        return a > b ? uint256(a) : uint256(b);
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function sub(int256 a, int256 b) internal pure returns (int256 c) {
        if (b > 0) {
            c = a - b;
            assert(c <= a);
        } else {
            c = a - b;
            assert(c >= a);
        }

    }
}



pragma solidity ^0.5.0;






library TellorStorage {

    struct Details {
        uint256 value;
        address miner;
    }

    struct Dispute {
        bytes32 hash;
        int256 tally;
        bool executed;
        bool disputeVotePassed;
        bool isPropFork;
        address reportedMiner;
        address reportingParty;
        address proposedForkAddress;
        mapping(bytes32 => uint256) disputeUintVars;











        mapping(address => bool) voted;
    }

    struct StakeInfo {
        uint256 currentStatus;
        uint256 startDate;
    }


    struct Checkpoint {
        uint128 fromBlock;
        uint128 value;
    }

    struct Request {
        string queryString;
        string dataSymbol;
        bytes32 queryHash;
        uint256[] requestTimestamps;
        mapping(bytes32 => uint256) apiUintVars;






        mapping(uint256 => uint256) minedBlockNum;

        mapping(uint256 => uint256) finalValues;
        mapping(uint256 => bool) inDispute;
        mapping(uint256 => address[5]) minersByValue;
        mapping(uint256 => uint256[5]) valuesByTimestamp;
    }

    struct TellorStorageStruct {
        bytes32 currentChallenge;
        uint256[51] requestQ;
        uint256[] newValueTimestamps;
        Details[5] currentMiners;
        mapping(bytes32 => address) addressVars;







        mapping(bytes32 => uint256) uintVars;























        mapping(bytes32 => mapping(address => bool)) minersByChallenge;
        mapping(uint256 => uint256) requestIdByTimestamp;
        mapping(uint256 => uint256) requestIdByRequestQIndex;
        mapping(uint256 => Dispute) disputesById;
        mapping(address => Checkpoint[]) balances;
        mapping(address => mapping(address => uint256)) allowed;
        mapping(address => StakeInfo) stakerDetails;
        mapping(uint256 => Request) requestDetails;
        mapping(bytes32 => uint256) requestIdByQueryHash;
        mapping(bytes32 => uint256) disputeIdByDisputeHash;
    }
}



pragma solidity ^0.5.16;








library TellorTransfer {
    using SafeMath for uint256;

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    bytes32 public constant stakeAmount = 0x7be108969d31a3f0b261465c71f2b0ba9301cd914d55d9091c3b36a49d4d41b2;









    function transfer(TellorStorage.TellorStorageStruct storage self, address _to, uint256 _amount) public returns (bool success) {
        doTransfer(self, msg.sender, _to, _amount);
        return true;
    }









    function transferFrom(TellorStorage.TellorStorageStruct storage self, address _from, address _to, uint256 _amount)
        public
        returns (bool success)
    {
        require(self.allowed[_from][msg.sender] >= _amount, "Allowance is wrong");
        self.allowed[_from][msg.sender] -= _amount;
        doTransfer(self, _from, _to, _amount);
        return true;
    }







    function approve(TellorStorage.TellorStorageStruct storage self, address _spender, uint256 _amount) public returns (bool) {
        require(_spender != address(0), "Spender is 0-address");
        require(self.allowed[msg.sender][_spender] == 0 || _amount == 0, "Spender is already approved");
        self.allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }






    function allowance(TellorStorage.TellorStorageStruct storage self, address _user, address _spender) public view returns (uint256) {
        return self.allowed[_user][_spender];
    }







    function doTransfer(TellorStorage.TellorStorageStruct storage self, address _from, address _to, uint256 _amount) public {
        require(_amount != 0, "Tried to send non-positive amount");
        require(_to != address(0), "Receiver is 0 address");
        require(allowedToTrade(self, _from, _amount), "Should have sufficient balance to trade");
        uint256 previousBalance = balanceOf(self, _from);
        updateBalanceAtNow(self.balances[_from], previousBalance - _amount);
        previousBalance = balanceOf(self,_to);
        require(previousBalance + _amount >= previousBalance, "Overflow happened");
        updateBalanceAtNow(self.balances[_to], previousBalance + _amount);
        emit Transfer(_from, _to, _amount);
    }






    function balanceOf(TellorStorage.TellorStorageStruct storage self, address _user) public view returns (uint256) {
        return balanceOfAt(self, _user, block.number);
    }







    function balanceOfAt(TellorStorage.TellorStorageStruct storage self, address _user, uint256 _blockNumber) public view returns (uint256) {
        TellorStorage.Checkpoint[] storage checkpoints = self.balances[_user];
        if (checkpoints.length == 0|| checkpoints[0].fromBlock > _blockNumber) {
            return 0;
        } else {
            if (_blockNumber >= checkpoints[checkpoints.length - 1].fromBlock) return checkpoints[checkpoints.length - 1].value;

            uint256 min = 0;
            uint256 max = checkpoints.length - 2;
            while (max > min) {
                uint256 mid = (max + min + 1) / 2;
                if  (checkpoints[mid].fromBlock ==_blockNumber){
                    return checkpoints[mid].value;
                }else if(checkpoints[mid].fromBlock < _blockNumber) {
                    min = mid;
                } else {
                    max = mid - 1;
                }
            }
            return checkpoints[min].value;
        }
    }







    function allowedToTrade(TellorStorage.TellorStorageStruct storage self, address _user, uint256 _amount) public view returns (bool) {
        if (self.stakerDetails[_user].currentStatus != 0 && self.stakerDetails[_user].currentStatus < 5) {

            if (balanceOf(self, _user)- self.uintVars[stakeAmount] >= _amount) {
                return true;
            }
            return false;
        }
        return (balanceOf(self, _user) >= _amount);
    }






    function updateBalanceAtNow(TellorStorage.Checkpoint[] storage checkpoints, uint256 _value) public {
        if (checkpoints.length == 0 || checkpoints[checkpoints.length - 1].fromBlock != block.number) {
           checkpoints.push(TellorStorage.Checkpoint({
                fromBlock : uint128(block.number),
                value : uint128(_value)
            }));
        } else {
            TellorStorage.Checkpoint storage oldCheckPoint = checkpoints[checkpoints.length - 1];
            oldCheckPoint.value = uint128(_value);
        }
    }
}



pragma solidity ^0.5.16;









library TellorDispute {
    using SafeMath for uint256;
    using SafeMath for int256;


    event NewDispute(uint256 indexed _disputeId, uint256 indexed _requestId, uint256 _timestamp, address _miner);

    event Voted(uint256 indexed _disputeID, bool _position, address indexed _voter, uint256 indexed _voteWeight);

    event DisputeVoteTallied(uint256 indexed _disputeID, int256 _result, address indexed _reportedMiner, address _reportingParty, bool _active);
    event NewTellorAddress(address _newTellor);












    function beginDispute(TellorStorage.TellorStorageStruct storage self, uint256 _requestId, uint256 _timestamp, uint256 _minerIndex) public {
        TellorStorage.Request storage _request = self.requestDetails[_requestId];
        require(_request.minedBlockNum[_timestamp] != 0, "Mined block is 0");
        require(_minerIndex < 5, "Miner index is wrong");



        address _miner = _request.minersByValue[_timestamp][_minerIndex];
        bytes32 _hash = keccak256(abi.encodePacked(_miner, _requestId, _timestamp));




        uint256 disputeId = self.uintVars[keccak256("disputeCount")] + 1;
        self.uintVars[keccak256("disputeCount")] = disputeId;




        uint256 hashId = self.disputeIdByDisputeHash[_hash];
        if(hashId != 0){
            self.disputesById[disputeId].disputeUintVars[keccak256("origID")] = hashId;

        }
        else{
            self.disputeIdByDisputeHash[_hash] = disputeId;
            hashId = disputeId;
        }
        uint256 origID = hashId;
        uint256 dispRounds = self.disputesById[origID].disputeUintVars[keccak256("disputeRounds")] + 1;
        self.disputesById[origID].disputeUintVars[keccak256("disputeRounds")] = dispRounds;
        self.disputesById[origID].disputeUintVars[keccak256(abi.encode(dispRounds))] = disputeId;
        if(disputeId != origID){
            uint256 lastID =  self.disputesById[origID].disputeUintVars[keccak256(abi.encode(dispRounds-1))];
            require(self.disputesById[lastID].disputeUintVars[keccak256("minExecutionDate")] <= now, "Dispute is already open");
            if(self.disputesById[lastID].executed){
                require(now - self.disputesById[lastID].disputeUintVars[keccak256("tallyDate")] <= 1 days, "Time for voting haven't elapsed");
            }
        }
        uint256 _fee;
        if (_minerIndex == 2) {
            self.requestDetails[_requestId].apiUintVars[keccak256("disputeCount")] = self.requestDetails[_requestId].apiUintVars[keccak256("disputeCount")] +1;

            _fee = self.uintVars[keccak256("stakeAmount")]*self.requestDetails[_requestId].apiUintVars[keccak256("disputeCount")];
        } else {

            _fee = self.uintVars[keccak256("disputeFee")] * dispRounds;
        }


        self.disputesById[disputeId] = TellorStorage.Dispute({
            hash: _hash,
            isPropFork: false,
            reportedMiner: _miner,
            reportingParty: msg.sender,
            proposedForkAddress: address(0),
            executed: false,
            disputeVotePassed: false,
            tally: 0
        });


        self.disputesById[disputeId].disputeUintVars[keccak256("requestId")] = _requestId;
        self.disputesById[disputeId].disputeUintVars[keccak256("timestamp")] = _timestamp;
        self.disputesById[disputeId].disputeUintVars[keccak256("value")] = _request.valuesByTimestamp[_timestamp][_minerIndex];
        self.disputesById[disputeId].disputeUintVars[keccak256("minExecutionDate")] = now + 2 days * dispRounds;
        self.disputesById[disputeId].disputeUintVars[keccak256("blockNumber")] = block.number;
        self.disputesById[disputeId].disputeUintVars[keccak256("minerSlot")] = _minerIndex;
        self.disputesById[disputeId].disputeUintVars[keccak256("fee")] = _fee;
        TellorTransfer.doTransfer(self, msg.sender, address(this),_fee);






        if (_minerIndex == 2) {
            _request.inDispute[_timestamp] = true;
            _request.finalValues[_timestamp] = 0;
        }
        if (self.stakerDetails[_miner].currentStatus != 4){
            self.stakerDetails[_miner].currentStatus = 3;
        }
        emit NewDispute(disputeId, _requestId, _timestamp, _miner);
    }






    function vote(TellorStorage.TellorStorageStruct storage self, uint256 _disputeId, bool _supportsDispute) public {
        TellorStorage.Dispute storage disp = self.disputesById[_disputeId];


        uint256 voteWeight = TellorTransfer.balanceOfAt(self, msg.sender, disp.disputeUintVars[keccak256("blockNumber")]);


        require(disp.voted[msg.sender] != true, "Sender has already voted");


        require(voteWeight != 0, "User balance is 0");


        require(self.stakerDetails[msg.sender].currentStatus != 3, "Miner is under dispute");


        disp.voted[msg.sender] = true;


        disp.disputeUintVars[keccak256("numberOfVotes")] += 1;



        if (_supportsDispute) {
            disp.tally = disp.tally.add(int256(voteWeight));
        } else {
            disp.tally = disp.tally.sub(int256(voteWeight));
        }


        emit Voted(_disputeId, _supportsDispute, msg.sender, voteWeight);
    }





    function tallyVotes(TellorStorage.TellorStorageStruct storage self, uint256 _disputeId) public {
        TellorStorage.Dispute storage disp = self.disputesById[_disputeId];


        require(disp.executed == false, "Dispute has been already executed");
        require(now >= disp.disputeUintVars[keccak256("minExecutionDate")], "Time for voting haven't elapsed");
        require(disp.reportingParty != address(0), "reporting Party is address 0");
        int256  _tally = disp.tally;
        if (_tally > 0) {

            disp.disputeVotePassed = true;
        }

        if (disp.isPropFork == false) {

                    TellorStorage.StakeInfo storage stakes = self.stakerDetails[disp.reportedMiner];


                    if(stakes.currentStatus == 3){
                        stakes.currentStatus = 4;
                    }
        } else if (uint(_tally) >= ((self.uintVars[keccak256("total_supply")] * 10) / 100)) {
            emit NewTellorAddress(disp.proposedForkAddress);
        }
        disp.disputeUintVars[keccak256("tallyDate")] = now;
        disp.executed = true;
        emit DisputeVoteTallied(_disputeId, _tally, disp.reportedMiner, disp.reportingParty, disp.disputeVotePassed);
    }





    function proposeFork(TellorStorage.TellorStorageStruct storage self, address _propNewTellorAddress) public {
        bytes32 _hash = keccak256(abi.encode(_propNewTellorAddress));
        TellorTransfer.doTransfer(self, msg.sender, address(this), 100e18);
        self.uintVars[keccak256("disputeCount")]++;
        uint256 disputeId = self.uintVars[keccak256("disputeCount")];
        if(self.disputeIdByDisputeHash[_hash] != 0){
            self.disputesById[disputeId].disputeUintVars[keccak256("origID")] = self.disputeIdByDisputeHash[_hash];
        }
        else{
            self.disputeIdByDisputeHash[_hash] = disputeId;
        }
        uint256 origID = self.disputeIdByDisputeHash[_hash];

        self.disputesById[origID].disputeUintVars[keccak256("disputeRounds")]++;
        uint256 dispRounds = self.disputesById[origID].disputeUintVars[keccak256("disputeRounds")];
        self.disputesById[origID].disputeUintVars[keccak256(abi.encode(dispRounds))] = disputeId;
        if(disputeId != origID){
            uint256 lastID =  self.disputesById[origID].disputeUintVars[keccak256(abi.encode(dispRounds-1))];
            require(self.disputesById[lastID].disputeUintVars[keccak256("minExecutionDate")] <= now, "Dispute is already open");
            if(self.disputesById[lastID].executed){
                require(now - self.disputesById[lastID].disputeUintVars[keccak256("tallyDate")] <= 1 days, "Time for voting haven't elapsed");
            }
        }
        self.disputesById[disputeId] = TellorStorage.Dispute({
            hash: _hash,
            isPropFork: true,
            reportedMiner: msg.sender,
            reportingParty: msg.sender,
            proposedForkAddress: _propNewTellorAddress,
            executed: false,
            disputeVotePassed: false,
            tally: 0
        });
        self.disputesById[disputeId].disputeUintVars[keccak256("blockNumber")] = block.number;
        self.disputesById[disputeId].disputeUintVars[keccak256("minExecutionDate")] = now + 7 days;
    }






    function updateTellor(TellorStorage.TellorStorageStruct storage self, uint _disputeId) public {
        bytes32 _hash = self.disputesById[_disputeId].hash;
        uint256 origID = self.disputeIdByDisputeHash[_hash];
        uint256 lastID =  self.disputesById[origID].disputeUintVars[keccak256(abi.encode(self.disputesById[origID].disputeUintVars[keccak256("disputeRounds")]))];
        TellorStorage.Dispute storage disp = self.disputesById[lastID];
        require(disp.disputeVotePassed == true, "vote needs to pass");
        require(now - disp.disputeUintVars[keccak256("tallyDate")] > 1 days, "Time for voting for further disputes has not passed");
        self.addressVars[keccak256("tellorContract")] = disp.proposedForkAddress;
    }





    function unlockDisputeFee (TellorStorage.TellorStorageStruct storage self, uint _disputeId) public {
        uint256 origID = self.disputeIdByDisputeHash[self.disputesById[_disputeId].hash];
        uint256 lastID =  self.disputesById[origID].disputeUintVars[keccak256(abi.encode(self.disputesById[origID].disputeUintVars[keccak256("disputeRounds")]))];
        if(lastID == 0){
            lastID = origID;
        }
        TellorStorage.Dispute storage disp = self.disputesById[origID];
        TellorStorage.Dispute storage last = self.disputesById[lastID];

        uint256 dispRounds = disp.disputeUintVars[keccak256("disputeRounds")];
        if(dispRounds == 0){
          dispRounds = 1;
        }
        uint256 _id;
        require(disp.disputeUintVars[keccak256("paid")] == 0,"already paid out");
        require(now - last.disputeUintVars[keccak256("tallyDate")] > 1 days, "Time for voting haven't elapsed");
        TellorStorage.StakeInfo storage stakes = self.stakerDetails[disp.reportedMiner];
        disp.disputeUintVars[keccak256("paid")] = 1;
        if (last.disputeVotePassed == true){

                stakes.startDate = now - (now % 86400);


                self.uintVars[keccak256("stakerCount")] -= 1;


                updateMinDisputeFee(self);

                if(stakes.currentStatus == 4){
                    stakes.currentStatus = 5;
                    TellorTransfer.doTransfer(self,disp.reportedMiner,disp.reportingParty,self.uintVars[keccak256("stakeAmount")]);
                    stakes.currentStatus =0 ;
                }
                for(uint i = 0; i < dispRounds;i++){
                    _id = disp.disputeUintVars[keccak256(abi.encode(dispRounds-i))];
                    if(_id == 0){
                        _id = origID;
                    }
                    TellorStorage.Dispute storage disp2 = self.disputesById[_id];

                    TellorTransfer.doTransfer(self,address(this), disp2.reportingParty, disp2.disputeUintVars[keccak256("fee")]);
                }
            }
            else {
                stakes.currentStatus = 1;
                TellorStorage.Request storage _request = self.requestDetails[disp.disputeUintVars[keccak256("requestId")]];
                if(disp.disputeUintVars[keccak256("minerSlot")] == 2) {

                  _request.finalValues[disp.disputeUintVars[keccak256("timestamp")]] = disp.disputeUintVars[keccak256("value")];
                }
                if (_request.inDispute[disp.disputeUintVars[keccak256("timestamp")]] == true) {
                    _request.inDispute[disp.disputeUintVars[keccak256("timestamp")]] = false;
                }
                for(uint i = 0; i < dispRounds;i++){
                    _id = disp.disputeUintVars[keccak256(abi.encode(dispRounds-i))];
                    if(_id != 0){
                        last = self.disputesById[_id];
                    }
                    TellorTransfer.doTransfer(self,address(this),last.reportedMiner,self.disputesById[_id].disputeUintVars[keccak256("fee")]);
                }
            }

            if (disp.disputeUintVars[keccak256("minerSlot")] == 2) {
                self.requestDetails[disp.disputeUintVars[keccak256("requestId")]].apiUintVars[keccak256("disputeCount")]--;
            }
    }





    function updateMinDisputeFee(TellorStorage.TellorStorageStruct storage self) public {
        uint256 stakeAmount = self.uintVars[keccak256("stakeAmount")];
        uint256 targetMiners = self.uintVars[keccak256("targetMiners")];
        self.uintVars[keccak256("disputeFee")] = SafeMath.max(15e18,
                (stakeAmount-(stakeAmount*(SafeMath.min(targetMiners,self.uintVars[keccak256("stakerCount")])*1000)/
                targetMiners)/1000));
    }
}



pragma solidity ^0.5.16;




library Utilities {













    function getMax(uint256[51] memory data) internal pure returns (uint256 max, uint256 maxIndex) {
        maxIndex = 1;
        max = data[maxIndex];
        for (uint256 i = 2; i < data.length; i++) {
            if (data[i] > max) {
                max = data[i];
                maxIndex = i;
            }
        }
    }






    function getMin(uint256[51] memory data) internal pure returns (uint256 min, uint256 minIndex) {
        minIndex = data.length - 1;
        min = data[minIndex];
        for (uint256 i = data.length - 2; i > 0; i--) {
            if (data[i] < min) {
                min = data[i];
                minIndex = i;
            }
        }
    }






    function getMax5(uint256[51] memory data) internal pure returns (uint256[5] memory max, uint256[5] memory maxIndex) {
        uint256 min5 = data[1];
        uint256 minI = 0;
        for(uint256 j=0;j<5;j++){
            max[j]= data[j+1];
            maxIndex[j] = j+1;
            if(max[j] < min5){
                min5 = max[j];
                minI = j;
            }
        }
        for(uint256 i = 6; i < data.length; i++) {
            if (data[i] > min5) {
                max[minI] = data[i];
                maxIndex[minI] = i;
                min5 = data[i];
                for(uint256 j=0;j<5;j++){
                    if(max[j] < min5){
                        min5 = max[j];
                        minI = j;
                    }
                }
            }
        }
    }
}



pragma solidity ^0.5.16;










library TellorStake {
    event NewStake(address indexed _sender);
    event StakeWithdrawn(address indexed _sender);
    event StakeWithdrawRequested(address indexed _sender);







    function init(TellorStorage.TellorStorageStruct storage self) public {
        require(self.uintVars[keccak256("decimals")] == 0, "Too many decimals");

        TellorTransfer.updateBalanceAtNow(self.balances[address(this)], 2**256 - 1 - 6000e18);



        address payable[6] memory _initalMiners = [
            address(0xE037EC8EC9ec423826750853899394dE7F024fee),
            address(0xcdd8FA31AF8475574B8909F135d510579a8087d3),
            address(0xb9dD5AfD86547Df817DA2d0Fb89334A6F8eDd891),
            address(0x230570cD052f40E14C14a81038c6f3aa685d712B),
            address(0x3233afA02644CCd048587F8ba6e99b3C00A34DcC),
            address(0xe010aC6e0248790e08F42d5F697160DEDf97E024)
        ];

        for (uint256 i = 0; i < 6; i++) {


            TellorTransfer.updateBalanceAtNow(self.balances[_initalMiners[i]], 1000e18);

            newStake(self, _initalMiners[i]);
        }


        self.uintVars[keccak256("total_supply")] += 6000e18;

        self.uintVars[keccak256("decimals")] = 18;
        self.uintVars[keccak256("targetMiners")] = 200;
        self.uintVars[keccak256("stakeAmount")] = 1000e18;
        self.uintVars[keccak256("disputeFee")] = 970e18;
        self.uintVars[keccak256("timeTarget")] = 600;
        self.uintVars[keccak256("timeOfLastNewValue")] = now - (now % self.uintVars[keccak256("timeTarget")]);
        self.uintVars[keccak256("difficulty")] = 1;
    }






    function requestStakingWithdraw(TellorStorage.TellorStorageStruct storage self) public {
        TellorStorage.StakeInfo storage stakes = self.stakerDetails[msg.sender];

        require(stakes.currentStatus == 1, "Miner is not staked");


        stakes.currentStatus = 2;



        stakes.startDate = now - (now % 86400);


        self.uintVars[keccak256("stakerCount")] -= 1;


        TellorDispute.updateMinDisputeFee(self);
        emit StakeWithdrawRequested(msg.sender);
    }




    function withdrawStake(TellorStorage.TellorStorageStruct storage self) public {
        TellorStorage.StakeInfo storage stakes = self.stakerDetails[msg.sender];


        require(now - (now % 86400) - stakes.startDate >= 7 days, "7 days didn't pass");
        require(stakes.currentStatus == 2, "Miner was not locked for withdrawal");
        stakes.currentStatus = 0;
        emit StakeWithdrawn(msg.sender);
    }




    function depositStake(TellorStorage.TellorStorageStruct storage self) public {
        newStake(self, msg.sender);

        TellorDispute.updateMinDisputeFee(self);
    }






    function newStake(TellorStorage.TellorStorageStruct storage self, address staker) internal {
        require(TellorTransfer.balanceOf(self, staker) >= self.uintVars[keccak256("stakeAmount")], "Balance is lower than stake amount");


        require(self.stakerDetails[staker].currentStatus == 0 || self.stakerDetails[staker].currentStatus == 2, "Miner is in the wrong state");
        self.uintVars[keccak256("stakerCount")] += 1;
        self.stakerDetails[staker] = TellorStorage.StakeInfo({
            currentStatus: 1,
            startDate: now - (now % 86400)
        });
        emit NewStake(staker);
    }





    function getNewCurrentVariables(TellorStorage.TellorStorageStruct storage self) internal view returns(bytes32 _challenge,uint[5] memory _requestIds,uint256 _difficulty, uint256 _tip){
        for(uint i=0;i<5;i++){
            _requestIds[i] =  self.currentMiners[i].value;
        }
        return (self.currentChallenge,_requestIds,self.uintVars[keccak256("difficulty")],self.uintVars[keccak256("currentTotalTips")]);
    }





    function getNewVariablesOnDeck(TellorStorage.TellorStorageStruct storage self) internal view returns (uint256[5] memory idsOnDeck, uint256[5] memory tipsOnDeck) {
        idsOnDeck = getTopRequestIDs(self);
        for(uint i = 0;i<5;i++){
            tipsOnDeck[i] = self.requestDetails[idsOnDeck[i]].apiUintVars[keccak256("totalTip")];
        }
    }





    function getTopRequestIDs(TellorStorage.TellorStorageStruct storage self) internal view returns (uint256[5] memory _requestIds) {
        uint256[5] memory _max;
        uint256[5] memory _index;
        (_max, _index) = Utilities.getMax5(self.requestQ);
        for(uint i=0;i<5;i++){
            if(_max[i] != 0){
                _requestIds[i] = self.requestIdByRequestQIndex[_index[i]];
            }
            else{
                _requestIds[i] = self.currentMiners[4-i].value;
            }
        }
    }



}



pragma solidity ^0.5.0;









library TellorGettersLibrary {
    using SafeMath for uint256;

    event NewTellorAddress(address _newTellor);









    function changeDeity(TellorStorage.TellorStorageStruct storage self, address _newDeity) internal {
        require(self.addressVars[keccak256("_deity")] == msg.sender, "Sender is not deity");
        self.addressVars[keccak256("_deity")] = _newDeity;
    }






    function changeTellorContract(TellorStorage.TellorStorageStruct storage self, address _tellorContract) internal {
        require(self.addressVars[keccak256("_deity")] == msg.sender, "Sender is not deity");
        self.addressVars[keccak256("tellorContract")] = _tellorContract;
        emit NewTellorAddress(_tellorContract);
    }









    function didMine(TellorStorage.TellorStorageStruct storage self, bytes32 _challenge, address _miner) public view returns (bool) {
        return self.minersByChallenge[_challenge][_miner];
    }







    function didVote(TellorStorage.TellorStorageStruct storage self, uint256 _disputeId, address _address) internal view returns (bool) {
        return self.disputesById[_disputeId].voted[_address];
    }









    function getAddressVars(TellorStorage.TellorStorageStruct storage self, bytes32 _data) internal view returns (address) {
        return self.addressVars[_data];
    }






















    function getAllDisputeVars(TellorStorage.TellorStorageStruct storage self, uint256 _disputeId)
        internal
        view
        returns (bytes32, bool, bool, bool, address, address, address, uint256[9] memory, int256)
    {
        TellorStorage.Dispute storage disp = self.disputesById[_disputeId];
        return (
            disp.hash,
            disp.executed,
            disp.disputeVotePassed,
            disp.isPropFork,
            disp.reportedMiner,
            disp.reportingParty,
            disp.proposedForkAddress,
            [
                disp.disputeUintVars[keccak256("requestId")],
                disp.disputeUintVars[keccak256("timestamp")],
                disp.disputeUintVars[keccak256("value")],
                disp.disputeUintVars[keccak256("minExecutionDate")],
                disp.disputeUintVars[keccak256("numberOfVotes")],
                disp.disputeUintVars[keccak256("blockNumber")],
                disp.disputeUintVars[keccak256("minerSlot")],
                disp.disputeUintVars[keccak256("quorum")],
                disp.disputeUintVars[keccak256("fee")]
            ],
            disp.tally
        );
    }





    function getCurrentVariables(TellorStorage.TellorStorageStruct storage self)
        internal
        view
        returns (bytes32, uint256, uint256, string memory, uint256, uint256)
    {
        return (
            self.currentChallenge,
            self.uintVars[keccak256("currentRequestId")],
            self.uintVars[keccak256("difficulty")],
            self.requestDetails[self.uintVars[keccak256("currentRequestId")]].queryString,
            self.requestDetails[self.uintVars[keccak256("currentRequestId")]].apiUintVars[keccak256("granularity")],
            self.requestDetails[self.uintVars[keccak256("currentRequestId")]].apiUintVars[keccak256("totalTip")]
        );
    }






    function getDisputeIdByDisputeHash(TellorStorage.TellorStorageStruct storage self, bytes32 _hash) internal view returns (uint256) {
        return self.disputeIdByDisputeHash[_hash];
    }









    function getDisputeUintVars(TellorStorage.TellorStorageStruct storage self, uint256 _disputeId, bytes32 _data)
        internal
        view
        returns (uint256)
    {
        return self.disputesById[_disputeId].disputeUintVars[_data];
    }






    function getLastNewValue(TellorStorage.TellorStorageStruct storage self) internal view returns (uint256, bool) {
        return (
            retrieveData(
                self,
                self.requestIdByTimestamp[self.uintVars[keccak256("timeOfLastNewValue")]],
                self.uintVars[keccak256("timeOfLastNewValue")]
            ),
            true
        );
    }






    function getLastNewValueById(TellorStorage.TellorStorageStruct storage self, uint256 _requestId) internal view returns (uint256, bool) {
        TellorStorage.Request storage _request = self.requestDetails[_requestId];
        if (_request.requestTimestamps.length != 0) {
            return (retrieveData(self, _requestId, _request.requestTimestamps[_request.requestTimestamps.length - 1]), true);
        } else {
            return (0, false);
        }
    }







    function getMinedBlockNum(TellorStorage.TellorStorageStruct storage self, uint256 _requestId, uint256 _timestamp)
        internal
        view
        returns (uint256)
    {
        return self.requestDetails[_requestId].minedBlockNum[_timestamp];
    }







    function getMinersByRequestIdAndTimestamp(TellorStorage.TellorStorageStruct storage self, uint256 _requestId, uint256 _timestamp)
        internal
        view
        returns (address[5] memory)
    {
        return self.requestDetails[_requestId].minersByValue[_timestamp];
    }








    function getNewValueCountbyRequestId(TellorStorage.TellorStorageStruct storage self, uint256 _requestId) internal view returns (uint256) {
        return self.requestDetails[_requestId].requestTimestamps.length;
    }






    function getRequestIdByRequestQIndex(TellorStorage.TellorStorageStruct storage self, uint256 _index) internal view returns (uint256) {
        require(_index <= 50, "RequestQ index is above 50");
        return self.requestIdByRequestQIndex[_index];
    }






    function getRequestIdByTimestamp(TellorStorage.TellorStorageStruct storage self, uint256 _timestamp) internal view returns (uint256) {
        return self.requestIdByTimestamp[_timestamp];
    }






    function getRequestIdByQueryHash(TellorStorage.TellorStorageStruct storage self, bytes32 _queryHash) internal view returns (uint256) {
        return self.requestIdByQueryHash[_queryHash];
    }





    function getRequestQ(TellorStorage.TellorStorageStruct storage self) internal view returns (uint256[51] memory) {
        return self.requestQ;
    }










    function getRequestUintVars(TellorStorage.TellorStorageStruct storage self, uint256 _requestId, bytes32 _data)
        internal
        view
        returns (uint256)
    {
        return self.requestDetails[_requestId].apiUintVars[_data];
    }











    function getRequestVars(TellorStorage.TellorStorageStruct storage self, uint256 _requestId)
        internal
        view
        returns (string memory, string memory, bytes32, uint256, uint256, uint256)
    {
        TellorStorage.Request storage _request = self.requestDetails[_requestId];
        return (
            _request.queryString,
            _request.dataSymbol,
            _request.queryHash,
            _request.apiUintVars[keccak256("granularity")],
            _request.apiUintVars[keccak256("requestQPosition")],
            _request.apiUintVars[keccak256("totalTip")]
        );
    }







    function getStakerInfo(TellorStorage.TellorStorageStruct storage self, address _staker) internal view returns (uint256, uint256) {
        return (self.stakerDetails[_staker].currentStatus, self.stakerDetails[_staker].startDate);
    }







    function getSubmissionsByTimestamp(TellorStorage.TellorStorageStruct storage self, uint256 _requestId, uint256 _timestamp)
        internal
        view
        returns (uint256[5] memory)
    {
        return self.requestDetails[_requestId].valuesByTimestamp[_timestamp];
    }







    function getTimestampbyRequestIDandIndex(TellorStorage.TellorStorageStruct storage self, uint256 _requestID, uint256 _index)
        internal
        view
        returns (uint256)
    {
        return self.requestDetails[_requestID].requestTimestamps[_index];
    }










    function getUintVar(TellorStorage.TellorStorageStruct storage self, bytes32 _data) internal view returns (uint256) {
        return self.uintVars[_data];
    }





    function getVariablesOnDeck(TellorStorage.TellorStorageStruct storage self) internal view returns (uint256, uint256, string memory) {
        uint256 newRequestId = getTopRequestID(self);
        return (
            newRequestId,
            self.requestDetails[newRequestId].apiUintVars[keccak256("totalTip")],
            self.requestDetails[newRequestId].queryString
        );
    }





    function getTopRequestID(TellorStorage.TellorStorageStruct storage self) internal view returns (uint256 _requestId) {
        uint256 _max;
        uint256 _index;
        (_max, _index) = Utilities.getMax(self.requestQ);
        _requestId = self.requestIdByRequestQIndex[_index];
    }







    function isInDispute(TellorStorage.TellorStorageStruct storage self, uint256 _requestId, uint256 _timestamp) internal view returns (bool) {
        return self.requestDetails[_requestId].inDispute[_timestamp];
    }







    function retrieveData(TellorStorage.TellorStorageStruct storage self, uint256 _requestId, uint256 _timestamp)
        internal
        view
        returns (uint256)
    {
        return self.requestDetails[_requestId].finalValues[_timestamp];
    }





    function totalSupply(TellorStorage.TellorStorageStruct storage self) internal view returns (uint256) {
        return self.uintVars[keccak256("total_supply")];
    }

}



pragma solidity ^0.5.16;













library TellorLibrary {
    using SafeMath for uint256;

    bytes32 public constant requestCount = 0x05de9147d05477c0a5dc675aeea733157f5092f82add148cf39d579cafe3dc98;
    bytes32 public constant totalTip = 0x2a9e355a92978430eca9c1aa3a9ba590094bac282594bccf82de16b83046e2c3;
    bytes32 public constant _tBlock = 0x969ea04b74d02bb4d9e6e8e57236e1b9ca31627139ae9f0e465249932e824502;
    bytes32 public constant timeOfLastNewValue = 0x97e6eb29f6a85471f7cc9b57f9e4c3deaf398cfc9798673160d7798baf0b13a4;
    bytes32 public constant difficulty = 0xb12aff7664b16cb99339be399b863feecd64d14817be7e1f042f97e3f358e64e;
    bytes32 public constant timeTarget = 0xad16221efc80aaf1b7e69bd3ecb61ba5ffa539adf129c3b4ffff769c9b5bbc33;
    bytes32 public constant runningTips = 0xdb21f0c4accc4f2f5f1045353763a9ffe7091ceaf0fcceb5831858d96cf84631;
    bytes32 public constant currentReward = 0x9b6853911475b07474368644a0d922ee13bc76a15cd3e97d3e334326424a47d4;
    bytes32 public constant total_supply = 0xb1557182e4359a1f0c6301278e8f5b35a776ab58d39892581e357578fb287836;
    bytes32 public constant devShare = 0x8fe9ded8d7c08f720cf0340699024f83522ea66b2bbfb8f557851cb9ee63b54c;
    bytes32 public constant _owner =  0x9dbc393ddc18fd27b1d9b1b129059925688d2f2d5818a5ec3ebb750b7c286ea6;
    bytes32 public constant requestQPosition = 0x1e344bd070f05f1c5b3f0b1266f4f20d837a0a8190a3a2da8b0375eac2ba86ea;
    bytes32 public constant currentTotalTips = 0xd26d9834adf5a73309c4974bf654850bb699df8505e70d4cfde365c417b19dfc;
    bytes32 public constant slotProgress =0x6c505cb2db6644f57b42d87bd9407b0f66788b07d0617a2bc1356a0e69e66f9a;
    bytes32 public constant pending_owner = 0x44b2657a0f8a90ed8e62f4c4cceca06eacaa9b4b25751ae1ebca9280a70abd68;
    bytes32 public constant currentRequestId = 0x7584d7d8701714da9c117f5bf30af73b0b88aca5338a84a21eb28de2fe0d93b8;


    event TipAdded(address indexed _sender, uint256 indexed _requestId, uint256 _tip, uint256 _totalTips);

    event NewChallenge(
        bytes32 indexed _currentChallenge,
        uint256[5] _currentRequestId,
        uint256 _difficulty,
        uint256 _totalTips
    );

    event NewValue(uint256[5] _requestId, uint256 _time, uint256[5] _value, uint256 _totalTips, bytes32 indexed _currentChallenge);

    event NonceSubmitted(address indexed _miner, string _nonce, uint256[5] _requestId, uint256[5] _value, bytes32 indexed _currentChallenge);
    event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);
    event OwnershipProposed(address indexed _previousOwner, address indexed _newOwner);








    function addTip(TellorStorage.TellorStorageStruct storage self, uint256 _requestId, uint256 _tip) public {
        require(_requestId != 0, "RequestId is 0");
        require(_tip != 0, "Tip should be greater than 0");
        uint256 _count =self.uintVars[requestCount] + 1;
        if(_requestId == _count){
            self.uintVars[requestCount] = _count;
        }
        else{
            require(_requestId < _count, "RequestId is not less than count");
        }
        TellorTransfer.doTransfer(self, msg.sender, address(this), _tip);

        updateOnDeck(self, _requestId, _tip);
        emit TipAdded(msg.sender, _requestId, _tip, self.requestDetails[_requestId].apiUintVars[totalTip]);
    }







    function newBlock(TellorStorage.TellorStorageStruct storage self, string memory _nonce, uint256[5] memory _requestId) public {
        TellorStorage.Request storage _tblock = self.requestDetails[self.uintVars[_tBlock]];



        int256 _change = int256(SafeMath.min(1200, (now - self.uintVars[timeOfLastNewValue])));
        int256 _diff = int256(self.uintVars[difficulty]);
        _change = (_diff * (int256(self.uintVars[timeTarget]) - _change)) / 4000;
        if (_change == 0) {
                _change = 1;
            }
        self.uintVars[difficulty]  = uint256(SafeMath.max(_diff + _change,1));

        bytes32 _currChallenge = self.currentChallenge;
        uint256 _timeOfLastNewValue = now - (now % 1 minutes);
        self.uintVars[timeOfLastNewValue] = _timeOfLastNewValue;
        uint[5] memory a;
        for (uint k = 0; k < 5; k++) {
            for (uint i = 1; i < 5; i++) {
                uint256 temp = _tblock.valuesByTimestamp[k][i];
                address temp2 = _tblock.minersByValue[k][i];
                uint256 j = i;
                while (j > 0 && temp < _tblock.valuesByTimestamp[k][j - 1]) {
                    _tblock.valuesByTimestamp[k][j] = _tblock.valuesByTimestamp[k][j - 1];
                    _tblock.minersByValue[k][j] = _tblock.minersByValue[k][j - 1];
                    j--;
                }
                if (j < i) {
                    _tblock.valuesByTimestamp[k][j] = temp;
                    _tblock.minersByValue[k][j] = temp2;
                }
            }
            TellorStorage.Request storage _request = self.requestDetails[_requestId[k]];

            a = _tblock.valuesByTimestamp[k];
            _request.finalValues[_timeOfLastNewValue] = a[2];
            _request.minersByValue[_timeOfLastNewValue] = _tblock.minersByValue[k];
            _request.valuesByTimestamp[_timeOfLastNewValue] = _tblock.valuesByTimestamp[k];
            delete _tblock.minersByValue[k];
            delete _tblock.valuesByTimestamp[k];
            _request.requestTimestamps.push(_timeOfLastNewValue);
            _request.minedBlockNum[_timeOfLastNewValue] = block.number;
            _request.apiUintVars[totalTip] = 0;
        }
            emit NewValue(
                _requestId,
                _timeOfLastNewValue,
                a,
                self.uintVars[runningTips],
                _currChallenge
            );

        self.requestIdByTimestamp[_timeOfLastNewValue] = _requestId[0];

        self.newValueTimestamps.push(_timeOfLastNewValue);

        uint _currReward = self.uintVars[currentReward];

        _timeOfLastNewValue = _currReward;
        if (_currReward > 1e18) {

            _currReward = _currReward - _currReward *  15306316590563/1e18;
            self.uintVars[devShare] = _currReward * 50/100;
            _timeOfLastNewValue = _currReward;
        } else {
            _timeOfLastNewValue = 1e18;
        }
        self.uintVars[currentReward] = _timeOfLastNewValue;
        _currReward = _timeOfLastNewValue;
        uint _devShare = self.uintVars[devShare];

        self.uintVars[total_supply] +=  _devShare + _currReward*5 - (self.uintVars[currentTotalTips]);
        TellorTransfer.doTransfer(self, address(this), self.addressVars[_owner],  _devShare);
        self.uintVars[_tBlock] ++;

        self.uintVars[currentTotalTips] = 0;
        uint256[5] memory _topId = TellorStake.getTopRequestIDs(self);
        for(uint i = 0; i< 5;i++){
            self.currentMiners[i].value = _topId[i];
            self.requestQ[self.requestDetails[_topId[i]].apiUintVars[requestQPosition]] = 0;
            self.uintVars[currentTotalTips] += self.requestDetails[_topId[i]].apiUintVars[totalTip];
        }


        _currChallenge = keccak256(abi.encode(_nonce, _currChallenge, blockhash(block.number - 1)));
        self.currentChallenge = _currChallenge;
        emit NewChallenge(
            _currChallenge,
            _topId,
            self.uintVars[difficulty],
            self.uintVars[currentTotalTips]
        );
    }







    function newBlock(TellorStorage.TellorStorageStruct storage self, string memory _nonce, uint256 _requestId) public {
        TellorStorage.Request storage _request = self.requestDetails[_requestId];




        int256 _change = int256(SafeMath.min(1200, (now - self.uintVars[timeOfLastNewValue])));
       int256 _diff = int256(self.uintVars[difficulty]);
        _change = (_diff * (int256(self.uintVars[timeTarget]) - _change)) / 4000;

        if (_change == 0) {
                _change = 1;
            }
        self.uintVars[difficulty]  = uint256(SafeMath.max(_diff+ _change,1));

        uint256 _timeOfLastNewValue = now - (now % 1 minutes);
        self.uintVars[timeOfLastNewValue] = _timeOfLastNewValue;


        TellorStorage.Details[5] memory a = self.currentMiners;
        uint256 i;
        for (i = 1; i < 5; i++) {
            uint256 temp = a[i].value;
            address temp2 = a[i].miner;
            uint256 j = i;
            while (j > 0 && temp < a[j - 1].value) {
                a[j].value = a[j - 1].value;
                a[j].miner = a[j - 1].miner;
                j--;
            }
            if (j < i) {
                a[j].value = temp;
                a[j].miner = temp2;
            }
        }



        if(self.uintVars[currentReward] == 0){
            self.uintVars[currentReward] = 5e18;
        }
        if (self.uintVars[currentReward] > 1e18) {
        self.uintVars[currentReward] = self.uintVars[currentReward] - self.uintVars[currentReward] * 30612633181126/1e18;
        self.uintVars[devShare] = self.uintVars[currentReward] * 50/100;
        } else {
            self.uintVars[currentReward] = 1e18;
        }
        for (i = 0; i < 5; i++) {
            TellorTransfer.doTransfer(self, address(this), a[i].miner, self.uintVars[currentReward]  + self.uintVars[currentTotalTips] / 5);
        }

        self.uintVars[total_supply] +=  self.uintVars[devShare] + self.uintVars[currentReward]*5 ;

        TellorTransfer.doTransfer(self, address(this), self.addressVars[_owner],  self.uintVars[devShare]);

        _request.finalValues[_timeOfLastNewValue] = a[2].value;
        _request.requestTimestamps.push(_timeOfLastNewValue);

        _request.minersByValue[_timeOfLastNewValue] = [a[0].miner, a[1].miner, a[2].miner, a[3].miner, a[4].miner];
        _request.valuesByTimestamp[_timeOfLastNewValue] = [a[0].value, a[1].value, a[2].value, a[3].value, a[4].value];
        _request.minedBlockNum[_timeOfLastNewValue] = block.number;

        self.requestIdByTimestamp[_timeOfLastNewValue] = _requestId;

        self.newValueTimestamps.push(_timeOfLastNewValue);

        self.uintVars[slotProgress] = 0;



        if(self.uintVars[timeTarget] == 600){
            self.uintVars[timeTarget] = 300;
            self.uintVars[currentReward] = self.uintVars[currentReward]/2;
            self.uintVars[_tBlock] = 1e18;
            self.uintVars[difficulty] = SafeMath.max(1,self.uintVars[difficulty]/3);
        }
        for(i = 0; i< 5;i++){
            self.currentMiners[i].value = i+1;
            self.requestQ[self.requestDetails[i+1].apiUintVars[requestQPosition]] = 0;
            self.uintVars[currentTotalTips] += self.requestDetails[i+1].apiUintVars[totalTip];
        }
        self.currentChallenge = keccak256(abi.encode(_nonce, self.currentChallenge, blockhash(block.number - 1)));
        emit NewChallenge(
            self.currentChallenge,
            [uint256(1),uint256(2),uint256(3),uint256(4),uint256(5)],
            self.uintVars[difficulty],
            self.uintVars[currentTotalTips]
        );
    }







    function submitMiningSolution(TellorStorage.TellorStorageStruct storage self, string memory _nonce, uint256 _requestId, uint256 _value)
        public
    {

        require (self.uintVars[timeTarget] == 600, "Contract has upgraded, call new function");

        require(self.stakerDetails[msg.sender].currentStatus == 1, "Miner status is not staker");


        require(_requestId == self.uintVars[currentRequestId], "RequestId is wrong");


        require(
            uint256(
                sha256(abi.encodePacked(ripemd160(abi.encodePacked(keccak256(abi.encodePacked(self.currentChallenge, msg.sender, _nonce))))))
            ) %
                self.uintVars[difficulty] ==
                0,
            "Incorrect nonce for current challenge"
        );


        require(self.minersByChallenge[self.currentChallenge][msg.sender] == false, "Miner already submitted the value");


        self.currentMiners[self.uintVars[slotProgress]].value = _value;
        self.currentMiners[self.uintVars[slotProgress]].miner = msg.sender;


        self.uintVars[slotProgress]++;


        self.minersByChallenge[self.currentChallenge][msg.sender] = true;
        if (self.uintVars[slotProgress] == 5) {
            newBlock(self, _nonce, _requestId);
        }
    }










    function submitMiningSolution(TellorStorage.TellorStorageStruct storage self, string calldata _nonce,uint256[5] calldata _requestId, uint256[5] calldata _value)
        external
    {

        bytes32 _hashMsgSender = keccak256(abi.encodePacked(_requestId, _value));
        require(self.stakerDetails[msg.sender].currentStatus == 1, "Miner status is not staker");
        require(now - self.uintVars[_hashMsgSender] > 15 minutes, "Miner can only win rewards once per 15 min");
        require(_requestId[0] ==  self.currentMiners[0].value,"Request ID is wrong");
        require(_requestId[1] ==  self.currentMiners[1].value,"Request ID is wrong");
        require(_requestId[2] ==  self.currentMiners[2].value,"Request ID is wrong");
        require(_requestId[3] ==  self.currentMiners[3].value,"Request ID is wrong");
        require(_requestId[4] ==  self.currentMiners[4].value,"Request ID is wrong");
        self.uintVars[_hashMsgSender] = now;


        bytes32 _currChallenge = keccak256(abi.encodePacked(_requestId, _value));
        uint256 _slotProgress = self.uintVars[slotProgress];

        require(uint256(
                sha256(abi.encodePacked(ripemd160(abi.encodePacked(keccak256(abi.encodePacked(_currChallenge, msg.sender, _nonce))))))
            ) %
                self.uintVars[difficulty] == 0
                || (now - (now % 1 minutes)) - self.uintVars[timeOfLastNewValue] >= 15 minutes,
            "Incorrect nonce for current challenge"
        );


        require(self.minersByChallenge[_currChallenge][msg.sender] == false, "Miner already submitted the value");

        self.minersByChallenge[_currChallenge][msg.sender] = true;


        TellorStorage.Request storage _tblock = self.requestDetails[self.uintVars[_tBlock]];
        _tblock.minersByValue[1][_slotProgress]= msg.sender;

        _tblock.valuesByTimestamp[0][_slotProgress] = _value[0];
        _tblock.valuesByTimestamp[1][_slotProgress] = _value[1];
        _tblock.valuesByTimestamp[2][_slotProgress] = _value[2];
        _tblock.valuesByTimestamp[3][_slotProgress] = _value[3];
        _tblock.valuesByTimestamp[4][_slotProgress] = _value[4];
        _tblock.minersByValue[0][self.uintVars[slotProgress]]= msg.sender;
        _tblock.minersByValue[1][self.uintVars[slotProgress]]= msg.sender;
        _tblock.minersByValue[2][self.uintVars[slotProgress]]= msg.sender;
        _tblock.minersByValue[3][self.uintVars[slotProgress]]= msg.sender;
        _tblock.minersByValue[4][self.uintVars[slotProgress]]= msg.sender;


        _payReward(self, _slotProgress);
        self.uintVars[slotProgress]++;


        if (_slotProgress + 1 == 5) {
            newBlock(self, _nonce, _requestId);
            self.uintVars[slotProgress] = 0;
        }
        emit NonceSubmitted(msg.sender, _nonce, _requestId, _value, _currChallenge);
    }




    function _payReward(TellorStorage.TellorStorageStruct storage self, uint _slotProgress) internal {
        uint _runningTips = self.uintVars[runningTips];
        uint _currentTotalTips = self.uintVars[currentTotalTips];
        if(_slotProgress == 0){
            _runningTips = _currentTotalTips;
            self.uintVars[runningTips] = _currentTotalTips;
        }
        uint _extraTip = (_currentTotalTips-_runningTips)/(5-_slotProgress);
        TellorTransfer.doTransfer(self, address(this), msg.sender, self.uintVars[currentReward]  + _runningTips / 2 / 5 + _extraTip);
        self.uintVars[currentTotalTips] -= _extraTip;
    }








    function proposeOwnership(TellorStorage.TellorStorageStruct storage self, address payable _pendingOwner) public {
        require(msg.sender == self.addressVars[_owner], "Sender is not owner");
        emit OwnershipProposed(self.addressVars[_owner], _pendingOwner);
        self.addressVars[pending_owner] = _pendingOwner;
    }




    function claimOwnership(TellorStorage.TellorStorageStruct storage self) public {
        require(msg.sender == self.addressVars[pending_owner], "Sender is not pending owner");
        emit OwnershipTransferred(self.addressVars[_owner], self.addressVars[pending_owner]);
        self.addressVars[_owner] = self.addressVars[pending_owner];
    }






    function updateOnDeck(TellorStorage.TellorStorageStruct storage self, uint256 _requestId, uint256 _tip) public {
        TellorStorage.Request storage _request = self.requestDetails[_requestId];
        _request.apiUintVars[totalTip] = _request.apiUintVars[totalTip].add(_tip);
        if(self.currentMiners[0].value == _requestId || self.currentMiners[1].value== _requestId ||self.currentMiners[2].value == _requestId||self.currentMiners[3].value== _requestId || self.currentMiners[4].value== _requestId ){
            self.uintVars[currentTotalTips] += _tip;
        }
        else {


            if (_request.apiUintVars[requestQPosition] == 0) {
                uint256 _min;
                uint256 _index;
                (_min, _index) = Utilities.getMin(self.requestQ);



                if (_request.apiUintVars[totalTip] > _min || _min == 0) {
                    self.requestQ[_index] = _request.apiUintVars[totalTip];
                    self.requestDetails[self.requestIdByRequestQIndex[_index]].apiUintVars[requestQPosition] = 0;
                    self.requestIdByRequestQIndex[_index] = _requestId;
                    _request.apiUintVars[requestQPosition] = _index;
                }

            } else{
                self.requestQ[_request.apiUintVars[requestQPosition]] += _tip;
            }
        }
    }























































































































}



pragma solidity ^0.5.16;













contract Tellor {
    using SafeMath for uint256;

    using TellorDispute for TellorStorage.TellorStorageStruct;
    using TellorLibrary for TellorStorage.TellorStorageStruct;
    using TellorStake for TellorStorage.TellorStorageStruct;
    using TellorTransfer for TellorStorage.TellorStorageStruct;

    TellorStorage.TellorStorageStruct tellor;












    function beginDispute(uint256 _requestId, uint256 _timestamp, uint256 _minerIndex) external {
        tellor.beginDispute(_requestId, _timestamp, _minerIndex);
    }






    function vote(uint256 _disputeId, bool _supportsDispute) external {
        tellor.vote(_disputeId, _supportsDispute);
    }





    function tallyVotes(uint256 _disputeId) external {
        tellor.tallyVotes(_disputeId);
    }





    function proposeFork(address _propNewTellorAddress) external {
        tellor.proposeFork(_propNewTellorAddress);
    }







    function addTip(uint256 _requestId, uint256 _tip) external {
        tellor.addTip(_requestId, _tip);
    }









    function submitMiningSolution(string calldata _nonce, uint256 _requestId, uint256 _value) external {
        tellor.submitMiningSolution(_nonce, _requestId, _value);
    }







    function submitMiningSolution(string calldata _nonce,uint256[5] calldata _requestId, uint256[5] calldata _value) external {
        tellor.submitMiningSolution(_nonce,_requestId, _value);
    }








    function proposeOwnership(address payable _pendingOwner) external {
        tellor.proposeOwnership(_pendingOwner);
    }




    function claimOwnership() external {
        tellor.claimOwnership();
    }




    function depositStake() external {
        tellor.depositStake();
    }






    function requestStakingWithdraw() external {
        tellor.requestStakingWithdraw();
    }




    function withdrawStake() external {
        tellor.withdrawStake();
    }







    function approve(address _spender, uint256 _amount) external returns (bool) {
        return tellor.approve(_spender, _amount);
    }







    function transfer(address _to, uint256 _amount) external returns (bool) {
        return tellor.transfer(_to, _amount);
    }









    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool) {
        return tellor.transferFrom(_from, _to, _amount);
    }




    function name() external pure returns (string memory) {
        return "Tellor Tributes";
    }




    function symbol() external pure returns (string memory) {
        return "TRB";
    }




    function decimals() external pure returns (uint8) {
        return 18;
    }





    function getNewCurrentVariables() external view returns(bytes32 _challenge,uint[5] memory _requestIds,uint256 _difficutly, uint256 _tip){
        return tellor.getNewCurrentVariables();
    }





    function getTopRequestIDs() external view returns(uint256[5] memory _requestIds){
        return tellor.getTopRequestIDs();
    }





    function getNewVariablesOnDeck() external view returns (uint256[5] memory idsOnDeck, uint256[5] memory tipsOnDeck) {
        return tellor.getNewVariablesOnDeck();
    }






     function updateTellor(uint _disputeId) external{
        return tellor.updateTellor(_disputeId);
    }





     function unlockDisputeFee (uint _disputeId) external{
        return tellor.unlockDisputeFee(_disputeId);
    }















 }
