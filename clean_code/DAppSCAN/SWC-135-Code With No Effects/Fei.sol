pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./IIncentive.sol";
import "./IFei.sol";
import "../refs/CoreRef.sol";



contract Fei is IFei, ERC20, ERC20Burnable, CoreRef {

    mapping (address => address) public override incentiveContract;

    bytes32 public DOMAIN_SEPARATOR;

    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public nonces;



	constructor(address core) public ERC20("Fei USD", "FEI") CoreRef(core) {
        uint chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name())),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
    }

    function setIncentiveContract(address account, address incentive) external override onlyGovernor {
        incentiveContract[account] = incentive;
        emit IncentiveContractUpdate(account, incentive);
    }

    function mint(address account, uint amount) external override onlyMinter {
        _mint(account, amount);
        emit Minting(account, msg.sender, amount);
    }

    function burn(uint amount) public override(IFei, ERC20Burnable) {
        super.burn(amount);
        emit Burning(msg.sender, msg.sender, amount);
    }

    function burnFrom(address account, uint amount) public override(IFei, ERC20Burnable) onlyBurner {
        _burn(account, amount);
        emit Burning(account, msg.sender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint amount) internal override {

        if (from != address(0) && to != address(0)) {
            _checkAndApplyIncentives(from, to, amount);
        }
    }

    function _checkAndApplyIncentives(address sender, address recipient, uint amount) internal {

        address senderIncentive = incentiveContract[sender];
        if (senderIncentive != address(0)) {
            IIncentive(senderIncentive).incentivize(sender, recipient, msg.sender, amount);
        }


        address recipientIncentive = incentiveContract[recipient];
        if (recipientIncentive != address(0)) {
            IIncentive(recipientIncentive).incentivize(sender, recipient, msg.sender, amount);
        }


        address operatorIncentive = incentiveContract[msg.sender];
        if (msg.sender != sender && msg.sender != recipient && operatorIncentive != address(0)) {
            IIncentive(operatorIncentive).incentivize(sender, recipient, msg.sender, amount);
        }


        address allIncentive = incentiveContract[address(0)];
        if (allIncentive != address(0)) {
            IIncentive(allIncentive).incentivize(sender, recipient, msg.sender, amount);
        }
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, 'Fei: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'Fei: INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }
}
