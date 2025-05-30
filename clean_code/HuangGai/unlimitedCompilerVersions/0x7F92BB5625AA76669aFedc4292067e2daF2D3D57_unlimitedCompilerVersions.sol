





pragma solidity ^0.7.0;

interface IRegistry {
    function isOwner(address _addr) external view returns (bool);

    function payableOwner() external view returns (address payable);

    function isInternal(address _addr) external view returns (bool);

    function getLatestAddress(bytes2 _contractName)
        external
        view
        returns (address contractAddress);
}

interface IRelayer {
    function onReceive(address msgSender, bytes calldata msgData)
        external
        payable;

    function onDeposit(address msgSender) external payable;

    function registrationExt(address msgSender, address referrerAddress)
        external
        payable;

    function registration(address msgSender, address referrerAddress)
        external
        payable;

    function occupyMatrix(
        address msgSender,
        uint8 matrix,
        uint8 level
    ) external payable;
}












library Address {

















    function isContract(address account) internal view returns (bool) {



        bytes32 codehash;

            bytes32 accountHash
         = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

















    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );


        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }



















    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }







    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }












    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }







    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");


        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
        if (success) {
            return returndata;
        } else {

            if (returndata.length > 0) {



                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


abstract contract IUpgradable {
    IRegistry public registry;

    modifier onlyInternal {
        assert(registry.isInternal(msg.sender));
        _;
    }

    modifier onlyOwner {
        assert(registry.isOwner(msg.sender));
        _;
    }

    modifier onlyRegistry {
        assert(address(registry) == msg.sender);
        _;
    }

    function changeDependentContractAddress() public virtual;

    function changeRegistryAddress(address addr) public {
        require(Address.isContract(addr), "not contract");
        require(
            address(registry) == address(0) || address(registry) == msg.sender,
            "require registry"
        );
        registry = IRegistry(addr);
    }
}

















contract Pausable {



    event Paused(address account);




    event Unpaused(address account);

    bool private _paused;




    function paused() public view returns (bool) {
        return _paused;
    }








    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }








    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }








    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }








    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}



