



pragma solidity >=0.6.0 <0.7.0;

contract UnchainedIndex {
  constructor () public {
      owner = msg.sender;
      indexHash = "QmbFMke1KXqnYyBBWxB74N4c5SBnJMVAiMNRcGu6x1AwQH";
  }

  function publishHash(string memory hash) public {
      require(tx.origin == owner, "msg.sender must be owner");

      indexHash = hash;
      emit HashPublished(hash);
  }

  event HashPublished(string hash);

  string indexHash;
  address owner;
}
