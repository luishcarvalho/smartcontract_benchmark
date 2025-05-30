pragma solidity ^0.4.23;

import "authos-solidity/contracts/core/Contract.sol";
import "authos-solidity/contracts/interfaces/GetterInterface.sol";
import "authos-solidity/contracts/lib/ArrayUtils.sol";

library DutchCrowdsaleIdx {

  using Contract for *;
  using SafeMath for uint;
  using ArrayUtils for bytes32[];

  bytes32 internal constant EXEC_PERMISSIONS = keccak256('script_exec_permissions');


  function execPermissions(address _exec) internal pure returns (bytes32)
    { return keccak256(_exec, EXEC_PERMISSIONS); }




  function admin() internal pure returns (bytes32)
    { return keccak256('sale_admin'); }


  function isConfigured() internal pure returns (bytes32)
    { return keccak256("sale_is_configured"); }


  function isFinished() internal pure returns (bytes32)
    { return keccak256("sale_is_completed"); }


  function burnExcess() internal pure returns (bytes32)
    { return keccak256("burn_excess_unsold"); }


  function startTime() internal pure returns (bytes32)
    { return keccak256("sale_start_time"); }


  function totalDuration() internal pure returns (bytes32)
    { return keccak256("sale_total_duration"); }


  function tokensRemaining() internal pure returns (bytes32)
    { return keccak256("sale_tokens_remaining"); }


  function maxSellCap() internal pure returns (bytes32)
    { return keccak256("token_sell_cap"); }


  function startRate() internal pure returns (bytes32)
    { return keccak256("sale_start_rate"); }


  function endRate() internal pure returns (bytes32)
    { return keccak256("sale_end_rate"); }


  function tokensSold() internal pure returns (bytes32)
    { return keccak256("sale_tokens_sold"); }


  function globalMinPurchaseAmt() internal pure returns (bytes32)
    { return keccak256("sale_min_purchase_amt"); }


  function contributors() internal pure returns (bytes32)
    { return keccak256("sale_contributors"); }


  function hasContributed(address _purchaser) internal pure returns (bytes32)
    { return keccak256(_purchaser, contributors()); }




  function wallet() internal pure returns (bytes32)
    { return keccak256("sale_destination_wallet"); }


  function totalWeiRaised() internal pure returns (bytes32)
    { return keccak256("sale_tot_wei_raised"); }




  function isWhitelisted() internal pure returns (bytes32)
    { return keccak256('sale_is_whitelisted'); }


  function saleWhitelist() internal pure returns (bytes32)
    { return keccak256("sale_whitelist"); }


  function whitelistMaxTok(address _spender) internal pure returns (bytes32)
    { return keccak256(_spender, "max_tok", saleWhitelist()); }


  function whitelistMinTok(address _spender) internal pure returns (bytes32)
    { return keccak256(_spender, "min_tok", saleWhitelist()); }




  function tokenName() internal pure returns (bytes32)
    { return keccak256("token_name"); }


  function tokenSymbol() internal pure returns (bytes32)
    { return keccak256("token_symbol"); }


  function tokenDecimals() internal pure returns (bytes32)
    { return keccak256("token_decimals"); }


  function tokenTotalSupply() internal pure returns (bytes32)
    { return keccak256("token_total_supply"); }


  bytes32 internal constant TOKEN_BALANCES = keccak256("token_balances");

  function balances(address _owner) internal pure returns (bytes32)
    { return keccak256(_owner, TOKEN_BALANCES); }


  bytes32 internal constant TOKEN_ALLOWANCES = keccak256("token_allowances");

  function allowed(address _owner, address _spender) internal pure returns (bytes32)
    { return keccak256(_spender, keccak256(_owner, TOKEN_ALLOWANCES)); }



  bytes32 internal constant TOKEN_TRANSFER_AGENTS = keccak256("token_transfer_agents");

  function transferAgents(address _agent) internal pure returns (bytes32)
    { return keccak256(_agent, TOKEN_TRANSFER_AGENTS); }

















  function init(
    address _wallet, uint _total_supply, uint _max_amount_to_sell, uint _starting_rate,
    uint _ending_rate, uint _duration, uint _start_time, bool _sale_is_whitelisted,
    address _admin, bool _burn_excess
  ) external view {

    if (
      _wallet == 0
      || _max_amount_to_sell == 0
      || _max_amount_to_sell > _total_supply
      || _starting_rate <= _ending_rate
      || _ending_rate == 0
      || _start_time <= now
      || _duration + _start_time <= _start_time
      || _admin == 0
    ) revert("Improper Initialization");


    Contract.initialize();


    Contract.storing();

    Contract.set(execPermissions(msg.sender)).to(true);

    Contract.set(wallet()).to(_wallet);
    Contract.set(admin()).to(_admin);
    Contract.set(totalDuration()).to(_duration);
    Contract.set(startTime()).to(_start_time);

    Contract.set(startRate()).to(_starting_rate);
    Contract.set(endRate()).to(_ending_rate);
    Contract.set(tokenTotalSupply()).to(_total_supply);
    Contract.set(maxSellCap()).to(_max_amount_to_sell);
    Contract.set(tokensRemaining()).to(_max_amount_to_sell);

    Contract.set(isWhitelisted()).to(_sale_is_whitelisted);
    Contract.set(balances(_admin)).to(_total_supply - _max_amount_to_sell);
    Contract.set(burnExcess()).to(_burn_excess);


    Contract.commit();
  }




  function getAdmin(address _storage, bytes32 _exec_id) external view returns (address)
    { return address(GetterInterface(_storage).read(_exec_id, admin())); }












  function getCrowdsaleInfo(address _storage, bytes32 _exec_id) external view
  returns (uint wei_raised, address team_wallet, uint minimum_contribution, bool is_initialized, bool is_finalized, bool burn_excess) {

    bytes32[] memory seed_arr = new bytes32[](6);


    seed_arr[0] = totalWeiRaised();
    seed_arr[1] = wallet();
    seed_arr[2] = globalMinPurchaseAmt();
    seed_arr[3] = isConfigured();
    seed_arr[4] = isFinished();
    seed_arr[5] = burnExcess();


    bytes32[] memory values_arr = GetterInterface(_storage).readMulti(_exec_id, seed_arr);


    wei_raised = uint(values_arr[0]);
    team_wallet = address(values_arr[1]);
    minimum_contribution = uint(values_arr[2]);
    is_initialized = (values_arr[3] != 0 ? true : false);
    is_finalized = (values_arr[4] != 0 ? true : false);
    burn_excess = values_arr[5] != 0 ? true : false;
  }









  function isCrowdsaleFull(address _storage, bytes32 _exec_id) external view returns (bool is_crowdsale_full, uint max_sellable) {

    bytes32[] memory seed_arr = new bytes32[](2);
    seed_arr[0] = tokensRemaining();
    seed_arr[1] = maxSellCap();


    uint[] memory values_arr = GetterInterface(_storage).readMulti(_exec_id, seed_arr).toUintArr();


    is_crowdsale_full = (values_arr[0] == 0 ? true : false);
    max_sellable = values_arr[1];


    seed_arr = new bytes32[](5);
    seed_arr[0] = startTime();
    seed_arr[1] = startRate();
    seed_arr[2] = totalDuration();
    seed_arr[3] = endRate();
    seed_arr[4] = tokenDecimals();

    uint num_remaining = values_arr[0];

    values_arr = GetterInterface(_storage).readMulti(_exec_id, seed_arr).toUintArr();

    uint current_rate;
    (current_rate, ) = getRateAndTimeRemaining(values_arr[0], values_arr[2], values_arr[1], values_arr[3]);


    if (current_rate.mul(num_remaining).div(10 ** values_arr[4]) == 0)
      return (true, max_sellable);
  }


  function getCrowdsaleUniqueBuyers(address _storage, bytes32 _exec_id) external view returns (uint)
    { return uint(GetterInterface(_storage).read(_exec_id, contributors())); }









  function getCrowdsaleStartAndEndTimes(address _storage, bytes32 _exec_id) external view returns (uint start_time, uint end_time) {

    bytes32[] memory seed_arr = new bytes32[](2);
    seed_arr[0] = startTime();
    seed_arr[1] = totalDuration();


    uint[] memory values_arr = GetterInterface(_storage).readMulti(_exec_id, seed_arr).toUintArr();


    start_time = values_arr[0];
    end_time = values_arr[1] + start_time;
  }














  function getCrowdsaleStatus(address _storage, bytes32 _exec_id) external view
  returns (uint start_rate, uint end_rate, uint current_rate, uint sale_duration, uint time_remaining, uint tokens_remaining, bool is_whitelisted) {

    bytes32[] memory seed_arr = new bytes32[](6);


    seed_arr[0] = startRate();
    seed_arr[1] = endRate();
    seed_arr[2] = startTime();
    seed_arr[3] = totalDuration();
    seed_arr[4] = tokensRemaining();
    seed_arr[5] = isWhitelisted();


    uint[] memory values_arr = GetterInterface(_storage).readMulti(_exec_id, seed_arr).toUintArr();


    start_rate = values_arr[0];
    end_rate = values_arr[1];
    uint start_time = values_arr[2];
    sale_duration = values_arr[3];
    tokens_remaining = values_arr[4];
    is_whitelisted = values_arr[5] == 0 ? false : true;

    (current_rate, time_remaining) =
      getRateAndTimeRemaining(start_time, sale_duration, start_rate, end_rate);
  }












  function getRateAndTimeRemaining(uint _start_time, uint _duration, uint _start_rate, uint _end_rate) internal view
  returns (uint current_rate, uint time_remaining)  {

    if (now <= _start_time)
      return (_start_rate, (_duration + _start_time - now));

    uint time_elapsed = now - _start_time;

    if (time_elapsed >= _duration)
      return (0, 0);


    time_remaining = _duration - time_elapsed;

    time_elapsed *= (10 ** 18);
    current_rate = ((_start_rate - _end_rate) * time_elapsed) / _duration;
    current_rate /= (10 ** 18);
    current_rate = _start_rate - current_rate;
  }


  function getTokensSold(address _storage, bytes32 _exec_id) external view returns (uint)
    { return uint(GetterInterface(_storage).read(_exec_id, tokensSold())); }










  function getWhitelistStatus(address _storage, bytes32 _exec_id, address _buyer) external view
  returns (uint minimum_purchase_amt, uint max_tokens_remaining) {
    bytes32[] memory seed_arr = new bytes32[](2);
    seed_arr[0] = whitelistMinTok(_buyer);
    seed_arr[1] = whitelistMaxTok(_buyer);


    uint[] memory values_arr = GetterInterface(_storage).readMulti(_exec_id, seed_arr).toUintArr();


    minimum_purchase_amt = values_arr[0];
    max_tokens_remaining = values_arr[1];
  }









  function getCrowdsaleWhitelist(address _storage, bytes32 _exec_id) external view returns (uint num_whitelisted, address[] whitelist) {

    num_whitelisted = uint(GetterInterface(_storage).read(_exec_id, saleWhitelist()));

    if (num_whitelisted == 0)
      return (num_whitelisted, whitelist);


    bytes32[] memory seed_arr = new bytes32[](num_whitelisted);


    for (uint i = 0; i < num_whitelisted; i++)
    	seed_arr[i] = bytes32(32 * (i + 1) + uint(saleWhitelist()));


    whitelist = GetterInterface(_storage).readMulti(_exec_id, seed_arr).toAddressArr();
  }




  function balanceOf(address _storage, bytes32 _exec_id, address _owner) external view returns (uint)
    { return uint(GetterInterface(_storage).read(_exec_id, balances(_owner))); }


  function allowance(address _storage, bytes32 _exec_id, address _owner, address _spender) external view returns (uint)
    { return uint(GetterInterface(_storage).read(_exec_id, allowed(_owner, _spender))); }


  function decimals(address _storage, bytes32 _exec_id) external view returns (uint)
    { return uint(GetterInterface(_storage).read(_exec_id, tokenDecimals())); }


  function totalSupply(address _storage, bytes32 _exec_id) external view returns (uint)
    { return uint(GetterInterface(_storage).read(_exec_id, tokenTotalSupply())); }


  function name(address _storage, bytes32 _exec_id) external view returns (bytes32)
    { return GetterInterface(_storage).read(_exec_id, tokenName()); }


  function symbol(address _storage, bytes32 _exec_id) external view returns (bytes32)
    { return GetterInterface(_storage).read(_exec_id, tokenSymbol()); }











  function getTokenInfo(address _storage, bytes32 _exec_id) external view
  returns (bytes32 token_name, bytes32 token_symbol, uint token_decimals, uint total_supply) {

    bytes32[] memory seed_arr = new bytes32[](4);


    seed_arr[0] = tokenName();
    seed_arr[1] = tokenSymbol();
    seed_arr[2] = tokenDecimals();
    seed_arr[3] = tokenTotalSupply();


    bytes32[] memory values_arr = GetterInterface(_storage).readMulti(_exec_id, seed_arr);


    token_name = values_arr[0];
    token_symbol = values_arr[1];
    token_decimals = uint(values_arr[2]);
    total_supply = uint(values_arr[3]);
  }


  function getTransferAgentStatus(address _storage, bytes32 _exec_id, address _agent) external view returns (bool)
    { return GetterInterface(_storage).read(_exec_id, transferAgents(_agent)) != 0 ? true : false; }
}