contract OccupyMatrix is IUpgradable, Pausable {
    IRelayer private rl;

    uint8 public constant MAX_LEVEL = 13;
    uint256 public lastUserId = 2;
    mapping(uint256 => address) public idToAddress;
    address public owner;
    mapping(uint8 => uint256) public levelPrice;
    mapping(address => User) public users;
    struct User {
        uint256 id;
        address referrer;
        uint256 partnersCount;
        mapping(uint8 => bool) activeX3Levels;
        mapping(uint8 => bool) activeX4Levels;
        mapping(uint8 => X3) x3Matrix;
        mapping(uint8 => X4) x4Matrix;
    }

    struct X3 {
        address currentReferrer;
        address[] referrals;
        bool blocked;
        uint256 reinvestCount;
    }

    struct X4 {
        address currentReferrer;
        address[] firstLevelReferrals;
        address[] secondLevelReferrals;
        bool blocked;
        uint256 reinvestCount;
        address closedPart;
    }
    event Registration(
        address indexed user,
        address indexed referrer,
        uint256 indexed userId,
        uint256 referrerId
    );
    event Reinvest(
        address indexed user,
        address indexed currentReferrer,
        address indexed caller,
        uint8 matrix,
        uint8 level
    );
    event BuyNewLevel(
        address indexed user,
        address indexed referrer,
        uint8 matrix,
        uint8 level
    );
    event NewUserPlace(
        address indexed user,
        address indexed referrer,
        uint8 matrix,
        uint8 level,
        uint8 place
    );
    event MissedEthReceive(
        address indexed receiver,
        address indexed from,
        uint8 matrix,
        uint8 level
    );
    event SentExtraEthDividends(
        address indexed from,
        address indexed receiver,
        uint8 matrix,
        uint8 level
    );

    constructor(address ownerAddress) {
        levelPrice[1] = 0.02 ether;
        for (uint8 i = 2; i <= MAX_LEVEL; i++) {
            levelPrice[i] = levelPrice[i - 1] * 2;
        }

        owner = ownerAddress;

        users[ownerAddress].id = 1;
        idToAddress[1] = ownerAddress;

        for (uint8 i = 1; i <= MAX_LEVEL; i++) {
            users[ownerAddress].activeX3Levels[i] = true;
            users[ownerAddress].activeX4Levels[i] = true;
        }
    }

    fallback() external payable {
        rl.onReceive{value: msg.value}(msg.sender, msg.data);
    }

    receive() external payable {
        rl.onReceive{value: msg.value}(msg.sender, msg.data);
    }

    function deposit() external payable {
        rl.onDeposit{value: msg.value}(msg.sender);
    }

    modifier checkRegisterMode(uint8 mode, address referrerAddress) {
        if (mode == 1) {
            _;
        } else if (mode == 2) {
            rl.registrationExt{value: msg.value}(msg.sender, referrerAddress);
        } else {
            rl.registration{value: msg.value}(msg.sender, referrerAddress);
        }
    }

    modifier checkUpgradeMode(
        uint8 mode,
        uint8 matrix,
        uint8 level
    ) {
        if (mode == 1) {
            _;
        } else {
            rl.occupyMatrix{value: msg.value}(msg.sender, matrix, level);
        }
    }

    function registrationExt(address referrerAddress, uint8 mode)
        external
        payable
        checkRegisterMode(mode, referrerAddress)
    {
        address userAddress = msg.sender;
        require(msg.value == 0.04 ether, "registration cost 0.04");
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");

        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");

        users[userAddress].id = lastUserId;
        users[userAddress].referrer = referrerAddress;
        idToAddress[lastUserId] = userAddress;

        users[userAddress].referrer = referrerAddress;

        users[userAddress].activeX3Levels[1] = true;
        users[userAddress].activeX4Levels[1] = true;

        lastUserId++;

        users[referrerAddress].partnersCount++;

        address freeX3Referrer = findFreeMatrixReferrer(1, userAddress, 1);
        users[userAddress].x3Matrix[1].currentReferrer = freeX3Referrer;
        occupyX3(userAddress, freeX3Referrer, 1);

        occupyX4(userAddress, findFreeMatrixReferrer(2, userAddress, 1), 1);

        emit Registration(
            userAddress,
            referrerAddress,
            users[userAddress].id,
            users[referrerAddress].id
        );
    }

    function occupyMatrix(
        uint8 matrix,
        uint8 level,
        uint8 mode
    ) external payable checkUpgradeMode(mode, matrix, level) {
        require(
            isUserExists(msg.sender),
            "user is not exists. Register first."
        );
        require(matrix == 1 || matrix == 2, "invalid matrix");
        require(msg.value == levelPrice[level], "invalid price");
        require(level > 1 && level <= MAX_LEVEL, "invalid level");

        if (matrix == 1) {
            require(
                !users[msg.sender].activeX3Levels[level],
                "level already activated"
            );
            require(users[msg.sender].activeX3Levels[level - 1], "no skipping");

            if (users[msg.sender].x3Matrix[level - 1].blocked) {
                users[msg.sender].x3Matrix[level - 1].blocked = false;
            }

            address freeX3Referrer = findFreeMatrixReferrer(
                1,
                msg.sender,
                level
            );
            users[msg.sender].x3Matrix[level].currentReferrer = freeX3Referrer;
            users[msg.sender].activeX3Levels[level] = true;
            occupyX3(msg.sender, freeX3Referrer, level);

            emit BuyNewLevel(msg.sender, freeX3Referrer, 1, level);
        } else {
            require(
                !users[msg.sender].activeX4Levels[level],
                "level already activated"
            );
            require(users[msg.sender].activeX4Levels[level - 1], "no skipping");

            if (users[msg.sender].x4Matrix[level - 1].blocked) {
                users[msg.sender].x4Matrix[level - 1].blocked = false;
            }

            address freeX4Referrer = findFreeMatrixReferrer(
                2,
                msg.sender,
                level
            );

            users[msg.sender].activeX4Levels[level] = true;
            occupyX4(msg.sender, freeX4Referrer, level);

            emit BuyNewLevel(msg.sender, freeX4Referrer, 2, level);
        }
    }

    function occupyX3(
        address userAddress,
        address referrerAddress,
        uint8 level
    ) private {
        users[referrerAddress].x3Matrix[level].referrals.push(userAddress);

        if (users[referrerAddress].x3Matrix[level].referrals.length < 3) {
            emit NewUserPlace(
                userAddress,
                referrerAddress,
                1,
                level,
                uint8(users[referrerAddress].x3Matrix[level].referrals.length)
            );
            return sendETHDividends(referrerAddress, userAddress, 1, level);
        }

        emit NewUserPlace(userAddress, referrerAddress, 1, level, 3);

        users[referrerAddress].x3Matrix[level].referrals = new address[](0);
        if (
            !users[referrerAddress].activeX3Levels[level + 1] &&
            level != MAX_LEVEL
        ) {
            users[referrerAddress].x3Matrix[level].blocked = true;
        }


        if (referrerAddress != owner) {

            address freeReferrerAddress = findFreeMatrixReferrer(
                1,
                referrerAddress,
                level
            );
            if (
                users[referrerAddress].x3Matrix[level].currentReferrer !=
                freeReferrerAddress
            ) {
                users[referrerAddress].x3Matrix[level]
                    .currentReferrer = freeReferrerAddress;
            }

            users[referrerAddress].x3Matrix[level].reinvestCount++;
            emit Reinvest(
                referrerAddress,
                freeReferrerAddress,
                userAddress,
                1,
                level
            );
            occupyX3(referrerAddress, freeReferrerAddress, level);
        } else {
            sendETHDividends(owner, userAddress, 1, level);
            users[owner].x3Matrix[level].reinvestCount++;
            emit Reinvest(owner, address(0), userAddress, 1, level);
        }
    }

    function occupyX4(
        address userAddress,
        address referrerAddress,
        uint8 level
    ) private {
        require(
            users[referrerAddress].activeX4Levels[level],
            "500. Referrer level is inactive"
        );

        if (
            users[referrerAddress].x4Matrix[level].firstLevelReferrals.length <
            2
        ) {
            users[referrerAddress].x4Matrix[level].firstLevelReferrals.push(
                userAddress
            );
            emit NewUserPlace(
                userAddress,
                referrerAddress,
                2,
                level,
                uint8(
                    users[referrerAddress].x4Matrix[level]
                        .firstLevelReferrals
                        .length
                )
            );


            users[userAddress].x4Matrix[level]
                .currentReferrer = referrerAddress;

            if (referrerAddress == owner) {
                return sendETHDividends(referrerAddress, userAddress, 2, level);
            }

            address ref = users[referrerAddress].x4Matrix[level]
                .currentReferrer;
            users[ref].x4Matrix[level].secondLevelReferrals.push(userAddress);

            uint256 len = users[ref].x4Matrix[level].firstLevelReferrals.length;

            if (
                (len == 2) &&
                (users[ref].x4Matrix[level].firstLevelReferrals[0] ==
                    referrerAddress) &&
                (users[ref].x4Matrix[level].firstLevelReferrals[1] ==
                    referrerAddress)
            ) {
                if (
                    users[referrerAddress].x4Matrix[level]
                        .firstLevelReferrals
                        .length == 1
                ) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6);
                }
            } else if (
                (len == 1 || len == 2) &&
                users[ref].x4Matrix[level].firstLevelReferrals[0] ==
                referrerAddress
            ) {
                if (
                    users[referrerAddress].x4Matrix[level]
                        .firstLevelReferrals
                        .length == 1
                ) {
                    emit NewUserPlace(userAddress, ref, 2, level, 3);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 4);
                }
            } else if (
                len == 2 &&
                users[ref].x4Matrix[level].firstLevelReferrals[1] ==
                referrerAddress
            ) {
                if (
                    users[referrerAddress].x4Matrix[level]
                        .firstLevelReferrals
                        .length == 1
                ) {
                    emit NewUserPlace(userAddress, ref, 2, level, 5);
                } else {
                    emit NewUserPlace(userAddress, ref, 2, level, 6);
                }
            }

            return occupyX4Second(userAddress, ref, level);
        }

        users[referrerAddress].x4Matrix[level].secondLevelReferrals.push(
            userAddress
        );

        if (users[referrerAddress].x4Matrix[level].closedPart != address(0)) {
            if (
                (users[referrerAddress].x4Matrix[level]
                    .firstLevelReferrals[0] ==
                    users[referrerAddress].x4Matrix[level]
                        .firstLevelReferrals[1]) &&
                (users[referrerAddress].x4Matrix[level]
                    .firstLevelReferrals[0] ==
                    users[referrerAddress].x4Matrix[level].closedPart)
            ) {
                updateX4(userAddress, referrerAddress, level, true);
                return occupyX4Second(userAddress, referrerAddress, level);
            } else if (
                users[referrerAddress].x4Matrix[level].firstLevelReferrals[0] ==
                users[referrerAddress].x4Matrix[level].closedPart
            ) {
                updateX4(userAddress, referrerAddress, level, true);
                return occupyX4Second(userAddress, referrerAddress, level);
            } else {
                updateX4(userAddress, referrerAddress, level, false);
                return occupyX4Second(userAddress, referrerAddress, level);
            }
        }

        if (
            users[referrerAddress].x4Matrix[level].firstLevelReferrals[1] ==
            userAddress
        ) {
            updateX4(userAddress, referrerAddress, level, false);
            return occupyX4Second(userAddress, referrerAddress, level);
        } else if (
            users[referrerAddress].x4Matrix[level].firstLevelReferrals[0] ==
            userAddress
        ) {
            updateX4(userAddress, referrerAddress, level, true);
            return occupyX4Second(userAddress, referrerAddress, level);
        }

        if (
            users[users[referrerAddress].x4Matrix[level].firstLevelReferrals[0]]
                .x4Matrix[level]
                .firstLevelReferrals
                .length <=
            users[users[referrerAddress].x4Matrix[level].firstLevelReferrals[1]]
                .x4Matrix[level]
                .firstLevelReferrals
                .length
        ) {
            updateX4(userAddress, referrerAddress, level, false);
        } else {
            updateX4(userAddress, referrerAddress, level, true);
        }

        occupyX4Second(userAddress, referrerAddress, level);
    }

    function updateX4(
        address userAddress,
        address referrerAddress,
        uint8 level,
        bool right
    ) private {
        if (!right) {
            users[users[referrerAddress].x4Matrix[level].firstLevelReferrals[0]]
                .x4Matrix[level]
                .firstLevelReferrals
                .push(userAddress);
            emit NewUserPlace(
                userAddress,
                users[referrerAddress].x4Matrix[level].firstLevelReferrals[0],
                2,
                level,
                uint8(
                    users[users[referrerAddress].x4Matrix[level]
                        .firstLevelReferrals[0]]
                        .x4Matrix[level]
                        .firstLevelReferrals
                        .length
                )
            );
            emit NewUserPlace(
                userAddress,
                referrerAddress,
                2,
                level,
                2 +
                    uint8(
                        users[users[referrerAddress].x4Matrix[level]
                            .firstLevelReferrals[0]]
                            .x4Matrix[level]
                            .firstLevelReferrals
                            .length
                    )
            );

            users[userAddress].x4Matrix[level]
                .currentReferrer = users[referrerAddress].x4Matrix[level]
                .firstLevelReferrals[0];
        } else {
            users[users[referrerAddress].x4Matrix[level].firstLevelReferrals[1]]
                .x4Matrix[level]
                .firstLevelReferrals
                .push(userAddress);
            emit NewUserPlace(
                userAddress,
                users[referrerAddress].x4Matrix[level].firstLevelReferrals[1],
                2,
                level,
                uint8(
                    users[users[referrerAddress].x4Matrix[level]
                        .firstLevelReferrals[1]]
                        .x4Matrix[level]
                        .firstLevelReferrals
                        .length
                )
            );
            emit NewUserPlace(
                userAddress,
                referrerAddress,
                2,
                level,
                4 +
                    uint8(
                        users[users[referrerAddress].x4Matrix[level]
                            .firstLevelReferrals[1]]
                            .x4Matrix[level]
                            .firstLevelReferrals
                            .length
                    )
            );

            users[userAddress].x4Matrix[level]
                .currentReferrer = users[referrerAddress].x4Matrix[level]
                .firstLevelReferrals[1];
        }
    }

    function occupyX4Second(
        address userAddress,
        address referrerAddress,
        uint8 level
    ) private {
        if (
            users[referrerAddress].x4Matrix[level].secondLevelReferrals.length <
            4
        ) {
            return sendETHDividends(referrerAddress, userAddress, 2, level);
        }

        address[] memory _X4Matrix = users[users[referrerAddress]
            .x4Matrix[level]
            .currentReferrer]
            .x4Matrix[level]
            .firstLevelReferrals;

        if (_X4Matrix.length == 2) {
            if (
                _X4Matrix[0] == referrerAddress ||
                _X4Matrix[1] == referrerAddress
            ) {
                users[users[referrerAddress].x4Matrix[level].currentReferrer]
                    .x4Matrix[level]
                    .closedPart = referrerAddress;
            }
        } else if (_X4Matrix.length == 1) {
            if (_X4Matrix[0] == referrerAddress) {
                users[users[referrerAddress].x4Matrix[level].currentReferrer]
                    .x4Matrix[level]
                    .closedPart = referrerAddress;
            }
        }

        users[referrerAddress].x4Matrix[level]
            .firstLevelReferrals = new address[](0);
        users[referrerAddress].x4Matrix[level]
            .secondLevelReferrals = new address[](0);
        users[referrerAddress].x4Matrix[level].closedPart = address(0);

        if (
            !users[referrerAddress].activeX4Levels[level + 1] &&
            level != MAX_LEVEL
        ) {
            users[referrerAddress].x4Matrix[level].blocked = true;
        }

        users[referrerAddress].x4Matrix[level].reinvestCount++;

        if (referrerAddress != owner) {
            address freeReferrerAddress = findFreeMatrixReferrer(
                2,
                referrerAddress,
                level
            );

            emit Reinvest(
                referrerAddress,
                freeReferrerAddress,
                userAddress,
                2,
                level
            );
            occupyX4(referrerAddress, freeReferrerAddress, level);
        } else {
            emit Reinvest(owner, address(0), userAddress, 2, level);
            sendETHDividends(owner, userAddress, 2, level);
        }
    }

    function findFreeMatrixReferrer(
        uint8 matrix,
        address userAddress,
        uint8 level
    ) public view returns (address) {
        if (matrix == 1) {
            while (true) {
                if (users[users[userAddress].referrer].activeX3Levels[level]) {
                    return users[userAddress].referrer;
                }

                userAddress = users[userAddress].referrer;
            }
        } else {
            while (true) {
                if (users[users[userAddress].referrer].activeX4Levels[level]) {
                    return users[userAddress].referrer;
                }

                userAddress = users[userAddress].referrer;
            }
        }
    }

    function findEthReceiver(
        address userAddress,
        address _from,
        uint8 matrix,
        uint8 level
    ) private returns (address, bool) {
        address receiver = userAddress;
        bool isExtraDividends;
        if (matrix == 1) {
            while (true) {
                if (users[receiver].x3Matrix[level].blocked) {
                    emit MissedEthReceive(receiver, _from, 1, level);
                    isExtraDividends = true;
                    receiver = users[receiver].x3Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        } else {
            while (true) {
                if (users[receiver].x4Matrix[level].blocked) {
                    emit MissedEthReceive(receiver, _from, 2, level);
                    isExtraDividends = true;
                    receiver = users[receiver].x4Matrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        }
    }

    function sendETHDividends(
        address userAddress,
        address _from,
        uint8 matrix,
        uint8 level
    ) private {
        (address receiver, bool isExtraDividends) = findEthReceiver(
            userAddress,
            _from,
            matrix,
            level
        );

        if (!address(uint160(receiver)).send(levelPrice[level])) {
            return address(uint160(receiver)).transfer(address(this).balance);
        }

        if (isExtraDividends) {
            emit SentExtraEthDividends(_from, receiver, matrix, level);
        }
    }

    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    function changeDependentContractAddress() public override {
        rl = IRelayer(registry.getLatestAddress("RL"));
    }
}
