
pragma solidity 0.8.10;

import "oz-contracts/access/Ownable.sol";


import "oz-contracts/token/ERC20/ERC20.sol";
import "oz-contracts/token/ERC721/ERC721.sol";
import "oz-contracts/token/ERC1155/ERC1155.sol";

import "./MatchMaker.sol";
import "../utils/Errors.sol";
import "../interfaces/IRegistry.sol";

enum Reward { ERC20, ERC721, ERC1155 }

struct TournamentDetails {
  Reward  rewardType;
  uint8   matchCount;
  address rewardAddress;
  uint256 rewardId;
  uint256 rewardAmount;
}

struct Tournament {
  bool   active;
  uint16 j;
  uint16 k;
  uint48 start;
  uint48 interval;
  TournamentDetails details;
}

struct TournamentRegistration {
  bool   active;
  uint8  cost;
  uint16 playerCount;
  uint16 tournamentCount;
  uint16 maxTournamentCount;
  uint48 entryDeadline;
  TournamentDetails details;
}

struct UserRegistration {
  bool registered;
}






contract PaidTournaments is Ownable, MatchMaker {










































































































































































































































































