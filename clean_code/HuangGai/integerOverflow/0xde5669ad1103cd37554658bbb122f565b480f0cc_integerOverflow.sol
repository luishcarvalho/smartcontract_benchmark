



pragma solidity 0.7.0;






























































library SafeMath {









    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;


        return c;
    }










    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }










    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }










    function mul(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }












    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }












    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {

        require(b > 0, errorMessage);
        uint256 c = a / b;


        return c;
    }












    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }












    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}






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



















interface IERC777 {



    function name() external view returns (string memory);





    function symbol() external view returns (string memory);








    function granularity() external view returns (uint256);




    function totalSupply() external view returns (uint256);




    function balanceOf(address owner) external view returns (uint256);

















    function send(address recipient, uint256 amount, bytes calldata data) external;














    function burn(uint256 amount, bytes calldata data) external;








    function isOperatorFor(address operator, address tokenHolder) external view returns (bool);












    function authorizeOperator(address operator) external;












    function revokeOperator(address operator) external;






























    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;
















    function operatorBurn(
        address account,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );

    event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);

    event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);

    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);

    event RevokedOperator(address indexed operator, address indexed tokenHolder);
}






interface ERC1820Registry {
    function setInterfaceImplementer(address _addr, bytes32 _interfaceHash, address _implementer) external;
    function getInterfaceImplementer(address _addr, bytes32 _interfaceHash) external view returns (address);
    function setManager(address _addr, address _newManager) external;
    function getManager(address _addr) external view returns (address);
}



contract ERC1820Client {
    ERC1820Registry constant ERC1820REGISTRY = ERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    function setInterfaceImplementation(string memory _interfaceLabel, address _implementation) internal {
        bytes32 interfaceHash = keccak256(abi.encodePacked(_interfaceLabel));
        ERC1820REGISTRY.setInterfaceImplementer(address(this), interfaceHash, _implementation);
    }

    function interfaceAddr(address addr, string memory _interfaceLabel) internal view returns(address) {
        bytes32 interfaceHash = keccak256(abi.encodePacked(_interfaceLabel));
        return ERC1820REGISTRY.getInterfaceImplementer(addr, interfaceHash);
    }

    function delegateManagement(address _newManager) internal {
        ERC1820REGISTRY.setManager(address(this), _newManager);
    }
}













interface IERC777Sender {










    function tokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}













interface IERC777Recipient {










    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}



interface Staking {

    event Staked(address indexed user, uint256 amount, uint256 total, bytes data);

    event Unstaked(address indexed user, uint256 amount, uint256 total, bytes data);

    function stake(uint256 amount, bytes calldata data) external returns (bool);

    function unstake(uint256 amount, bytes calldata data) external returns (bool);

    function totalStakedFor(address addr) external view returns (uint256);

    function totalStaked() external view returns (uint256);

    function supportsHistory() external pure returns (bool);

}



