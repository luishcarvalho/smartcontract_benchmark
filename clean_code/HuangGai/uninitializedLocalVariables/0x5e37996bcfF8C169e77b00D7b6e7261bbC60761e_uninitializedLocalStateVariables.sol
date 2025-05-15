




pragma solidity =0.6.11;




interface IERC20 {



    function totalSupply() external view returns (uint256);




    function balanceOf(address account) external view returns (uint256);








    function transfer(address recipient, uint256 amount) external returns (bool);








    function allowance(address owner, address spender) external view returns (uint256);















    function approve(address spender, uint256 amount) external returns (bool);










    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);







    event Transfer(address indexed from, address indexed to, uint256 value);





    event Approval(address indexed owner, address indexed spender, uint256 value);
}




library MerkleProof {






    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash ;


        for (uint256 i ; i < proof.length; i++) {

            bytes32 proofElement ;


            if (computedHash <= proofElement) {

                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {

                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }


        return computedHash == root;
    }
}


interface IMerkleDistributor {

    function token() external view returns (address);

    function merkleRoot() external view returns (bytes32);

    function isClaimed(uint256 index) external view returns (bool);

    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof, uint256 tipBips) external;


    event Claimed(uint256 index, address account, uint256 amount);
}

contract MerkleDistributor is IMerkleDistributor {
    address public immutable override token;
    bytes32 public immutable override merkleRoot;


    mapping(uint256 => uint256) private claimedBitMap;
    address deployer;

    constructor(address token_, bytes32 merkleRoot_) public {
        token = token_;
        merkleRoot = merkleRoot_;
        deployer = msg.sender;
    }

    function isClaimed(uint256 index) public view override returns (bool) {
        uint256 claimedWordIndex ;

        uint256 claimedBitIndex ;

        uint256 claimedWord ;

        uint256 mask ;

        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex ;

        uint256 claimedBitIndex ;

        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof, uint256 tipBips) external override {
        require(tipBips <= 10000);
        require(!isClaimed(index), 'MerkleDistributor: Drop already claimed.');


        bytes32 node ;

        require(MerkleProof.verify(merkleProof, merkleRoot, node), 'MerkleDistributor: Invalid proof.');


        _setClaimed(index);
        uint256 tip ;

        require(IERC20(token).transfer(account, amount - tip), 'MerkleDistributor: Transfer failed.');
        if (tip > 0) require(IERC20(token).transfer(deployer, tip));

        emit Claimed(index, account, amount);
    }

    function collectDust(address _token, uint256 _amount) external {
      require(msg.sender == deployer, "!deployer");
      require(_token != token, "!token");
      if (_token == address(0)) {
        payable(deployer).transfer(_amount);
      } else {
        IERC20(_token).transfer(deployer, _amount);
      }
    }
}
