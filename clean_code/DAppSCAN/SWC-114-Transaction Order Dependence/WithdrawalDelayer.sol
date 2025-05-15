

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/utils/ReentrancyGuard.sol";

contract WithdrawalDelayer is Initializable, ReentrancyGuardUpgradeSafe {
    struct DepositState {
        uint192 amount;
        uint64 depositTimestamp;
    }
    bytes4 private constant _TRANSFER_SIGNATURE = bytes4(
        keccak256(bytes("transfer(address,uint256)"))
    );
    bytes4 private constant _TRANSFERFROM_SIGNATURE = bytes4(
        keccak256(bytes("transferFrom(address,address,uint256)"))
    );
    bytes4 private constant _DEPOSIT_SIGNATURE = bytes4(
        keccak256(bytes("deposit(address,address,uint192)"))
    );

    uint64 public constant MAX_WITHDRAWAL_DELAY = 2 weeks;
    uint64 public constant MAX_EMERGENCY_MODE_TIME = 26 weeks;

    uint64 private _withdrawalDelay;
    uint64 private _emergencyModeStartingTime;
    address private _hermezGovernanceDAOAddress;
    address payable private _whiteHackGroupAddress;
    address private _hermezKeeperAddress;
    bool private _emergencyMode;
    address public hermezRollupAddress;
    mapping(bytes32 => DepositState) public deposits;

    event Deposit(
        address indexed owner,
        address indexed token,
        uint192 amount,
        uint64 depositTimestamp
    );
    event Withdraw(
        address indexed token,
        address indexed owner,
        uint192 amount
    );
    event EmergencyModeEnabled();
    event NewWithdrawalDelay(uint64 withdrawalDelay);
    event EscapeHatchWithdrawal(
        address indexed who,
        address indexed to,
        address indexed token,
        uint256 amount
    );
    event NewHermezKeeperAddress(address newHermezKeeperAddress);
    event NewWhiteHackGroupAddress(address newWhiteHackGroupAddress);
    event NewHermezGovernanceDAOAddress(address newHermezGovernanceDAOAddress);










    function withdrawalDelayerInitializer(
        uint64 _initialWithdrawalDelay,
        address _initialHermezRollup,
        address _initialHermezKeeperAddress,
        address _initialHermezGovernanceDAOAddress,
        address payable _initialWhiteHackGroupAddress
    ) public initializer {
        __ReentrancyGuard_init_unchained();
        _withdrawalDelay = _initialWithdrawalDelay;
        hermezRollupAddress = _initialHermezRollup;
        _hermezKeeperAddress = _initialHermezKeeperAddress;
        _hermezGovernanceDAOAddress = _initialHermezGovernanceDAOAddress;
        _whiteHackGroupAddress = _initialWhiteHackGroupAddress;
        _emergencyMode = false;
    }





    function getHermezGovernanceDAOAddress() external view returns (address) {
        return _hermezGovernanceDAOAddress;
    }





    function setHermezGovernanceDAOAddress(address newAddress) external {
        require(
            msg.sender == _hermezGovernanceDAOAddress,
            "WithdrawalDelayer::setHermezGovernanceDAOAddress: ONLY_GOVERNANCE"
        );
        _hermezGovernanceDAOAddress = newAddress;
        emit NewHermezGovernanceDAOAddress(_hermezGovernanceDAOAddress);
    }





    function getHermezKeeperAddress() external view returns (address) {
        return _hermezKeeperAddress;
    }





    function setHermezKeeperAddress(address newAddress) external {
        require(
            msg.sender == _hermezKeeperAddress,
            "WithdrawalDelayer::setHermezGovernanceDAOAddress: ONLY_KEEPER"
        );
        _hermezKeeperAddress = newAddress;
        emit NewHermezKeeperAddress(_hermezKeeperAddress);
    }





    function getWhiteHackGroupAddress() external view returns (address) {
        return _whiteHackGroupAddress;
    }





    function setWhiteHackGroupAddress(address payable newAddress) external {
        require(
            msg.sender == _whiteHackGroupAddress,
            "WithdrawalDelayer::setHermezGovernanceDAOAddress: ONLY_WHG"
        );
        _whiteHackGroupAddress = newAddress;
        emit NewWhiteHackGroupAddress(_whiteHackGroupAddress);
    }





    function isEmergencyMode() external view returns (bool) {
        return _emergencyMode;
    }





    function getWithdrawalDelay() external view returns (uint128) {
        return _withdrawalDelay;
    }





    function getEmergencyModeStartingTime() external view returns (uint128) {
        return _emergencyModeStartingTime;
    }








    function enableEmergencyMode() external {
        require(
            msg.sender == _hermezKeeperAddress,
            "WithdrawalDelayer::enableEmergencyMode: ONLY_KEEPER"
        );
        require(
            !_emergencyMode,
            "WithdrawalDelayer::enableEmergencyMode: ALREADY_ENABLED"
        );
        _emergencyMode = true;













    function changeWithdrawalDelay(uint64 _newWithdrawalDelay) external {
        require(
            (msg.sender == _hermezKeeperAddress) ||
                (msg.sender == hermezRollupAddress),
            "Only hermez keeper or rollup"
        );
        require(
            _newWithdrawalDelay <= MAX_WITHDRAWAL_DELAY,
            "Exceeds MAX_WITHDRAWAL_DELAY"
        );
        _withdrawalDelay = _newWithdrawalDelay;
        emit NewWithdrawalDelay(_withdrawalDelay);
    }








    function depositInfo(address payable _owner, address _token)
        external
        view
        returns (uint192, uint64)
    {
        DepositState memory ds = deposits[keccak256(
            abi.encodePacked(_owner, _token)
        )];
        return (ds.amount, ds.depositTimestamp);
    }











    function deposit(
        address _owner,
        address _token,
        uint192 _amount
    ) external payable nonReentrant {
        require(
            msg.sender == hermezRollupAddress,
            "WithdrawalDelayer::deposit: ONLY_ROLLUP"
        );
        if (msg.value != 0) {
            require(
                _token == address(0x0),
                "WithdrawalDelayer::deposit: WRONG_TOKEN_ADDRESS"
            );
            require(
                _amount == msg.value,
                "WithdrawalDelayer::deposit: WRONG_AMOUNT"
            );
        } else {
            require(
                IERC20(_token).allowance(hermezRollupAddress, address(this)) >=
                    _amount,
                "WithdrawalDelayer::deposit: NOT_ENOUGH_ALLOWANCE"
            );

























    function _processDeposit(
        address _owner,
        address _token,
        uint192 _amount
    ) internal {

        bytes32 depositId = keccak256(abi.encodePacked(_owner, _token));
        uint192 newAmount = deposits[depositId].amount + _amount;
        require(
            newAmount >= deposits[depositId].amount,
            "WithdrawalDelayer::_processDeposit: DEPOSIT_OVERFLOW"
        );

        deposits[depositId].amount = newAmount;
        deposits[depositId].depositTimestamp = uint64(now);

        emit Deposit(
            _owner,
            _token,
            _amount,
            deposits[depositId].depositTimestamp
        );
    }









    function withdrawal(address payable _owner, address _token)
        external
        nonReentrant
    {
        require(!_emergencyMode, "WithdrawalDelayer::deposit: EMERGENCY_MODE");

        bytes32 depositId = keccak256(abi.encodePacked(_owner, _token));
        uint192 amount = deposits[depositId].amount;
        require(amount > 0, "WithdrawalDelayer::withdrawal: NO_FUNDS");
        require(
            uint64(now) >=
                deposits[depositId].depositTimestamp + _withdrawalDelay,
            "WithdrawalDelayer::withdrawal: WITHDRAWAL_NOT_ALLOWED"
        );


        deposits[depositId].amount = 0;
        deposits[depositId].depositTimestamp = 0;


        if (_token == address(0x0)) {
            _ethWithdrawal(_owner, uint256(amount));
        } else {
            _tokenWithdrawal(_token, _owner, uint256(amount));
        }

        emit Withdraw(_token, _owner, amount);
    }











    function escapeHatchWithdrawal(
        address _to,
        address _token,
        uint256 _amount
    ) external nonReentrant {
        require(
            _emergencyMode,
            "WithdrawalDelayer::escapeHatchWithdrawal: ONLY_EMODE"
        );
        require(
            msg.sender == _whiteHackGroupAddress ||
                msg.sender == _hermezGovernanceDAOAddress,
            "WithdrawalDelayer::escapeHatchWithdrawal: ONLY_GOVERNANCE_WHG"
        );
        if (msg.sender == _whiteHackGroupAddress) {
            require(
                uint64(now) >=
                    _emergencyModeStartingTime + MAX_EMERGENCY_MODE_TIME,
                "WithdrawalDelayer::escapeHatchWithdrawal: NO_MAX_EMERGENCY_MODE_TIME"
            );
        }
        if (_token == address(0x0)) {
            _ethWithdrawal(_to, _amount);
        } else {
            _tokenWithdrawal(_token, _to, _amount);
        }
        emit EscapeHatchWithdrawal(msg.sender, _to, _token, _amount);
    }






    function _ethWithdrawal(address to, uint256 amount) internal {











    function _tokenWithdrawal(
        address tokenAddress,
        address to,
        uint256 amount
    ) internal {











