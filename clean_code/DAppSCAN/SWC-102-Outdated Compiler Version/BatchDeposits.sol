

















pragma solidity 0.6.11;

import "../node_modules/@openzeppelin/contracts/utils/Pausable.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/math/SafeMath.sol";


interface IDepositContract {

    event DepositEvent(
        bytes pubkey,
        bytes withdrawal_credentials,
        bytes amount,
        bytes signature,
        bytes index
    );







    function deposit(
        bytes calldata pubkey,
        bytes calldata withdrawal_credentials,
        bytes calldata signature,
        bytes32 deposit_data_root
    ) external payable;



    function get_deposit_root() external view returns (bytes32);



    function get_deposit_count() external view returns (bytes memory);
}


contract BatchDeposit is Pausable, Ownable {
    using SafeMath for uint256;

    address depositContract;
    uint256 private _fee;

    uint256 constant PUBKEY_LENGTH = 48;
    uint256 constant SIGNATURE_LENGTH = 96;
    uint256 constant CREDENTIALS_LENGTH = 32;
    uint256 constant MAX_VALIDATORS = 100;
    uint256 constant DEPOSIT_AMOUNT = 32 ether;

    event FeeChanged(uint256 previousFee, uint256 newFee);
    event Withdrawn(address indexed payee, uint256 weiAmount);
    event FeeCollected(address indexed payee, uint256 weiAmount);

    constructor(address depositContractAddr, uint256 initialFee) public {
        require(initialFee % 1 gwei == 0, "Fee must be a multiple of GWEI");

        depositContract = depositContractAddr;
        _fee = initialFee;
    }





    function batchDeposit(
        bytes calldata pubkeys,
        bytes calldata withdrawal_credentials,
        bytes calldata signatures,
        bytes32[] calldata deposit_data_roots
    )
        external payable whenNotPaused
    {

        require(msg.value % 1 gwei == 0, "BatchDeposit: Deposit value not multiple of GWEI");
        require(msg.value >= DEPOSIT_AMOUNT, "BatchDeposit: Amount is too low");

        uint256 count = deposit_data_roots.length;
        require(count > 0, "BatchDeposit: You should deposit at least one validator");
        require(count <= MAX_VALIDATORS, "BatchDeposit: You can deposit max 100 validators at a time");

        require(pubkeys.length == count * PUBKEY_LENGTH, "BatchDeposit: Pubkey count don't match");
        require(signatures.length == count * SIGNATURE_LENGTH, "BatchDeposit: Signatures count don't match");
        require(withdrawal_credentials.length == 1 * CREDENTIALS_LENGTH, "BatchDeposit: Withdrawal Credentials count don't match");

        uint256 expectedAmount = _fee.add(DEPOSIT_AMOUNT).mul(count);
        require(msg.value == expectedAmount, "BatchDeposit: Amount is not aligned with pubkeys number");

        emit FeeCollected(msg.sender, _fee.mul(count));

        for (uint256 i = 0; i < count; ++i) {
            bytes memory pubkey = bytes(pubkeys[i*PUBKEY_LENGTH:(i+1)*PUBKEY_LENGTH]);
            bytes memory signature = bytes(signatures[i*SIGNATURE_LENGTH:(i+1)*SIGNATURE_LENGTH]);

            IDepositContract(depositContract).deposit{value: DEPOSIT_AMOUNT}(
                pubkey,
                withdrawal_credentials,
                signature,
                deposit_data_roots[i]
            );
        }
    }







    function withdraw(address payable receiver) public onlyOwner {
        require(receiver != address(0), "You can't burn these eth directly");

        uint256 amount = address(this).balance;
        emit Withdrawn(receiver, amount);
        receiver.transfer(amount);
    }





    function changeFee(uint256 newFee) public onlyOwner {
        require(newFee != _fee, "Fee must be different from current one");
        require(newFee % 1 gwei == 0, "Fee must be a multiple of GWEI");

        emit FeeChanged(_fee, newFee);
        _fee = newFee;
    }








    function pause() public onlyOwner {
        _pause();
    }








    function unpause() public onlyOwner {
        _unpause();
    }




    function fee() public view returns (uint256) {
        return _fee;
    }




    function renounceOwnership() public override onlyOwner {
        revert("Ownable: renounceOwnership is disabled");
    }
}
