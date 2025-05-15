pragma solidity ^0.4.24;

import 'openzeppelin-solidity/contracts/token/ERC20/StandardBurnableToken.sol';
import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';



















contract Ambix is Ownable {
    address[][] public A;
    uint256[][] public N;
    address[] public B;
    uint256[] public M;







    function appendSource(
        address[] _a,
        uint256[] _n
    ) public onlyOwner {
        require(_a.length == _n.length);
        A.length++;
        N.length++;

        uint256 ix = A.length - 1;
        for (uint256 i = 0; i < _a.length; ++i) {
            require(_a[i] != 0);

            A[ix].push(_a[i]);
            N[ix].push(_n[i]);
        }
    }





    function removeSource(uint256 _ix) public onlyOwner {
        A[_ix].length = 0;
        N[_ix].length = 0;
    }






    function setSink(
        address[] _b,
        uint256[] _m
    ) public onlyOwner{
        B = _b;
        M = _m;
    }





    function run(uint256 _ix) {
        require(_ix < A.length);
        uint256 i;

        if (N[_ix][0] > 0) {


            StandardBurnableToken token = StandardBurnableToken(A[_ix][0]);

            uint256 mux = token.allowance(msg.sender, this) / N[_ix][0];
            require(mux > 0);


            for (i = 0; i < A[_ix].length; ++i) {
                token = StandardBurnableToken(A[_ix][i]);
                token.burnFrom(msg.sender, mux * N[_ix][i]);
            }


            for (i = 0; i < B.length; ++i) {
                token = StandardBurnableToken(B[i]);
                require(token.transfer(msg.sender, M[i] * mux));
            }

        } else {






            require(A[_ix].length == 1 && B.length == 1);

            StandardBurnableToken source = StandardBurnableToken(A[_ix][0]);
            StandardBurnableToken sink = StandardBurnableToken(B[0]);

            uint256 scale = 10 ** 18 * sink.balanceOf(this) / source.totalSupply();

            uint256 allowance = source.allowance(msg.sender, this);
            require(allowance > 0);
            source.burnFrom(msg.sender, allowance);

            uint256 reward = scale * allowance / 10 ** 18;
            require(reward > 0);
            require(sink.transfer(msg.sender, reward));
        }
    }
}
