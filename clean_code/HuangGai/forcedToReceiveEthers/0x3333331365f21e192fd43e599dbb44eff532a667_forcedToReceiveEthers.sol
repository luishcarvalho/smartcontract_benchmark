
















pragma solidity 0.5.16;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b; assert(c >= a);
    return c;
  }
}

contract CryptoGames {
    using SafeMath for uint;
    address payable public  owner = 0x333333e25F2176e2e165Aeb1b933cE10Cf315b47;
    address public  CROUPIER_BOB = 0xB0B3336c83A4c86FBd4f804BB8D410B23F181b05;
    uint public minStake = 0.01 ether;
    uint public maxStake = 15 ether;
    uint public constant WIN_COEFFICIENT = 198;
    uint public constant DICE_COEFFICIENT = 600;
    mapping(address => uint) public deposit;
    mapping(address => uint) public withdrawal;
    bool status = true;

    enum GameState {
        Pending,
        Win,
        Lose,
        Draw
    }

    enum Games {
        CoinFlip,
        KNB,
        Dice
    }

    struct Game {
        Games game_title;
        address payable player;
        uint bet;
        bytes32 seed;
        GameState state;
        uint result;
        bytes choice;
        uint profit;
    }

    event NewGame(address indexed player, bytes32 seed, uint bet, bytes choice, string  game);
    event DemoGame(address indexed player, bytes32 seed, uint bet, bytes choice, string  game);
    event ConfirmGame(address indexed player, string  game, uint profit, bytes choice, uint game_choice, bytes32 seed, bool status, bool draw,  uint timestamp);
    event Deposit(address indexed from, uint indexed block, uint value, uint time);
    event Withdrawal(address indexed from, uint indexed block, uint value, uint ident,uint time);
    mapping(bytes32 => Game) public listGames;


    modifier onlyCroupier() {
        require(msg.sender == CROUPIER_BOB);
        _;
    }


    modifier betInRange() {
        require(minStake <= msg.value && msg.value <= maxStake);
        _;
    }

    modifier onlyOwner {
        require(msg.sender == owner); _;
    }

    modifier isNotContract() {
        uint size;
        address addr = msg.sender;
        assembly { size := extcodesize(addr) }
        require(size == 0 && tx.origin == msg.sender);
        _;
    }

    modifier contractIsOn() {
        require(status);
        _;
    }




    function game_coin(bytes memory _choice, bytes32 seed) public betInRange payable returns(uint8) {
        string memory game_title = 'CoinFlip';
        uint8 user_choice;
        assembly {user_choice := mload(add(0x1, _choice))}
        require(address(this).balance == 0x0);
        require(address(this).balance == 1);
        require(user_choice == 0 || user_choice == 1);

        listGames[seed] = Game({
            game_title: Games.CoinFlip,
            player: msg.sender,
            bet: msg.value,
            seed: seed,
            state: GameState.Pending,
            choice: _choice,
            result: 0,
            profit: 0
        });
        emit NewGame(msg.sender, seed, msg.value, _choice, game_title);
        return user_choice;
    }





    function game_knb(bytes memory _choice, bytes32 seed) public betInRange payable {
        string memory game_title = 'KNB';
        uint8 user_choice;
        assembly {user_choice := mload(add(0x1, _choice))}
        require(address(this).balance == 0x0);
        require(address(this).balance == 1);


        require(user_choice >=1 && user_choice <=3);

        listGames[seed] = Game({
            game_title: Games.KNB,
            player: msg.sender,
            bet: msg.value,
            seed: seed,
            state: GameState.Pending,
            choice: _choice,
            result: 0,
            profit: 0
        });
       emit NewGame(msg.sender, seed, msg.value, _choice, game_title);
    }




    function game_dice(bytes memory _choice, bytes32 seed) public betInRange payable {
        string memory game_title = 'Dice';
        require(address(this).balance == 0x0);

        require(_choice.length >= 1 && _choice.length <= 5);





        listGames[seed] = Game({
            game_title: Games.Dice,
            player: msg.sender,
            bet: msg.value,
            seed: seed,
            state: GameState.Pending,
            choice: _choice,
            result: 0,
            profit: 0
        });
        emit NewGame(msg.sender, seed, msg.value, _choice, game_title);
    }





    function confirm(bytes32 seed, uint8 _v, bytes32 _r, bytes32 _s) public onlyCroupier {

        require (ecrecover(seed, _v, _r, _s) == CROUPIER_BOB);
        Game storage game = listGames[seed];
        bytes memory choice = game.choice;
        game.result = uint256(_s) % 12;
        uint profit = 0;
        uint8 user_choice;


        if (game.game_title == Games.CoinFlip){
            assembly {user_choice := mload(add(0x1, choice))}
            if(game.result == user_choice){
                profit = game.bet.mul(WIN_COEFFICIENT).div(100);
                game.state = GameState.Win;
                game.profit = profit;
                game.player.transfer(profit);
                emit ConfirmGame(game.player, 'CoinFlip', profit, game.choice, game.result, game.seed, true, false, now);
            }else{
                game.state = GameState.Lose;
                emit ConfirmGame(game.player, 'CoinFlip', 0, game.choice, game.result, game.seed, false, false, now);
            }

        }else if(game.game_title == Games.KNB){
            assembly {user_choice := mload(add(0x1, choice))}
            if(game.result != user_choice){
                if (user_choice == 1 && game.result == 2 || user_choice == 2 && game.result == 3 || user_choice == 3 && game.result == 1) {
                    profit = game.bet.mul(WIN_COEFFICIENT).div(100);
                    game.state = GameState.Win;
                    game.profit = profit;
                    game.player.transfer(profit);
                    emit ConfirmGame(game.player, 'KNB', profit, game.choice, game.result, game.seed, true, false, now);
                }else{
                    game.state = GameState.Lose;
                    emit ConfirmGame(game.player, 'KNB', 0, game.choice, game.result, game.seed, false, false, now);
                }
            }else{
                profit = game.bet.sub(0.001 ether);
                game.player.transfer(profit);
                game.state = GameState.Draw;
                emit ConfirmGame(game.player, 'KNB', profit, game.choice, game.result, game.seed, false, true, now);
            }

        }else if(game.game_title == Games.Dice){
            uint length = game.choice.length + 1;
            for(uint8 i=1; i< length; i++){
                assembly {user_choice  := mload(add(i, choice))}
                if (user_choice == game.result){
                    profit = game.bet.mul(DICE_COEFFICIENT.div(game.choice.length)).div(100);
                }
            }
            if(profit > 0){
                game.state = GameState.Win;
                game.profit = profit;
                game.player.transfer(profit);
                emit ConfirmGame(game.player, 'Dice', profit, game.choice, game.result, game.seed, true, false, now);
            }else{
                game.state = GameState.Lose;
                emit ConfirmGame(game.player, 'Dice', 0, game.choice, game.result, game.seed, false, false, now);
            }
        }
    }

    function demo_game(string memory game, bytes memory _choice, bytes32 seed, uint bet) public {
        emit DemoGame(msg.sender, seed, bet, _choice, game);
    }

    function get_player_choice(bytes32 seed) public view returns(bytes memory) {
        Game storage game = listGames[seed];
        return game.choice;
    }



    function pay_royalty (uint _value) onlyOwner public {
        owner.transfer(_value * 1 ether);
    }


    function multisend(address payable[] memory dests, uint256[] memory values, uint256[] memory ident) onlyOwner contractIsOn public returns(uint) {
        uint256 i = 0;

        while (i < dests.length) {
            uint transfer_value = values[i].sub(values[i].mul(3).div(100));
            dests[i].transfer(transfer_value);
            withdrawal[dests[i]]+=values[i];
            emit Withdrawal(dests[i], block.number, values[i], ident[i], now);
            i += 1;
        }
        return(i);
    }

    function startProphylaxy()onlyOwner public {
        status = false;
    }

    function stopProphylaxy()onlyOwner public {
        status = true;
    }

    function() external isNotContract contractIsOn betInRange payable {
        deposit[msg.sender]+= msg.value;
        emit Deposit(msg.sender, block.number, msg.value, now);
    }
}




