pragma solidity 0.4.24;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";








contract Escrow is Ownable {
    using SafeMath for uint256;

    event Deposited(address indexed payee, uint256 weiAmount);
    event Withdrawn(address indexed payee, uint256 weiAmount);

    mapping(address => uint256) private deposits;





    function deposit(address _payee) public onlyOwner payable {
        uint256 amount = msg.value;
        deposits[_payee] = deposits[_payee].add(amount);

        emit Deposited(_payee, amount);
    }






    function withdraw(address _payee) public onlyOwner returns(uint256) {
        uint256 payment = deposits[_payee];

        assert(address(this).balance >= payment);

        deposits[_payee] = 0;

        _payee.transfer(payment);

        emit Withdrawn(_payee, payment);
        return payment;
    }





    function beneficiaryWithdraw(address _wallet) public onlyOwner {
        uint256 _amount = address(this).balance;

        _wallet.transfer(_amount);

        emit Withdrawn(_wallet, _amount);
    }






    function depositsOf(address _payee) public view returns(uint256) {
        return deposits[_payee];
    }
}