contract EQUUSGovernanceToken is IERC20, Staking, IERC777, ERC1820Client {



    string public override constant name = "EQUUSGovernanceToken";
    string public override constant symbol = "EQGT";
    uint8 public constant decimals = 18;


    address public constant burnaddress = 0x0000000000000000000000000000000000000000;
    IERC20 public uniaddress;

    mapping(address => uint256) balances;

    mapping(address => uint256) public stakedbalances;

    mapping(address => uint256) public stakeMultipliers;

    mapping(address => uint256) public stakeMultipliersMax;

    mapping(address => uint) public staketimestamps;

    mapping(address => mapping (address => uint256)) allowed;



    uint256 totalSupply_ = 0;
    uint256 totalstaked = 0;
    uint256 granularity_ = 1;



    mapping(address => bool) internal isDefaultOperator_;
    mapping(address => mapping(address => bool)) internal revokedDefaultOperator_;
    mapping(address => mapping(address => bool)) authorizedOperator_;


    address theowner;

    using SafeMath for uint256;

    constructor(IERC20 tokenaddress) public {
        uniaddress = tokenaddress;
        theowner = msg.sender;
        setInterfaceImplementation("ERC777Token", address(this));
   }





   function granularity() public override view returns (uint256) {
       return granularity_;
   }





   function setDefaultOperators(address addr) public returns (bool) {
       require(theowner != addr, "Owner address cannot be handled");
       require(theowner == msg.sender, "Only theowner can set default operators");

        isDefaultOperator_[addr] = true;
        emit AuthorizedOperator(addr, msg.sender);
   }

   function revokeDefaultOperators(address addr) public returns (bool) {
        require(theowner != addr, "Owner address cannot be revoked");

        isDefaultOperator_[addr] = false;
        emit RevokedOperator(addr, msg.sender);
   }

   function isOperatorFor( address operator_, address holder_) public override view returns (bool) {
        return (operator_ == holder_ ||
        authorizedOperator_[operator_][holder_] ||
        (isDefaultOperator_[operator_] &&
        !revokedDefaultOperator_[operator_][holder_]));
    }

    function authorizeOperator(address operator) public override {
        require(operator != msg.sender, "You can't authorize yourself");
        if (isDefaultOperator_[operator]) {
            revokedDefaultOperator_[operator][msg.sender] = false;
        } else {
            authorizedOperator_[operator][msg.sender] = true;
        }
        emit AuthorizedOperator(operator, msg.sender);
    }

    function revokeOperator(address operator) public override {
        require(operator != msg.sender, "You can't revoke yourself");
        if (isDefaultOperator_[operator]) {
            revokedDefaultOperator_[operator][msg.sender] = true;
        } else {
            authorizedOperator_[operator][msg.sender] = false;
        }
        emit RevokedOperator(operator, msg.sender);
    }

    function burn(uint256 amount, bytes memory data) public override {
        burning(msg.sender, msg.sender, amount, data, "");
    }

    function operatorBurn(
        address from,
        uint256 amount,
        bytes memory data,
        bytes memory operatorData
    ) public override {
        require(isOperatorFor(msg.sender, from), "Not an Operator");
        burning(msg.sender, from, amount, data, operatorData);
    }

    function burning(address operator, address from, uint256 amount, bytes memory data, bytes memory operatorData) internal {
        require(balances[from] >= amount, "Not enought funds");
        require(stakedbalances[from] != 0, "Nothing staked to mine for");
        require(stakeMultipliers[from] <= 500, "Max burn multiplier reached");
        require( getPercentageWithFive( stakeMultipliers[from] ) .add( getPercentageFromMax( amount, stakeMultipliersMax[from] ) ) <= 100 , "Too much to burn");

        balances[from] = balances[from].sub(amount);

        totalSupply_ = totalSupply_.sub(amount);


        uint256 multiplier = getPercentageFromMax(amount, stakeMultipliersMax[from]).mul(5);

        stakeMultipliers[from] = stakeMultipliers[from].add(multiplier);

        emit Burned(operator, from, amount, data, operatorData);
        emit Sent(operator, from, burnaddress, amount, data, operatorData);
    }



    function getPercentageFromMax(uint256 amount, uint256 maxForFuntion) public pure returns (uint256) {
        uint256 onePercent = maxForFuntion.div(100);
        return amount.div(onePercent);
    }

    function getPercentageWithFive(uint256 amount) public pure returns (uint256) {
        return amount.div(5);
    }


    function send(address to, uint256 amount, bytes memory data) public override {
        sending(msg.sender, msg.sender, to, amount, data, "", true);
    }

    function operatorSend(
        address from,
        address to,
        uint256 amount,
        bytes memory data,
        bytes memory operatorData
    ) public override {
        require(isOperatorFor(msg.sender, from), "Not an operator.");
        sending(msg.sender, from, to, amount, data, operatorData, true);
    }



    function sending(address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory data,
        bytes memory operatorData,
        bool preventLocking) internal {


        checkSender(operator, from, to, amount, data, operatorData);

        require(to != burnaddress, "Can't send to 0x0");
        require(balances[from] >= amount, "Insufficient funds");

        balances[from] = balances[from].sub(amount);
        balances[to] = balances[to].add(amount);

        checkReceiver(operator, from, to, amount, data, operatorData, preventLocking);

        emit Sent(operator, from, to, amount, data, operatorData);

    }

    function checkSender(address operator, address from, address to, uint256 amount, bytes memory data, bytes memory operatorData) internal {
        address sender = interfaceAddr(from, "ERC777TokensSender");
        require(sender != burnaddress);
        IERC777Sender(sender).tokensToSend(
            operator, from, to, amount, data, operatorData);
    }

    function checkReceiver(address operator, address from, address to, uint256 amount, bytes memory data, bytes memory operatorData, bool preventLocking) internal {
        address recipient = interfaceAddr(to, "ERC777TokensRecipient");
        if (recipient != burnaddress) {
            IERC777Recipient(recipient).tokensReceived(
                operator, from, to, amount, data, operatorData);
        } else if (preventLocking) {
            require(isNormalAddress(to), "Cannot send to contract without ERC777TokensRecipient");
        }
    }

    function isNormalAddress(address addr) internal view returns(bool) {
        if (addr == burnaddress) { return false; }
        uint size;
        assembly { size := extcodesize(addr) }
        return size == 0;
    }




   function totalSupply() public override(IERC20, IERC777) view returns (uint256) {
       return totalSupply_;
   }


   function balanceOf(address tokenOwner) public override(IERC20, IERC777) view returns (uint) {
       return balances[tokenOwner];
   }


   function uniBalance(address tokenOwner) public view returns (uint) {
       return uniaddress.balanceOf(tokenOwner);
   }


   function transfer(address receiver, uint256 numTokens) public override returns (bool) {
       require(numTokens <= balances[msg.sender], 'Amount exceeds balance.');
       balances[msg.sender] = balances[msg.sender].sub(numTokens);

       balances[receiver] = balances[receiver].add(numTokens);

       emit Transfer(msg.sender, receiver, numTokens);
       return true;
   }


   function approve(address delegate, uint256 numTokens) public override returns (bool) {
       require(numTokens <= balances[msg.sender], 'Amount exceeds balance.');
       allowed[msg.sender][delegate] = numTokens;
       emit Approval(msg.sender, delegate, numTokens);
       return true;
   }


   function allowance(address owner, address delegate) public override view returns (uint) {
       return allowed[owner][delegate];
   }


   function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
       require(addedValue <= balances[msg.sender].sub(allowed[msg.sender][spender]), 'Amount exceeds balance.');

       allowed[msg.sender][spender] = allowed[msg.sender][spender].add(addedValue);

       emit Approval(msg.sender, spender, allowed[msg.sender][spender].add(addedValue));
       return true;
   }


   function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
       require(subtractedValue <= allowed[msg.sender][spender], 'Amount exceeds balance.');

       allowed[msg.sender][spender] = allowed[msg.sender][spender].sub(subtractedValue);

       emit Approval(msg.sender, spender, allowed[msg.sender][spender].sub(subtractedValue));
       return true;
   }


   function transferFrom(address owner, address buyer, uint numTokens) public override returns (bool) {
       require(numTokens <= balances[owner], 'Amount exceeds balance.');
       require(numTokens <= allowed[owner][msg.sender], 'Amount exceeds allowance.');

       balances[owner] = balances[owner].sub(numTokens);
       allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
       balances[buyer] = balances[buyer].add(numTokens);

       emit Transfer(msg.sender, buyer, numTokens);
       return true;
   }






   function stake(uint256 amount, bytes memory data) public override returns (bool) {
       require(amount >= 105000);
       require(amount <= uniBalance(msg.sender));
       require(amount <= uniaddress.allowance(msg.sender, address(this)));



       uniaddress.transferFrom(msg.sender, address(this), amount);

       stakedbalances[msg.sender] = stakedbalances[msg.sender].add(amount);

       totalstaked = totalstaked.add(amount);

       staketimestamps[msg.sender] = block.timestamp;
       stakeMultipliers[msg.sender] = 100;


       uint256 max = amount;
       max = max.mul(744);
       max = max.mul(9583).div(1000000);

       max = max.div(1000);
       max = max.mul(5000);

       stakeMultipliersMax[msg.sender] = max;

       uint256 total = stakedbalances[msg.sender];

       emit Staked(msg.sender, amount, total, data);
       return true;
   }


   function unstake(uint256 amount, bytes memory data) public override returns (bool) {
       require(amount <= stakedbalances[msg.sender]);
       require(amount <= totalstaked);

       stakedbalances[msg.sender] = stakedbalances[msg.sender].sub(amount);
       totalstaked = totalstaked.sub(amount);
       staketimestamps[msg.sender] = block.timestamp;
       stakeMultipliers[msg.sender] = 100;
       stakeMultipliersMax[msg.sender] = 0;

       uniaddress.transfer(msg.sender, amount);

       emit Unstaked(msg.sender, amount, stakedbalances[msg.sender], data);
       return true;
   }







    function _mint(bytes memory data) public {
        require(stakedbalances[msg.sender] != 0, "Nothing staked to mine for");


        uint256 amount = operate(stakedbalances[msg.sender]);

        stakeMultipliers[msg.sender] = 100;
        staketimestamps[msg.sender] = block.timestamp;
        balances[msg.sender] = balances[msg.sender].add(amount);
        totalSupply_ = totalSupply_.add(amount);

        emit Minted(burnaddress, msg.sender, amount, data, data);
        emit Sent(burnaddress, burnaddress, msg.sender, amount, data, data);

    }

    function operate(uint256 number) public view returns (uint256) {
        uint256 amount = number;

        amount = amount.mul((stakeTimeFor(msg.sender).div(60)).div(60));

        require(amount > 104400, "Not enough time to mine tokens");



        amount = amount.mul(9583).div(1000000);

        if ((stakeTimeFor(msg.sender).div(60)).div(60) > 744) {
            amount = amount.mul(2);
        }
        uint256 multiplier = stakeMultipliers[msg.sender];
        amount = (amount.mul(multiplier)).div(100);
        return amount;
    }


   function stakeMultiplierFor(address addr) public view returns (uint256) {
       return stakeMultipliers[addr];
   }


   function totalStakedFor(address addr) public override view returns (uint256) {
       return stakedbalances[addr];
   }


   function stakeTimestampFor(address addr) public view returns (uint256) {
       return staketimestamps[addr];
   }


   function stakeTimeFor(address addr) public view returns (uint256) {
       return block.timestamp.sub(staketimestamps[addr]);
   }


   function totalStaked() public override view returns (uint256) {
       return totalstaked;
   }


   function supportsHistory() public override pure returns (bool) {
       return false;
   }

}
