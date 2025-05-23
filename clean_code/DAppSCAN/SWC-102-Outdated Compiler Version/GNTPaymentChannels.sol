
pragma solidity ^0.4.16;

import "./GolemNetworkTokenBatching.sol";

contract GNTPaymentChannels is ReceivingContract {

    GolemNetworkTokenBatching public token;

    struct PaymentChannel {
        address owner;
        address receiver;
        uint256 deposited;

        uint256 withdrawn;


        uint256 locked_until;
    }

    uint256 id;
    mapping (bytes32 => PaymentChannel) public channels;
    uint256 close_delay;

    event NewChannel(address indexed _owner, address indexed _receiver, bytes32 _channel);
    event Fund(address indexed _receiver, bytes32 indexed _channel, uint256 amount);
    event Withdraw(address indexed _owner, address indexed _receiver);
    event TimeLocked(address indexed _owner, address indexed _receiver, bytes32 _channel);
    event Close(address indexed _owner, address indexed _receiver, bytes32 _channel);
    event ForceClose(address indexed _owner, address indexed _receiver, bytes32 _channel);

    function GNTPaymentChannels(address _token, uint256 _close_delay)
        public {
        token = GolemNetworkTokenBatching(_token);
        id = 0;
        close_delay = _close_delay;
    }

    modifier onlyToken() {
        require(msg.sender == address(token));
        _;
    }

    modifier onlyValidSig(bytes32 _ch, uint _value,
                      uint8 _v, bytes32 _r, bytes32 _s) {
        require(isValidSig(_ch, _value, _v, _r, _s));
        _;
    }

    modifier onlyOwner(bytes32 _channel) {
        require(msg.sender == channels[_channel].owner);
        _;
    }

    modifier unlocked(bytes32 _channel) {
        require(isUnlocked(_channel));
        _;
    }



    function getDeposited(bytes32 _channel)
        external
        view
        returns (uint256) {
        PaymentChannel ch = channels[_channel];
        return ch.deposited;
    }

    function getWithdrawn(bytes32 _channel)
        external
        view
        returns (uint256) {
        return channels[_channel].withdrawn;
    }

    function getOwner(bytes32 _channel)
        external
        view
        returns (address) {
        return channels[_channel].owner;
    }

    function getReceiver(bytes32 _channel)
        external
        view
        returns (address) {
        return channels[_channel].receiver;
    }

    function isLocked(bytes32 _channel) public returns (bool) {
        return channels[_channel].locked_until == 0;
    }

    function isTimeLocked(bytes32 _channel) public view returns (bool) {
        return channels[_channel].locked_until >= block.timestamp;
    }

    function isUnlocked(bytes32 _channel) public view returns (bool) {
        return ((channels[_channel].locked_until != 0) &&
                (channels[_channel].locked_until < block.timestamp));
    }

    function isValidSig(bytes32 _ch, uint _value,
                        uint8 _v, bytes32 _r, bytes32 _s) view returns (bool) {
        return (channels[_ch].owner) == (ecrecover(sha3(_ch, _value), _v, _r, _s));
    }




    function createChannel(address _receiver)
        external {
        bytes32 channel = sha3(id++);
        channels[channel] = PaymentChannel(msg.sender, _receiver, 0, 0, 0);
        NewChannel(msg.sender, _receiver, channel);
    }


    function onTokenReceived(address _from, uint _value, bytes _data) {
        bytes32 channel;
        assembly {
          channel := mload(add(_data, 32))
        }
        PaymentChannel ch = channels[channel];
        require(_from == ch.owner);
        ch.deposited += _value;
        Fund(ch.receiver, channel, _value);
    }



    function fund(bytes32 _channel, uint256 _amount)
        returns (bool) {
        PaymentChannel ch = channels[_channel];


        require(ch.receiver != address(0));
        if (token.transferFrom(msg.sender, address(this), _amount)) {
            ch.deposited += _amount;
            ch.locked_until = 0;
            Fund(ch.receiver, _channel, _amount);
            return true;
        }
        return false;
    }


    function withdraw(bytes32 _channel, uint256 _value,
                      uint8 _v, bytes32 _r, bytes32 _s)
        external
        onlyValidSig(_channel, _value, _v, _r, _s)
        returns (bool) {
        PaymentChannel ch = channels[_channel];
        require(ch.withdrawn < _value);
        var amount = _value - ch.withdrawn;

        if (ch.deposited - ch.withdrawn < amount)
            amount = ch.deposited - ch.withdrawn;
        return _do_withdraw(_channel, amount);
    }



    function unlock(bytes32 _channel)
        external
        onlyOwner(_channel) {
        PaymentChannel ch = channels[_channel];
        ch.locked_until = block.timestamp + close_delay;
        TimeLocked(ch.owner, ch.receiver, _channel);
    }


    function close(bytes32 _channel)
        external
        onlyOwner(_channel)
        unlocked(_channel)
        returns (bool) {
        return _do_close(_channel, false);
    }



    function forceClose(bytes32 _channel)
        external
        returns (bool) {
        require(msg.sender == channels[_channel].receiver);
        return _do_close(_channel, true);
    }



    function _do_withdraw(bytes32 _channel, uint256 _amount)
        private
        returns (bool) {

        PaymentChannel ch = channels[_channel];
        if (token.transfer(ch.receiver, _amount)) {
            ch.withdrawn += _amount;
            Withdraw(ch.owner, ch.receiver);
            return true;
        }
        return false;
    }

    function _do_close(bytes32 _channel, bool force)
        private
        returns (bool) {

        PaymentChannel ch = channels[_channel];
        var amount = ch.deposited - ch.withdrawn;
        if (token.transfer(ch.owner, amount)) {
            if (force)
                { ForceClose(ch.owner, ch.receiver, _channel); }
            else
                { Close(ch.owner, ch.receiver, _channel); }
            delete channels[_channel];
            return true;
        }
        return false;
    }
}
